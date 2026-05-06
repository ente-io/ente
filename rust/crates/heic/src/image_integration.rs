//! Optional `image` crate integration helpers.
//!
//! Enable the `image-integration` feature to:
//! - register HEIF/HEIC/AVIF decoder hooks for `image::ImageReader`
//! - convert [`DecodedRgbaImage`](crate::DecodedRgbaImage) into `image` buffers
//!   and `DynamicImage` values.
//!
//! See `API.md` in the crate root for end-to-end examples.

use crate::{
    DecodeError, DecodeGuardrails, DecodedRgbaImage, DecodedRgbaPixels, HeifInputFamily,
    decode_bufread_to_rgba_with_guardrails, decode_bytes_to_rgba_with_guardrails,
    decode_path_to_rgba_with_guardrails, decode_read_to_rgba_with_guardrails,
    decode_seekable_to_rgba_with_hint_and_guardrails,
};
use image::error::{
    DecodingError, ImageFormatHint, ParameterError, ParameterErrorKind, UnsupportedError,
    UnsupportedErrorKind,
};
use image::hooks;
use image::{ColorType, DynamicImage, ImageBuffer, ImageDecoder, ImageError, ImageResult, Rgba};
use std::error::Error;
use std::ffi::OsString;
use std::fmt::{Display, Formatter};
use std::io::{BufRead, Read, Seek};
use std::path::Path;
use std::sync::Once;

const HOOK_EXTENSION_HEIC: &str = "heic";
const HOOK_EXTENSION_HEIF: &str = "heif";
const HOOK_EXTENSION_AVIF: &str = "avif";

const FTYP_MASK_12: [u8; 12] = [
    0x00, 0x00, 0x00, 0x00, // size field is ignored
    0xFF, 0xFF, 0xFF, 0xFF, // "ftyp"
    0xFF, 0xFF, 0xFF, 0xFF, // major_brand
];

const FTYP_SIG_AVIF: [u8; 12] = *b"\0\0\0\0ftypavif";
const FTYP_SIG_AVIS: [u8; 12] = *b"\0\0\0\0ftypavis";

const FTYP_SIG_HEIC: [u8; 12] = *b"\0\0\0\0ftypheic";
const FTYP_SIG_HEIX: [u8; 12] = *b"\0\0\0\0ftypheix";
const FTYP_SIG_HEVC: [u8; 12] = *b"\0\0\0\0ftyphevc";
const FTYP_SIG_HEVX: [u8; 12] = *b"\0\0\0\0ftyphevx";
const FTYP_SIG_HEIM: [u8; 12] = *b"\0\0\0\0ftypheim";
const FTYP_SIG_HEIS: [u8; 12] = *b"\0\0\0\0ftypheis";
const FTYP_SIG_MIF1: [u8; 12] = *b"\0\0\0\0ftypmif1";
const FTYP_SIG_MSF1: [u8; 12] = *b"\0\0\0\0ftypmsf1";
const FTYP_SIG_MIAF: [u8; 12] = *b"\0\0\0\0ftypmiaf";

static REGISTER_IMAGE_FORMAT_DETECTION_HOOKS: Once = Once::new();

pub type Rgba8ImageBuffer = ImageBuffer<Rgba<u8>, Vec<u8>>;
pub type Rgba16ImageBuffer = ImageBuffer<Rgba<u16>, Vec<u16>>;

/// Apply EXIF orientation (`1..=8`) to an `image::DynamicImage`.
///
/// This helper is intended for callers that decode with libheif-parity behavior
/// and then apply orientation explicitly at the application layer.
pub fn apply_exif_orientation_dynamic(image: DynamicImage, exif_orientation: u8) -> DynamicImage {
    match exif_orientation {
        2 => image.fliph(),
        3 => image.rotate180(),
        4 => image.flipv(),
        5 => image.fliph().rotate270(),
        6 => image.rotate90(),
        7 => image.fliph().rotate90(),
        8 => image.rotate270(),
        _ => image,
    }
}

/// Dedicated `image::ImageDecoder` adapter backed by decoded RGBA samples.
///
/// This adapter decodes HEIF/HEIC/AVIF inputs directly into in-memory RGBA and
/// exposes the buffer via the `image` crate's decoder trait without any PNG
/// intermediate transcode.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HeifImageDecoder {
    decoded: DecodedRgbaImage,
}

impl HeifImageDecoder {
    /// Build an adapter from an already decoded RGBA image.
    pub fn from_decoded(decoded: DecodedRgbaImage) -> ImageResult<Self> {
        validate_decoded_rgba_image(&decoded)?;
        Ok(Self { decoded })
    }

    /// Decode HEIF/HEIC/AVIF bytes into an `image::ImageDecoder` adapter.
    pub fn from_bytes(input: &[u8]) -> ImageResult<Self> {
        Self::from_bytes_with_guardrails(input, DecodeGuardrails::default())
    }

    /// Decode HEIF/HEIC/AVIF bytes into an `image::ImageDecoder` adapter with configurable guardrails.
    pub fn from_bytes_with_guardrails(
        input: &[u8],
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        let decoded = decode_bytes_to_rgba_with_guardrails(input, guardrails)
            .map_err(decode_error_to_image_error)?;
        Self::from_decoded(decoded)
    }

    /// Decode a `Read` source into an `image::ImageDecoder` adapter.
    pub fn from_read<R: Read>(input_reader: R) -> ImageResult<Self> {
        Self::from_read_with_guardrails(input_reader, DecodeGuardrails::default())
    }

    /// Decode a `Read` source into an `image::ImageDecoder` adapter with configurable guardrails.
    pub fn from_read_with_guardrails<R: Read>(
        input_reader: R,
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        let decoded = decode_read_to_rgba_with_guardrails(input_reader, guardrails)
            .map_err(decode_error_to_image_error)?;
        Self::from_decoded(decoded)
    }

    /// Decode a seekable `Read` source into an `image::ImageDecoder` adapter.
    pub fn from_seekable<R: Read + Seek>(input_reader: R) -> ImageResult<Self> {
        Self::from_seekable_with_guardrails(input_reader, DecodeGuardrails::default())
    }

    /// Decode a seekable `Read` source into an `image::ImageDecoder` adapter with configurable guardrails.
    pub fn from_seekable_with_guardrails<R: Read + Seek>(
        input_reader: R,
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        Self::from_seekable_with_hint_and_guardrails(input_reader, None, guardrails)
    }

    /// Decode a `BufRead` source into an `image::ImageDecoder` adapter.
    pub fn from_bufread<R: BufRead>(input_reader: R) -> ImageResult<Self> {
        Self::from_bufread_with_guardrails(input_reader, DecodeGuardrails::default())
    }

    /// Decode a `BufRead` source into an `image::ImageDecoder` adapter with configurable guardrails.
    pub fn from_bufread_with_guardrails<R: BufRead>(
        input_reader: R,
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        let decoded = decode_bufread_to_rgba_with_guardrails(input_reader, guardrails)
            .map_err(decode_error_to_image_error)?;
        Self::from_decoded(decoded)
    }

    /// Decode a file path into an `image::ImageDecoder` adapter.
    pub fn from_path(input_path: &Path) -> ImageResult<Self> {
        Self::from_path_with_guardrails(input_path, DecodeGuardrails::default())
    }

    /// Decode a file path into an `image::ImageDecoder` adapter with configurable guardrails.
    pub fn from_path_with_guardrails(
        input_path: &Path,
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        let decoded = decode_path_to_rgba_with_guardrails(input_path, guardrails)
            .map_err(decode_error_to_image_error)?;
        Self::from_decoded(decoded)
    }

    /// Consume the adapter and return the owned decoded RGBA buffer.
    pub fn into_decoded_rgba(self) -> DecodedRgbaImage {
        self.decoded
    }

    fn from_seekable_with_hint_and_guardrails<R: Read + Seek>(
        input_reader: R,
        hint: Option<HeifInputFamily>,
        guardrails: DecodeGuardrails,
    ) -> ImageResult<Self> {
        let decoded =
            decode_seekable_to_rgba_with_hint_and_guardrails(input_reader, hint, guardrails)
                .map_err(decode_error_to_image_error)?;
        Self::from_decoded(decoded)
    }

    fn storage_color_type(&self) -> ColorType {
        match self.decoded.storage_bit_depth() {
            8 => ColorType::Rgba8,
            16 => ColorType::Rgba16,
            other => {
                unreachable!("validated storage bit depth must be 8 or 16, got {other}")
            }
        }
    }

    fn expected_total_bytes(&self) -> ImageResult<usize> {
        expected_rgba_byte_count(
            self.decoded.width,
            self.decoded.height,
            self.decoded.storage_bit_depth(),
        )
        .ok_or_else(|| {
            parameter_error(format!(
                "decoded RGBA buffer size overflow for {}x{} image",
                self.decoded.width, self.decoded.height
            ))
        })
    }
}

impl ImageDecoder for HeifImageDecoder {
    fn dimensions(&self) -> (u32, u32) {
        (self.decoded.width, self.decoded.height)
    }

    fn color_type(&self) -> ColorType {
        self.storage_color_type()
    }

    fn icc_profile(&mut self) -> ImageResult<Option<Vec<u8>>> {
        Ok(self.decoded.icc_profile.clone())
    }

    fn read_image(self, buf: &mut [u8]) -> ImageResult<()>
    where
        Self: Sized,
    {
        let expected_total_bytes = self.expected_total_bytes()?;
        if buf.len() != expected_total_bytes {
            return Err(ImageError::Parameter(ParameterError::from_kind(
                ParameterErrorKind::DimensionMismatch,
            )));
        }

        match self.decoded.pixels {
            DecodedRgbaPixels::U8(pixels) => {
                buf.copy_from_slice(&pixels);
            }
            DecodedRgbaPixels::U16(pixels) => {
                write_rgba16_native_endian_bytes(&pixels, buf);
            }
        }

        Ok(())
    }

    fn read_image_boxed(self: Box<Self>, buf: &mut [u8]) -> ImageResult<()> {
        (*self).read_image(buf)
    }
}

/// Result of attempting to install `image` crate decoder hooks for this crate.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ImageHookRegistration {
    pub heic_decoder_hook_registered: bool,
    pub heif_decoder_hook_registered: bool,
    pub avif_decoder_hook_registered: bool,
}

impl ImageHookRegistration {
    pub fn any_decoder_hook_registered(self) -> bool {
        self.heic_decoder_hook_registered
            || self.heif_decoder_hook_registered
            || self.avif_decoder_hook_registered
    }

    pub fn all_decoder_hooks_registered(self) -> bool {
        self.heic_decoder_hook_registered
            && self.heif_decoder_hook_registered
            && self.avif_decoder_hook_registered
    }
}

/// Register HEIF/HEIC/AVIF decoder hooks with `image::hooks`.
///
/// After registration, `image::ImageReader` can decode `.heic`, `.heif`, and
/// `.avif` inputs through this crate's pure-Rust decode path, including direct
/// extension-based dispatch and content-based `ftyp` guesses for common brands.
pub fn register_image_decoder_hooks() -> ImageHookRegistration {
    register_image_decoder_hooks_with_guardrails(DecodeGuardrails::default())
}

/// Register HEIF/HEIC/AVIF decoder hooks with `image::hooks`, applying the provided guardrails to all hook decodes.
pub fn register_image_decoder_hooks_with_guardrails(
    guardrails: DecodeGuardrails,
) -> ImageHookRegistration {
    let heif_guardrails = guardrails.clone();
    let heic_decoder_hook_registered = hooks::register_decoding_hook(
        OsString::from(HOOK_EXTENSION_HEIC),
        Box::new(move |reader| {
            let decoder = HeifImageDecoder::from_seekable_with_hint_and_guardrails(
                reader,
                Some(HeifInputFamily::Heif),
                heif_guardrails.clone(),
            )?;
            Ok(Box::new(decoder))
        }),
    );
    let heif_guardrails = guardrails.clone();
    let heif_decoder_hook_registered = hooks::register_decoding_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        Box::new(move |reader| {
            let decoder = HeifImageDecoder::from_seekable_with_hint_and_guardrails(
                reader,
                Some(HeifInputFamily::Heif),
                heif_guardrails.clone(),
            )?;
            Ok(Box::new(decoder))
        }),
    );
    let avif_decoder_hook_registered = hooks::register_decoding_hook(
        OsString::from(HOOK_EXTENSION_AVIF),
        Box::new(move |reader| {
            let decoder = HeifImageDecoder::from_seekable_with_hint_and_guardrails(
                reader,
                Some(HeifInputFamily::Avif),
                guardrails.clone(),
            )?;
            Ok(Box::new(decoder))
        }),
    );

    REGISTER_IMAGE_FORMAT_DETECTION_HOOKS.call_once(register_image_format_detection_hooks);

    ImageHookRegistration {
        heic_decoder_hook_registered,
        heif_decoder_hook_registered,
        avif_decoder_hook_registered,
    }
}

fn register_image_format_detection_hooks() {
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_AVIF),
        &FTYP_SIG_AVIF,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_AVIF),
        &FTYP_SIG_AVIS,
        Some(&FTYP_MASK_12),
    );

    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEIC,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEIX,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEVC,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEVX,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEIM,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_HEIS,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_MIF1,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_MSF1,
        Some(&FTYP_MASK_12),
    );
    hooks::register_format_detection_hook(
        OsString::from(HOOK_EXTENSION_HEIF),
        &FTYP_SIG_MIAF,
        Some(&FTYP_MASK_12),
    );
}

/// ImageBuffer variants produced by `DecodedRgbaImage` conversion helpers.
#[derive(Debug)]
pub enum ImageBufferKind {
    Rgba8(Rgba8ImageBuffer),
    Rgba16(Rgba16ImageBuffer),
}

/// `image::ImageBuffer` conversion output plus metadata that cannot be stored
/// directly inside `ImageBuffer`.
#[derive(Debug)]
pub struct ImageBufferWithMetadata {
    pub image: ImageBufferKind,
    pub source_bit_depth: u8,
    pub icc_profile: Option<Vec<u8>>,
}

impl ImageBufferWithMetadata {
    pub fn storage_bit_depth(&self) -> u8 {
        match self.image {
            ImageBufferKind::Rgba8(_) => 8,
            ImageBufferKind::Rgba16(_) => 16,
        }
    }

    pub fn into_dynamic_image_with_metadata(self) -> DynamicImageWithMetadata {
        let image = match self.image {
            ImageBufferKind::Rgba8(buffer) => DynamicImage::ImageRgba8(buffer),
            ImageBufferKind::Rgba16(buffer) => DynamicImage::ImageRgba16(buffer),
        };
        DynamicImageWithMetadata {
            image,
            source_bit_depth: self.source_bit_depth,
            icc_profile: self.icc_profile,
        }
    }
}

/// `image::DynamicImage` conversion output plus metadata that cannot be stored
/// directly inside `DynamicImage`.
#[derive(Debug)]
pub struct DynamicImageWithMetadata {
    pub image: DynamicImage,
    pub source_bit_depth: u8,
    pub icc_profile: Option<Vec<u8>>,
}

/// Conversion failures while handing off decoded RGBA buffers to the `image` crate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ImageConversionError {
    SampleCountOverflow {
        width: u32,
        height: u32,
    },
    SampleCountMismatch {
        storage_bit_depth: u8,
        width: u32,
        height: u32,
        expected_samples: usize,
        actual_samples: usize,
    },
}

impl Display for ImageConversionError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ImageConversionError::SampleCountOverflow { width, height } => {
                write!(
                    f,
                    "image sample count overflow for dimensions {width}x{height}"
                )
            }
            ImageConversionError::SampleCountMismatch {
                storage_bit_depth,
                width,
                height,
                expected_samples,
                actual_samples,
            } => write!(
                f,
                "decoded RGBA{storage_bit_depth} sample count mismatch for {width}x{height}: expected {expected_samples}, got {actual_samples}"
            ),
        }
    }
}

impl Error for ImageConversionError {}

impl DecodedRgbaImage {
    /// Convert decoded pixels into `image::ImageBuffer` while carrying metadata.
    pub fn into_image_buffer_with_metadata(
        self,
    ) -> Result<ImageBufferWithMetadata, ImageConversionError> {
        let expected_samples = expected_rgba_sample_count(self.width, self.height).ok_or(
            ImageConversionError::SampleCountOverflow {
                width: self.width,
                height: self.height,
            },
        )?;

        let source_bit_depth = self.source_bit_depth;
        let icc_profile = self.icc_profile;

        let image = match self.pixels {
            DecodedRgbaPixels::U8(pixels) => {
                let actual_samples = pixels.len();
                let buffer =
                    ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(self.width, self.height, pixels)
                        .ok_or(ImageConversionError::SampleCountMismatch {
                            storage_bit_depth: 8,
                            width: self.width,
                            height: self.height,
                            expected_samples,
                            actual_samples,
                        })?;
                ImageBufferKind::Rgba8(buffer)
            }
            DecodedRgbaPixels::U16(pixels) => {
                let actual_samples = pixels.len();
                let buffer =
                    ImageBuffer::<Rgba<u16>, Vec<u16>>::from_raw(self.width, self.height, pixels)
                        .ok_or(ImageConversionError::SampleCountMismatch {
                        storage_bit_depth: 16,
                        width: self.width,
                        height: self.height,
                        expected_samples,
                        actual_samples,
                    })?;
                ImageBufferKind::Rgba16(buffer)
            }
        };

        Ok(ImageBufferWithMetadata {
            image,
            source_bit_depth,
            icc_profile,
        })
    }

    /// Convert decoded pixels into `image::ImageBuffer`.
    pub fn into_image_buffer(self) -> Result<ImageBufferKind, ImageConversionError> {
        Ok(self.into_image_buffer_with_metadata()?.image)
    }

    /// Convert decoded pixels into `image::DynamicImage` while carrying metadata.
    pub fn into_dynamic_image_with_metadata(
        self,
    ) -> Result<DynamicImageWithMetadata, ImageConversionError> {
        Ok(self
            .into_image_buffer_with_metadata()?
            .into_dynamic_image_with_metadata())
    }

    /// Convert decoded pixels into `image::DynamicImage`.
    pub fn into_dynamic_image(self) -> Result<DynamicImage, ImageConversionError> {
        Ok(self.into_dynamic_image_with_metadata()?.image)
    }
}

fn expected_rgba_sample_count(width: u32, height: u32) -> Option<usize> {
    (width as usize)
        .checked_mul(height as usize)?
        .checked_mul(4)
}

fn expected_rgba_byte_count(width: u32, height: u32, storage_bit_depth: u8) -> Option<usize> {
    let bytes_per_sample = match storage_bit_depth {
        8 => 1,
        16 => 2,
        _ => return None,
    };
    expected_rgba_sample_count(width, height)?.checked_mul(bytes_per_sample)
}

fn validate_decoded_rgba_image(decoded: &DecodedRgbaImage) -> ImageResult<()> {
    if decoded.storage_bit_depth() != 8 && decoded.storage_bit_depth() != 16 {
        return Err(ImageError::Unsupported(
            UnsupportedError::from_format_and_kind(
                heif_image_format_hint(),
                UnsupportedErrorKind::GenericFeature(format!(
                    "unsupported decoded RGBA storage bit depth {}",
                    decoded.storage_bit_depth()
                )),
            ),
        ));
    }

    let expected_samples =
        expected_rgba_sample_count(decoded.width, decoded.height).ok_or_else(|| {
            parameter_error(format!(
                "decoded RGBA sample count overflow for {}x{} image",
                decoded.width, decoded.height
            ))
        })?;
    let actual_samples = match &decoded.pixels {
        DecodedRgbaPixels::U8(pixels) => pixels.len(),
        DecodedRgbaPixels::U16(pixels) => pixels.len(),
    };
    if actual_samples != expected_samples {
        return Err(parameter_error(format!(
            "decoded RGBA sample count mismatch for {}x{} image: expected {expected_samples}, got {actual_samples}",
            decoded.width, decoded.height
        )));
    }

    Ok(())
}

fn write_rgba16_native_endian_bytes(samples: &[u16], out: &mut [u8]) {
    for (sample, chunk) in samples.iter().zip(out.chunks_exact_mut(2)) {
        chunk.copy_from_slice(&sample.to_ne_bytes());
    }
}

fn heif_image_format_hint() -> ImageFormatHint {
    ImageFormatHint::Name("heif/heic/avif".to_string())
}

fn parameter_error(message: String) -> ImageError {
    ImageError::Parameter(ParameterError::from_kind(ParameterErrorKind::Generic(
        message,
    )))
}

fn decode_error_to_image_error(err: DecodeError) -> ImageError {
    match err {
        DecodeError::Io(io_err) => ImageError::IoError(io_err),
        DecodeError::Unsupported(message) => {
            ImageError::Unsupported(UnsupportedError::from_format_and_kind(
                heif_image_format_hint(),
                UnsupportedErrorKind::GenericFeature(message),
            ))
        }
        other => ImageError::Decoding(DecodingError::new(heif_image_format_hint(), other)),
    }
}
