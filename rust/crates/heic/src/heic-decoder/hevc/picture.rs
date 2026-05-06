//! Decoded frame representation

use alloc::vec;
use alloc::vec::Vec;

use super::color_convert;

/// Sentinel value for uninitialized pixels.
/// Used during decoding to distinguish decoded samples from uninitialized ones
/// for reference sample availability (H.265 8.4.4.2.2).
pub(crate) const UNINIT_SAMPLE: u16 = u16::MAX;

/// Deblocking edge flags per 4x4 block
pub(crate) const DEBLOCK_FLAG_VERT: u8 = 1;
/// Horizontal edge flag
pub(crate) const DEBLOCK_FLAG_HORIZ: u8 = 2;

/// Decoded video frame with YCbCr plane data.
///
/// Returned by the HEVC decoder for direct YCbCr access before color conversion.
#[derive(Debug)]
#[non_exhaustive]
pub struct DecodedFrame {
    /// Width in pixels (full frame, before cropping)
    pub width: u32,
    /// Height in pixels (full frame, before cropping)
    pub height: u32,
    /// Luma (Y) plane — `u16` samples, `bit_depth` bits significant
    pub y_plane: Vec<u16>,
    /// Cb chroma plane (subsampled per `chroma_format`)
    pub cb_plane: Vec<u16>,
    /// Cr chroma plane (subsampled per `chroma_format`)
    pub cr_plane: Vec<u16>,
    /// Bit depth (8 or 10)
    pub bit_depth: u8,
    /// Chroma format (1=4:2:0, 2=4:2:2, 3=4:4:4)
    pub chroma_format: u8,
    /// Conformance window left offset (in luma samples)
    pub crop_left: u32,
    /// Conformance window right offset (in luma samples)
    pub crop_right: u32,
    /// Conformance window top offset (in luma samples)
    pub crop_top: u32,
    /// Conformance window bottom offset (in luma samples)
    pub crop_bottom: u32,
    /// Alpha plane (optional, from auxiliary alpha image)
    pub alpha_plane: Option<Vec<u16>>,
    /// Video full range flag (from SPS VUI). true = full \[0,255\], false = limited \[16,235\]
    pub full_range: bool,
    /// Matrix coefficients (from SPS VUI). 1=BT.709, 5/6=BT.601, 9=BT.2020, 2=unspecified
    pub matrix_coeffs: u8,
    // -- Internal fields (not part of public API) --
    /// Deblocking edge flags at 4x4 block granularity
    #[doc(hidden)]
    pub deblock_flags: Vec<u8>,
    /// Stride for deblock_flags (width / 4)
    #[doc(hidden)]
    pub deblock_stride: u32,
    /// QP map at 4x4 block granularity (for deblocking)
    #[doc(hidden)]
    pub qp_map: Vec<i8>,
}

impl DecodedFrame {
    /// Create a frame with specific parameters
    ///
    /// # Panics
    /// Panics if width * height overflows u32.
    pub(crate) fn with_params(width: u32, height: u32, bit_depth: u8, chroma_format: u8) -> Self {
        let luma_size = width
            .checked_mul(height)
            .expect("frame dimensions overflow") as usize;

        let (chroma_width, chroma_height) = match chroma_format {
            0 => (0, 0),                                  // Monochrome
            1 => (width.div_ceil(2), height.div_ceil(2)), // 4:2:0
            2 => (width.div_ceil(2), height),             // 4:2:2
            3 => (width, height),                         // 4:4:4
            _ => (width.div_ceil(2), height.div_ceil(2)),
        };

        let chroma_size = (chroma_width * chroma_height) as usize;

        let deblock_stride = width.div_ceil(4);
        let deblock_height = height.div_ceil(4);
        let deblock_size = (deblock_stride * deblock_height) as usize;

        Self {
            width,
            height,
            y_plane: vec![UNINIT_SAMPLE; luma_size],
            cb_plane: vec![UNINIT_SAMPLE; chroma_size],
            cr_plane: vec![UNINIT_SAMPLE; chroma_size],
            bit_depth,
            chroma_format,
            crop_left: 0,
            crop_right: 0,
            crop_top: 0,
            crop_bottom: 0,
            deblock_flags: vec![0; deblock_size],
            deblock_stride,
            qp_map: vec![0; deblock_size],
            alpha_plane: None,
            full_range: false,
            matrix_coeffs: 2,
        }
    }

    /// Mark a vertical TU/CU boundary at luma position (x, y) with given size
    pub(crate) fn mark_tu_boundary(&mut self, x: u32, y: u32, size: u32) {
        let bx = x / 4;
        let by = y / 4;
        let bs = size / 4;

        // Mark vertical edge at x (left edge of TU)
        if x > 0 {
            for j in 0..bs {
                let idx = ((by + j) * self.deblock_stride + bx) as usize;
                if idx < self.deblock_flags.len() {
                    self.deblock_flags[idx] |= DEBLOCK_FLAG_VERT;
                }
            }
        }

        // Mark horizontal edge at y (top edge of TU)
        if y > 0 {
            for i in 0..bs {
                let idx = (by * self.deblock_stride + bx + i) as usize;
                if idx < self.deblock_flags.len() {
                    self.deblock_flags[idx] |= DEBLOCK_FLAG_HORIZ;
                }
            }
        }
    }

    /// Store QP for a block region at 4x4 granularity
    pub(crate) fn store_block_qp(&mut self, x: u32, y: u32, size: u32, qp: i8) {
        let bx = x / 4;
        let by = y / 4;
        let bs = size / 4;
        for j in 0..bs {
            for i in 0..bs {
                let idx = ((by + j) * self.deblock_stride + bx + i) as usize;
                if idx < self.qp_map.len() {
                    self.qp_map[idx] = qp;
                }
            }
        }
    }

    /// Set conformance window cropping
    pub(crate) fn set_crop(&mut self, left: u32, right: u32, top: u32, bottom: u32) {
        self.crop_left = left;
        self.crop_right = right;
        self.crop_top = top;
        self.crop_bottom = bottom;
    }

    /// Width after conformance window cropping. This is the visible image width.
    pub fn cropped_width(&self) -> u32 {
        self.width - self.crop_left - self.crop_right
    }

    /// Height after conformance window cropping. This is the visible image height.
    pub fn cropped_height(&self) -> u32 {
        self.height - self.crop_top - self.crop_bottom
    }

    /// Luma plane stride in pixels (equal to the un-cropped `width`).
    pub fn y_stride(&self) -> usize {
        self.width as usize
    }

    /// Chroma plane stride in pixels. Depends on chroma format:
    /// `width/2` for 4:2:0 and 4:2:2, `width` for 4:4:4, 0 for monochrome.
    pub fn c_stride(&self) -> usize {
        match self.chroma_format {
            0 => 0,
            1 | 2 => self.width.div_ceil(2) as usize,
            3 => self.width as usize,
            _ => self.width.div_ceil(2) as usize,
        }
    }

    /// Convert a single YCbCr pixel to RGB.
    /// y_val, cb_val, cr_val are 8-bit values (0-255).
    /// Selects coefficient matrix based on `matrix_coeffs` field.
    ///
    /// Both full-range and limited-range use integer fixed-point arithmetic.
    /// Full-range: ×256, limited-range: ×2048 with combined Y/C scale factors.
    #[inline(always)]
    fn ycbcr_to_rgb(&self, y_val: i32, cb_val: i32, cr_val: i32) -> (u8, u8, u8) {
        let cb = cb_val - 128;
        let cr = cr_val - 128;

        if self.full_range {
            // Full-range: ×256 fixed-point, matches libheif Op_YCbCr420_to_RGB24.
            let (cr_r, cb_g, cr_g, cb_b) = match self.matrix_coeffs {
                1 => (403, -48, -120, 475), // BT.709
                9 => (377, -42, -146, 482), // BT.2020
                _ => (359, -88, -183, 454), // BT.601 (default/unspecified)
            };
            let r = y_val + ((cr_r * cr + 128) >> 8);
            let g = y_val + ((cb_g * cb + cr_g * cr + 128) >> 8);
            let b = y_val + ((cb_b * cb + 128) >> 8);
            (
                r.clamp(0, 255) as u8,
                g.clamp(0, 255) as u8,
                b.clamp(0, 255) as u8,
            )
        } else {
            // Limited-range: ×8192 fixed-point with pre-combined scale factors.
            // Y_scale = 256/219 ≈ 1.1689, C_scale = 256/224 ≈ 1.1429
            // Combined coefficients = round(matrix_coeff * C_scale * 8192)
            let (cr_r, cb_g, cr_g, cb_b) = match self.matrix_coeffs {
                1 => (14744, -1754, -4383, 17373), // BT.709
                9 => (13806, -1541, -5349, 17615), // BT.2020
                _ => (13126, -3222, -6686, 16591), // BT.601 (default/unspecified)
            };
            // Y_coeff = round(1.1689 * 8192) = 9576
            let yv = (y_val - 16) * 9576;
            let r = (yv + cr_r * cr + 4096) >> 13;
            let g = (yv + cb_g * cb + cr_g * cr + 4096) >> 13;
            let b = (yv + cb_b * cb + 4096) >> 13;
            (
                r.clamp(0, 255) as u8,
                g.clamp(0, 255) as u8,
                b.clamp(0, 255) as u8,
            )
        }
    }

    /// Convert YCbCr to interleaved RGB bytes with conformance window cropping.
    ///
    /// Returns `cropped_width * cropped_height * 3` bytes in R, G, B order.
    /// Selects the color matrix from [`matrix_coeffs`](Self::matrix_coeffs)
    /// (BT.601, BT.709, or BT.2020) and range from [`full_range`](Self::full_range).
    ///
    /// Uses SIMD-accelerated conversion for 4:2:0 chroma (AVX2 on x86-64).
    pub fn to_rgb(&self) -> Vec<u8> {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let total = (out_width * out_height) as usize;
        let mut rgb = vec![0u8; total * 3];
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;
        let w = self.width as usize;

        let mut out_idx = 0;

        if self.chroma_format == 1 {
            // SIMD-accelerated 4:2:0 path (AVX2 when available, scalar fallback)
            let c_stride = self.c_stride();
            color_convert::convert_420_to_rgb(
                &self.y_plane,
                &self.cb_plane,
                &self.cr_plane,
                w,
                c_stride,
                y_start,
                y_end,
                x_start,
                x_end,
                shift as u32,
                self.full_range,
                self.matrix_coeffs,
                &mut rgb,
            );
        } else {
            for y in y_start..y_end {
                for x in x_start..x_end {
                    let y_idx = y as usize * w + x as usize;
                    let y_val = (self.y_plane[y_idx] >> shift) as i32;
                    let (cb_val, cr_val) = self.get_chroma(x, y, shift);
                    let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                    rgb[out_idx] = r;
                    rgb[out_idx + 1] = g;
                    rgb[out_idx + 2] = b;
                    out_idx += 3;
                }
            }
        }

        rgb
    }

    /// Convert YCbCr to interleaved BGRA bytes with conformance window cropping.
    ///
    /// Returns `cropped_width * cropped_height * 4` bytes in B, G, R, A order.
    /// Uses real alpha from [`alpha_plane`](Self::alpha_plane) if present, otherwise 255.
    pub fn to_bgra(&self) -> Vec<u8> {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let mut bgra = Vec::with_capacity((out_width * out_height * 4) as usize);
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        let mut pixel_idx = 0usize;
        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;

                let (cb_val, cr_val) = self.get_chroma(x, y, shift);

                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                bgra.push(b);
                bgra.push(g);
                bgra.push(r);

                let alpha = if let Some(ref alpha) = self.alpha_plane {
                    if pixel_idx < alpha.len() {
                        (alpha[pixel_idx] >> shift).min(255) as u8
                    } else {
                        255
                    }
                } else {
                    255
                };
                bgra.push(alpha);

                pixel_idx += 1;
            }
        }

        bgra
    }

    /// Convert YCbCr to interleaved BGR bytes with conformance window cropping.
    ///
    /// Returns `cropped_width * cropped_height * 3` bytes in B, G, R order.
    pub fn to_bgr(&self) -> Vec<u8> {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let mut bgr = Vec::with_capacity((out_width * out_height * 3) as usize);
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;
                let (cb_val, cr_val) = self.get_chroma(x, y, shift);

                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                bgr.push(b);
                bgr.push(g);
                bgr.push(r);
            }
        }

        bgr
    }

    /// Write cropped pixels into a pre-allocated buffer in RGB format.
    ///
    /// The buffer must be at least `cropped_width * cropped_height * 3` bytes.
    /// Returns the number of bytes written (always `cropped_width * cropped_height * 3`).
    pub fn write_rgb_into(&self, output: &mut [u8]) -> usize {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;
        let w = self.width as usize;

        let mut offset = 0;
        if self.chroma_format == 1 {
            // SIMD-accelerated 4:2:0 path
            let c_stride = self.c_stride();
            let needed = (out_width * out_height * 3) as usize;
            if output.len() >= needed {
                color_convert::convert_420_to_rgb(
                    &self.y_plane,
                    &self.cb_plane,
                    &self.cr_plane,
                    w,
                    c_stride,
                    y_start,
                    y_end,
                    x_start,
                    x_end,
                    shift as u32,
                    self.full_range,
                    self.matrix_coeffs,
                    output,
                );
            }
        } else {
            for y in y_start..y_end {
                for x in x_start..x_end {
                    let y_idx = y as usize * w + x as usize;
                    let y_val = (self.y_plane[y_idx] >> shift) as i32;
                    let (cb_val, cr_val) = self.get_chroma(x, y, shift);
                    let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                    if offset + 3 <= output.len() {
                        output[offset] = r;
                        output[offset + 1] = g;
                        output[offset + 2] = b;
                        offset += 3;
                    }
                }
            }
        }
        (out_width * out_height * 3) as usize
    }

    /// Write cropped pixels into a pre-allocated buffer in RGBA format.
    ///
    /// The buffer must be at least `cropped_width * cropped_height * 4` bytes.
    /// Returns the number of bytes written. Uses real alpha if present, otherwise 255.
    pub fn write_rgba_into(&self, output: &mut [u8]) -> usize {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        let mut offset = 0;
        let mut pixel_idx = 0usize;
        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;
                let (cb_val, cr_val) = self.get_chroma(x, y, shift);
                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                let alpha = if let Some(ref alpha) = self.alpha_plane {
                    if pixel_idx < alpha.len() {
                        (alpha[pixel_idx] >> shift).min(255) as u8
                    } else {
                        255
                    }
                } else {
                    255
                };
                if offset + 4 <= output.len() {
                    output[offset] = r;
                    output[offset + 1] = g;
                    output[offset + 2] = b;
                    output[offset + 3] = alpha;
                    offset += 4;
                }
                pixel_idx += 1;
            }
        }
        (out_width * out_height * 4) as usize
    }

    /// Write cropped pixels into a pre-allocated buffer in BGRA format.
    ///
    /// The buffer must be at least `cropped_width * cropped_height * 4` bytes.
    /// Returns the number of bytes written. Uses real alpha if present, otherwise 255.
    pub fn write_bgra_into(&self, output: &mut [u8]) -> usize {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        let mut offset = 0;
        let mut pixel_idx = 0usize;
        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;
                let (cb_val, cr_val) = self.get_chroma(x, y, shift);
                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                let alpha = if let Some(ref alpha) = self.alpha_plane {
                    if pixel_idx < alpha.len() {
                        (alpha[pixel_idx] >> shift).min(255) as u8
                    } else {
                        255
                    }
                } else {
                    255
                };
                if offset + 4 <= output.len() {
                    output[offset] = b;
                    output[offset + 1] = g;
                    output[offset + 2] = r;
                    output[offset + 3] = alpha;
                    offset += 4;
                }
                pixel_idx += 1;
            }
        }
        (out_width * out_height * 4) as usize
    }

    /// Write cropped pixels into a pre-allocated buffer in BGR format.
    ///
    /// The buffer must be at least `cropped_width * cropped_height * 3` bytes.
    /// Returns the number of bytes written.
    pub fn write_bgr_into(&self, output: &mut [u8]) -> usize {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let shift = self.bit_depth - 8;

        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        let mut offset = 0;
        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;
                let (cb_val, cr_val) = self.get_chroma(x, y, shift);
                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                if offset + 3 <= output.len() {
                    output[offset] = b;
                    output[offset + 1] = g;
                    output[offset + 2] = r;
                    offset += 3;
                }
            }
        }
        (out_width * out_height * 3) as usize
    }

    /// Convert YCbCr to interleaved RGBA bytes with conformance window cropping.
    ///
    /// Returns `cropped_width * cropped_height * 4` bytes in R, G, B, A order.
    /// Uses real alpha from [`alpha_plane`](Self::alpha_plane) if present, otherwise 255.
    pub fn to_rgba(&self) -> Vec<u8> {
        let out_width = self.cropped_width();
        let out_height = self.cropped_height();
        let mut rgba = Vec::with_capacity((out_width * out_height * 4) as usize);
        let shift = self.bit_depth - 8;

        // Iterate over cropped region
        let y_start = self.crop_top;
        let y_end = self.height - self.crop_bottom;
        let x_start = self.crop_left;
        let x_end = self.width - self.crop_right;

        let mut pixel_idx = 0usize;
        for y in y_start..y_end {
            for x in x_start..x_end {
                let y_idx = (y * self.width + x) as usize;
                let y_val = (self.y_plane[y_idx] >> shift) as i32;

                let (cb_val, cr_val) = self.get_chroma(x, y, shift);

                let (r, g, b) = self.ycbcr_to_rgb(y_val, cb_val, cr_val);
                rgba.push(r);
                rgba.push(g);
                rgba.push(b);

                let alpha = if let Some(ref alpha) = self.alpha_plane {
                    if pixel_idx < alpha.len() {
                        (alpha[pixel_idx] >> shift).min(255) as u8
                    } else {
                        255
                    }
                } else {
                    255
                };
                rgba.push(alpha);

                pixel_idx += 1;
            }
        }

        rgba
    }

    /// Get chroma values for a pixel position
    fn get_chroma(&self, x: u32, y: u32, shift: u8) -> (i32, i32) {
        match self.chroma_format {
            0 => (128, 128), // Monochrome - neutral chroma
            1 => {
                // 4:2:0 - both dimensions halved
                let cx = x / 2;
                let cy = y / 2;
                let c_stride = self.c_stride();
                let c_idx = (cy as usize) * c_stride + (cx as usize);
                let cb = if c_idx < self.cb_plane.len() {
                    (self.cb_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                let cr = if c_idx < self.cr_plane.len() {
                    (self.cr_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                (cb, cr)
            }
            2 => {
                // 4:2:2 - horizontal halved
                let cx = x / 2;
                let c_stride = self.c_stride();
                let c_idx = (y as usize) * c_stride + (cx as usize);
                let cb = if c_idx < self.cb_plane.len() {
                    (self.cb_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                let cr = if c_idx < self.cr_plane.len() {
                    (self.cr_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                (cb, cr)
            }
            3 => {
                // 4:4:4 - full resolution
                let c_idx = (y * self.width + x) as usize;
                let cb = if c_idx < self.cb_plane.len() {
                    (self.cb_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                let cr = if c_idx < self.cr_plane.len() {
                    (self.cr_plane[c_idx] >> shift) as i32
                } else {
                    128
                };
                (cb, cr)
            }
            _ => (128, 128),
        }
    }

    /// Get a luma (Y) sample at full-frame coordinates `(x, y)`.
    ///
    /// Coordinates are in the un-cropped frame. Returns 0 if out of bounds.
    /// The returned value has `bit_depth` significant bits.
    #[inline]
    pub fn get_y(&self, x: u32, y: u32) -> u16 {
        let idx = (y * self.width + x) as usize;
        if idx < self.y_plane.len() {
            self.y_plane[idx]
        } else {
            0
        }
    }

    /// Get a Cb chroma sample at chroma-plane coordinates `(x, y)`.
    ///
    /// Coordinates are in the chroma plane's resolution (see [`c_stride`](Self::c_stride)).
    /// Returns neutral chroma (128 << (bit_depth - 8)) if out of bounds.
    #[inline]
    pub fn get_cb(&self, x: u32, y: u32) -> u16 {
        let stride = self.c_stride();
        let idx = (y as usize) * stride + (x as usize);
        if idx < self.cb_plane.len() {
            self.cb_plane[idx]
        } else {
            128 << (self.bit_depth - 8)
        }
    }

    /// Get a Cr chroma sample at chroma-plane coordinates `(x, y)`.
    ///
    /// Coordinates are in the chroma plane's resolution (see [`c_stride`](Self::c_stride)).
    /// Returns neutral chroma (128 << (bit_depth - 8)) if out of bounds.
    #[inline]
    pub fn get_cr(&self, x: u32, y: u32) -> u16 {
        let stride = self.c_stride();
        let idx = (y as usize) * stride + (x as usize);
        if idx < self.cr_plane.len() {
            self.cr_plane[idx]
        } else {
            128 << (self.bit_depth - 8)
        }
    }

    /// Get a mutable plane slice and stride for a given component.
    ///
    /// Returns `(plane, stride)` where `plane` is the raw pixel data
    /// and `stride` is the number of pixels per row.
    #[inline]
    pub(crate) fn plane_mut(&mut self, c_idx: u8) -> (&mut [u16], usize) {
        match c_idx {
            0 => (&mut self.y_plane, self.width as usize),
            1 => {
                let stride = self.c_stride();
                (&mut self.cb_plane, stride)
            }
            2 => {
                let stride = self.c_stride();
                (&mut self.cr_plane, stride)
            }
            _ => (&mut self.y_plane, self.width as usize),
        }
    }

    /// Get an immutable plane slice and stride for a given component index.
    ///
    /// - `c_idx = 0`: luma (Y), stride = `width`
    /// - `c_idx = 1`: Cb chroma, stride = `c_stride()`
    /// - `c_idx = 2`: Cr chroma, stride = `c_stride()`
    ///
    /// Returns `(plane_data, stride_in_pixels)`.
    #[inline]
    pub fn plane(&self, c_idx: u8) -> (&[u16], usize) {
        match c_idx {
            0 => (&self.y_plane, self.width as usize),
            1 => {
                let stride = self.c_stride();
                (&self.cb_plane, stride)
            }
            2 => {
                let stride = self.c_stride();
                (&self.cr_plane, stride)
            }
            _ => (&self.y_plane, self.width as usize),
        }
    }

    /// Get chroma plane dimensions (width, height)
    pub(crate) fn chroma_dims(&self) -> (u32, u32) {
        match self.chroma_format {
            0 => (0, 0),
            1 => (self.width.div_ceil(2), self.height.div_ceil(2)),
            2 => (self.width.div_ceil(2), self.height),
            3 => (self.width, self.height),
            _ => (self.width.div_ceil(2), self.height.div_ceil(2)),
        }
    }
}
