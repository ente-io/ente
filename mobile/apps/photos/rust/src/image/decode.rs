use std::{ffi::OsStr, fs::File, io::BufReader, path::Path, sync::Once};

use exif::{In, Reader as ExifReader, Tag};
use image::{DynamicImage, ImageReader, hooks::decoding_hook_registered};
use libheic_rs::{
    DecodeGuardrails, exif_orientation_hint_from_path,
    image_integration::{
        apply_exif_orientation_dynamic, register_image_decoder_hooks_with_guardrails,
    },
    path_extension_is_heif,
};

use crate::ml::{
    error::{MlError, MlResult},
    types::{DecodedImage, Dimensions},
};

static IMAGE_DECODER_HOOKS_INIT: Once = Once::new();

pub fn decode_image_from_path(image_path: &str) -> MlResult<DecodedImage> {
    let decoded_dynamic = decode_with_image_crate(image_path)?;
    let oriented = orient_decoded_image(decoded_dynamic, image_path).to_rgb8();

    Ok(DecodedImage {
        dimensions: Dimensions {
            width: oriented.width(),
            height: oriented.height(),
        },
        rgb: oriented.into_raw(),
    })
}

fn decode_with_image_crate(image_path: &str) -> MlResult<DynamicImage> {
    init_image_decoders();

    let reader = ImageReader::open(image_path)
        .map_err(|e| MlError::Decode(format!("failed to open image file '{image_path}': {e}")))?
        .with_guessed_format()
        .map_err(|e| MlError::Decode(format!("failed to guess image format: {e}")))?;
    Ok(reader.decode()?)
}

fn init_image_decoders() {
    IMAGE_DECODER_HOOKS_INIT.call_once(|| {
        let registration = register_image_decoder_hooks_with_guardrails(DecodeGuardrails {
            max_input_bytes: Some(128 * 1024 * 1024),
            max_pixels: Some(256_000_000),
            max_temp_spool_bytes: Some(256 * 1024 * 1024),
            temp_spool_directory: None,
        });

        let heic_hook_active = decoding_hook_registered(OsStr::new("heic"));
        let heif_hook_active = decoding_hook_registered(OsStr::new("heif"));
        let avif_hook_active = decoding_hook_registered(OsStr::new("avif"));
        let has_heif_family_support = heic_hook_active || heif_hook_active;

        if !has_heif_family_support {
            eprintln!(
                "[ml][decode] failed to activate HEIF/HEIC decoder hooks; registration_result=(heic:{}, heif:{}, avif:{}), active_hooks=(heic:{}, heif:{}, avif:{})",
                registration.heic_decoder_hook_registered,
                registration.heif_decoder_hook_registered,
                registration.avif_decoder_hook_registered,
                heic_hook_active,
                heif_hook_active,
                avif_hook_active,
            );
        } else if !registration.all_decoder_hooks_registered() {
            eprintln!(
                "[ml][decode] libheic-rs decoder hooks only partially registered (usually because another initializer registered first); registration_result=(heic:{}, heif:{}, avif:{}), active_hooks=(heic:{}, heif:{}, avif:{})",
                registration.heic_decoder_hook_registered,
                registration.heif_decoder_hook_registered,
                registration.avif_decoder_hook_registered,
                heic_hook_active,
                heif_hook_active,
                avif_hook_active,
            );
        }

        debug_assert!(
            heic_hook_active || heif_hook_active || avif_hook_active,
            "no libheic-rs image decoder hooks are active"
        );
    });
}

fn orient_decoded_image(image: DynamicImage, image_path: &str) -> DynamicImage {
    let path = Path::new(image_path);
    if path_extension_is_heif(path) {
        return apply_heif_exif_orientation_hint(image, path);
    }

    apply_standard_exif_orientation(image, image_path)
}

fn apply_heif_exif_orientation_hint(image: DynamicImage, image_path: &Path) -> DynamicImage {
    let hint = match exif_orientation_hint_from_path(image_path) {
        Ok(hint) => hint,
        Err(err) => {
            eprintln!(
                "[ml][decode] failed to inspect HEIF EXIF orientation for '{}': {}",
                image_path.display(),
                err
            );
            return image;
        }
    };

    if let Some(orientation) = hint.orientation_to_apply() {
        return apply_exif_orientation_dynamic(image, orientation);
    }

    image
}

fn apply_standard_exif_orientation(image: DynamicImage, image_path: &str) -> DynamicImage {
    match read_exif_orientation_from_path(image_path) {
        Some(orientation) => apply_exif_orientation_dynamic(image, orientation),
        None => image,
    }
}

fn read_exif_orientation_from_path(image_path: &str) -> Option<u8> {
    let file = File::open(image_path).ok()?;
    let mut reader = BufReader::new(file);
    let exif = ExifReader::new().read_from_container(&mut reader).ok()?;

    exif.get_field(Tag::Orientation, In::PRIMARY)
        .and_then(|field| field.value.get_uint(0))
        .and_then(|value| u8::try_from(value).ok())
        .filter(|value| (1..=8).contains(value))
}
