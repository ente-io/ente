//! SIMD-accelerated YCbCr→RGB color conversion
//!
//! Uses archmage for safe runtime dispatch across x86 (AVX2) with
//! scalar fallback on other platforms.

use archmage::incant;
use archmage::prelude::*;

// Explicit imports for safe SIMD load/store (can't glob-import alongside core::arch)
#[cfg(target_arch = "x86_64")]
use safe_unaligned_simd::x86_64::{_mm_loadu_si64, _mm_loadu_si128, _mm256_storeu_si256};

/// Get color matrix coefficients for YCbCr→RGB conversion.
///
/// Returns (cr_r, cb_g, cr_g, cb_b, y_bias, y_scale, rounding, shift_bits).
/// Full-range uses ×256 fixed-point, limited-range uses ×8192.
#[inline]
fn get_coefficients(
    full_range: bool,
    matrix_coeffs: u8,
) -> (i32, i32, i32, i32, i32, i32, i32, i32) {
    if full_range {
        let (cr_r, cb_g, cr_g, cb_b) = match matrix_coeffs {
            1 => (403, -48, -120, 475), // BT.709
            9 => (377, -42, -146, 482), // BT.2020
            _ => (359, -88, -183, 454), // BT.601
        };
        (cr_r, cb_g, cr_g, cb_b, 0, 256, 128, 8)
    } else {
        let (cr_r, cb_g, cr_g, cb_b) = match matrix_coeffs {
            1 => (14744, -1754, -4383, 17373), // BT.709
            9 => (13806, -1541, -5349, 17615), // BT.2020
            _ => (13126, -3222, -6686, 16591), // BT.601
        };
        (cr_r, cb_g, cr_g, cb_b, 16, 9576, 4096, 13)
    }
}

/// Convert 4:2:0 YCbCr planes to interleaved RGB bytes.
///
/// Dispatches to AVX2 when available, scalar fallback otherwise.
/// Writes exactly `(y_end - y_start) * (x_end - x_start) * 3` bytes to `rgb`.
#[allow(clippy::too_many_arguments)]
pub fn convert_420_to_rgb(
    y_plane: &[u16],
    cb_plane: &[u16],
    cr_plane: &[u16],
    y_stride: usize,
    c_stride: usize,
    y_start: u32,
    y_end: u32,
    x_start: u32,
    x_end: u32,
    shift: u32,
    full_range: bool,
    matrix_coeffs: u8,
    rgb: &mut [u8],
) {
    incant!(
        convert_420_to_rgb(
            y_plane,
            cb_plane,
            cr_plane,
            y_stride,
            c_stride,
            y_start,
            y_end,
            x_start,
            x_end,
            shift,
            full_range,
            matrix_coeffs,
            rgb
        ),
        [v3]
    )
}

/// Scalar YCbCr→RGB conversion (fallback for all platforms)
#[allow(clippy::too_many_arguments)]
fn convert_420_to_rgb_scalar(
    _token: ScalarToken,
    y_plane: &[u16],
    cb_plane: &[u16],
    cr_plane: &[u16],
    y_stride: usize,
    c_stride: usize,
    y_start: u32,
    y_end: u32,
    x_start: u32,
    x_end: u32,
    shift: u32,
    full_range: bool,
    matrix_coeffs: u8,
    rgb: &mut [u8],
) {
    let (cr_r, cb_g, cr_g, cb_b, y_bias, y_scale, rnd, shr) =
        get_coefficients(full_range, matrix_coeffs);

    let mut out_idx = 0;
    for y in y_start..y_end {
        let y_row = y as usize * y_stride;
        let c_row = (y as usize / 2) * c_stride;
        for x in x_start..x_end {
            let y_val = (y_plane[y_row + x as usize] >> shift) as i32;
            let cx = x as usize / 2;
            let c_idx = c_row + cx;
            let cb_val = (cb_plane[c_idx] >> shift) as i32;
            let cr_val = (cr_plane[c_idx] >> shift) as i32;

            let cb = cb_val - 128;
            let cr = cr_val - 128;
            let yv = (y_val - y_bias) * y_scale;
            let r = (yv + cr_r * cr + rnd) >> shr;
            let g = (yv + cb_g * cb + cr_g * cr + rnd) >> shr;
            let b = (yv + cb_b * cb + rnd) >> shr;

            rgb[out_idx] = r.clamp(0, 255) as u8;
            rgb[out_idx + 1] = g.clamp(0, 255) as u8;
            rgb[out_idx + 2] = b.clamp(0, 255) as u8;
            out_idx += 3;
        }
    }
}

/// AVX2 YCbCr→RGB conversion — processes 8 pixels per iteration
#[arcane]
#[allow(clippy::too_many_arguments)]
fn convert_420_to_rgb_v3(
    _token: X64V3Token,
    y_plane: &[u16],
    cb_plane: &[u16],
    cr_plane: &[u16],
    y_stride: usize,
    c_stride: usize,
    y_start: u32,
    y_end: u32,
    x_start: u32,
    x_end: u32,
    shift: u32,
    full_range: bool,
    matrix_coeffs: u8,
    rgb: &mut [u8],
) {
    let (cr_r, cb_g, cr_g, cb_b, y_bias, y_scale, rnd, shr) =
        get_coefficients(full_range, matrix_coeffs);

    // Coefficient vectors (hoisted out of loop)
    let cr_r_v = _mm256_set1_epi32(cr_r);
    let cb_g_v = _mm256_set1_epi32(cb_g);
    let cr_g_v = _mm256_set1_epi32(cr_g);
    let cb_b_v = _mm256_set1_epi32(cb_b);
    let y_bias_v = _mm256_set1_epi32(y_bias);
    let y_scale_v = _mm256_set1_epi32(y_scale);
    let rnd_v = _mm256_set1_epi32(rnd);
    let bias128_v = _mm256_set1_epi32(128);
    let zero = _mm256_setzero_si256();
    let max255 = _mm256_set1_epi32(255);
    let shr_v = _mm_cvtsi32_si128(shr);
    let shift_v = _mm_cvtsi32_si128(shift as i32);
    let needs_shift = shift > 0;

    // Shuffle mask: interleave packed [R0..R3, G0..G3, B0..B3, 0000] per lane
    // into [R0,G0,B0, R1,G1,B1, R2,G2,B2, R3,G3,B3, 0000]
    let shuffle = _mm256_setr_epi8(
        0, 4, 8, 1, 5, 9, 2, 6, 10, 3, 7, 11, -1, -1, -1, -1, 0, 4, 8, 1, 5, 9, 2, 6, 10, 3, 7, 11,
        -1, -1, -1, -1,
    );

    // Align SIMD start to even x for 4:2:0 chroma alignment
    let x_simd_start = x_start.next_multiple_of(2);
    let row_pixels = x_end.saturating_sub(x_simd_start) as usize;
    let simd_count = (row_pixels / 8) * 8;
    let x_simd_end = x_simd_start + simd_count as u32;

    let mut out_idx = 0;

    for y in y_start..y_end {
        let y_row = y as usize * y_stride;
        let c_row = (y as usize / 2) * c_stride;

        // Scalar prefix: handle odd x_start (0 or 1 pixel)
        for x in x_start..x_simd_start.min(x_end) {
            scalar_pixel(
                y_plane,
                cb_plane,
                cr_plane,
                y_row,
                c_row,
                x as usize,
                shift,
                y_bias,
                y_scale,
                cr_r,
                cb_g,
                cr_g,
                cb_b,
                rnd,
                shr,
                rgb,
                &mut out_idx,
            );
        }

        // SIMD: 8 pixels per iteration
        let mut x = x_simd_start as usize;
        let x_end_simd = x_simd_end as usize;
        while x < x_end_simd {
            let cx = x / 2;

            // Load 8 Y values (u16) → zero-extend to 8×i32
            let y_arr: &[u16; 8] = (&y_plane[y_row + x..y_row + x + 8]).try_into().unwrap();
            let y_raw = _mm_loadu_si128(y_arr);
            let mut y_i32 = _mm256_cvtepu16_epi32(y_raw);

            // Load 4 Cb/Cr values, duplicate each for 4:2:0 → 8×i32
            let cb_arr: &[u16; 4] = (&cb_plane[c_row + cx..c_row + cx + 4]).try_into().unwrap();
            let cr_arr: &[u16; 4] = (&cr_plane[c_row + cx..c_row + cx + 4]).try_into().unwrap();
            let cb_raw = _mm_loadu_si64(cb_arr);
            let cr_raw = _mm_loadu_si64(cr_arr);
            let cb_dup = _mm_unpacklo_epi16(cb_raw, cb_raw);
            let cr_dup = _mm_unpacklo_epi16(cr_raw, cr_raw);
            let mut cb_i32 = _mm256_cvtepu16_epi32(cb_dup);
            let mut cr_i32 = _mm256_cvtepu16_epi32(cr_dup);

            // 10-bit → 8-bit shift
            if needs_shift {
                y_i32 = _mm256_srl_epi32(y_i32, shift_v);
                cb_i32 = _mm256_srl_epi32(cb_i32, shift_v);
                cr_i32 = _mm256_srl_epi32(cr_i32, shift_v);
            }

            // Fixed-point YCbCr → RGB
            let yv = _mm256_mullo_epi32(_mm256_sub_epi32(y_i32, y_bias_v), y_scale_v);
            let cb_adj = _mm256_sub_epi32(cb_i32, bias128_v);
            let cr_adj = _mm256_sub_epi32(cr_i32, bias128_v);

            let r = _mm256_sra_epi32(
                _mm256_add_epi32(
                    _mm256_add_epi32(yv, _mm256_mullo_epi32(cr_r_v, cr_adj)),
                    rnd_v,
                ),
                shr_v,
            );
            let g = _mm256_sra_epi32(
                _mm256_add_epi32(
                    _mm256_add_epi32(
                        _mm256_add_epi32(yv, _mm256_mullo_epi32(cb_g_v, cb_adj)),
                        _mm256_mullo_epi32(cr_g_v, cr_adj),
                    ),
                    rnd_v,
                ),
                shr_v,
            );
            let b = _mm256_sra_epi32(
                _mm256_add_epi32(
                    _mm256_add_epi32(yv, _mm256_mullo_epi32(cb_b_v, cb_adj)),
                    rnd_v,
                ),
                shr_v,
            );

            // Clamp [0, 255]
            let r = _mm256_min_epi32(_mm256_max_epi32(r, zero), max255);
            let g = _mm256_min_epi32(_mm256_max_epi32(g, zero), max255);
            let b = _mm256_min_epi32(_mm256_max_epi32(b, zero), max255);

            // Pack i32→i16→u8: each lane gets [r0-3, g0-3, b0-3, 0000]
            let rg = _mm256_packs_epi32(r, g);
            let bz = _mm256_packs_epi32(b, zero);
            let packed = _mm256_packus_epi16(rg, bz);
            let interleaved = _mm256_shuffle_epi8(packed, shuffle);

            // Extract 12 bytes from each 128-bit lane → 24 bytes total
            let mut buf = [0u8; 32];
            _mm256_storeu_si256(&mut buf, interleaved);
            rgb[out_idx..out_idx + 12].copy_from_slice(&buf[..12]);
            rgb[out_idx + 12..out_idx + 24].copy_from_slice(&buf[16..28]);
            out_idx += 24;

            x += 8;
        }

        // Scalar tail: remaining 0–7 pixels
        for x in x_simd_end..x_end {
            scalar_pixel(
                y_plane,
                cb_plane,
                cr_plane,
                y_row,
                c_row,
                x as usize,
                shift,
                y_bias,
                y_scale,
                cr_r,
                cb_g,
                cr_g,
                cb_b,
                rnd,
                shr,
                rgb,
                &mut out_idx,
            );
        }
    }
}

/// Convert a single 4:2:0 pixel (shared between SIMD prefix/tail and scalar path)
#[inline(always)]
#[allow(clippy::too_many_arguments)]
#[allow(dead_code)] // only used from #[arcane] AVX2 path
fn scalar_pixel(
    y_plane: &[u16],
    cb_plane: &[u16],
    cr_plane: &[u16],
    y_row: usize,
    c_row: usize,
    x: usize,
    shift: u32,
    y_bias: i32,
    y_scale: i32,
    cr_r: i32,
    cb_g: i32,
    cr_g: i32,
    cb_b: i32,
    rnd: i32,
    shr: i32,
    rgb: &mut [u8],
    out_idx: &mut usize,
) {
    let y_val = (y_plane[y_row + x] >> shift) as i32;
    let cx = x / 2;
    let c_idx = c_row + cx;
    let cb_val = (cb_plane[c_idx] >> shift) as i32;
    let cr_val = (cr_plane[c_idx] >> shift) as i32;

    let cb = cb_val - 128;
    let cr = cr_val - 128;
    let yv = (y_val - y_bias) * y_scale;
    let r = (yv + cr_r * cr + rnd) >> shr;
    let g = (yv + cb_g * cb + cr_g * cr + rnd) >> shr;
    let b = (yv + cb_b * cb + rnd) >> shr;

    rgb[*out_idx] = r.clamp(0, 255) as u8;
    rgb[*out_idx + 1] = g.clamp(0, 255) as u8;
    rgb[*out_idx + 2] = b.clamp(0, 255) as u8;
    *out_idx += 3;
}
