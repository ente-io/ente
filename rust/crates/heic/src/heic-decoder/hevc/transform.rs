//! HEVC transform and inverse quantization
//!
//! This module implements the inverse transforms used in HEVC:
//! - 4x4 Inverse DST (for intra 4x4 luma)
//! - 4x4, 8x8, 16x16, 32x32 Inverse DCT
//!
//! The 8x8 and 16x16 IDCTs dispatch to AVX2 SIMD via `incant!` when available.

// Transform and inverse quantization for HEVC
use super::transform_simd::{
    dequantize_scalar, idct8_scalar, idct16_scalar, idct32_scalar, idst4_scalar,
};
#[cfg(target_arch = "x86_64")]
use super::transform_simd::{dequantize_v3, idct8_v3, idct16_v3, idct32_v3, idst4_v3};
use archmage::incant;

/// Maximum number of coefficients (32x32 transform)
pub const MAX_COEFF: usize = 32 * 32;

/// DST-VII basis functions for 4x4 (scaled by 64)
static DST4_MATRIX: [[i16; 4]; 4] = [
    [29, 55, 74, 84],
    [74, 74, 0, -74],
    [84, -29, -74, 55],
    [55, -84, 74, -29],
];

/// DCT-II basis functions for 4x4 (scaled by 64)
static DCT4_MATRIX: [[i16; 4]; 4] = [
    [64, 64, 64, 64],
    [83, 36, -36, -83],
    [64, -64, -64, 64],
    [36, -83, 83, -36],
];

/// Inverse 4x4 DST (for intra 4x4 luma blocks)
pub fn idst4(coeffs: &[i16; 16], output: &mut [i16; 16], bit_depth: u8) {
    incant!(idst4(coeffs, output, bit_depth), [v3]);
}

/// Scalar implementation of inverse 4x4 DST
pub(crate) fn idst4_inner(coeffs: &[i16; 16], output: &mut [i16; 16], bit_depth: u8) {
    let shift1 = 7;
    let shift2 = 20 - bit_depth;
    let add1 = 1 << (shift1 - 1);
    let add2 = 1 << (shift2 - 1);

    let mut tmp = [0i32; 16];

    // First pass (vertical)
    for i in 0..4 {
        for j in 0..4 {
            let mut sum = 0i32;
            for k in 0..4 {
                sum += DST4_MATRIX[k][j] as i32 * coeffs[k * 4 + i] as i32;
            }
            // H.265 Eq. 8-314: clip intermediate results to 16-bit range
            tmp[j * 4 + i] = ((sum + add1) >> shift1).clamp(-32768, 32767);
        }
    }

    // Second pass (horizontal)
    for i in 0..4 {
        for j in 0..4 {
            let mut sum = 0i32;
            for k in 0..4 {
                sum += DST4_MATRIX[k][j] as i32 * tmp[i * 4 + k];
            }
            output[i * 4 + j] = ((sum + add2) >> shift2) as i16;
        }
    }
}

/// Inverse 4x4 DCT
pub fn idct4(coeffs: &[i16; 16], output: &mut [i16; 16], bit_depth: u8) {
    let shift1 = 7;
    let shift2 = 20 - bit_depth;
    let add1 = 1 << (shift1 - 1);
    let add2 = 1 << (shift2 - 1);

    let mut tmp = [0i32; 16];

    // First pass (vertical)
    for i in 0..4 {
        for j in 0..4 {
            let mut sum = 0i32;
            for k in 0..4 {
                sum += DCT4_MATRIX[k][j] as i32 * coeffs[k * 4 + i] as i32;
            }
            // H.265 Eq. 8-314: clip intermediate results to 16-bit range
            tmp[j * 4 + i] = ((sum + add1) >> shift1).clamp(-32768, 32767);
        }
    }

    // Second pass (horizontal)
    for i in 0..4 {
        for j in 0..4 {
            let mut sum = 0i32;
            for k in 0..4 {
                sum += DCT4_MATRIX[k][j] as i32 * tmp[i * 4 + k];
            }
            output[i * 4 + j] = ((sum + add2) >> shift2) as i16;
        }
    }
}

/// 8-point partial butterfly IDCT (H.265 8.6.4.2)
///
/// Exploits DCT-II symmetry to reduce 64 multiply-adds to 24 per column.
/// `src` are 8 frequency-domain inputs, `dst` gets 8 spatial-domain outputs.
#[inline(always)]
fn idct8_1d(src: [i32; 8], shift: i32) -> [i32; 8] {
    let add = 1i32 << (shift - 1);

    // Odd part: 4 coefficients × 4 outputs = 16 multiply-adds
    let o0 = 89 * src[1] + 75 * src[3] + 50 * src[5] + 18 * src[7];
    let o1 = 75 * src[1] - 18 * src[3] - 89 * src[5] - 50 * src[7];
    let o2 = 50 * src[1] - 89 * src[3] + 18 * src[5] + 75 * src[7];
    let o3 = 18 * src[1] - 50 * src[3] + 75 * src[5] - 89 * src[7];

    // Even-even part: 2 multiply-adds
    let ee0 = 64 * src[0] + 64 * src[4];
    let ee1 = 64 * src[0] - 64 * src[4];

    // Even-odd part: 4 multiply-adds
    let eo0 = 83 * src[2] + 36 * src[6];
    let eo1 = 36 * src[2] - 83 * src[6];

    // Even part combination
    let e0 = ee0 + eo0;
    let e1 = ee1 + eo1;
    let e2 = ee1 - eo1;
    let e3 = ee0 - eo0;

    // Output with butterfly (E+O / E-O symmetry)
    [
        ((e0 + o0 + add) >> shift).clamp(-32768, 32767),
        ((e1 + o1 + add) >> shift).clamp(-32768, 32767),
        ((e2 + o2 + add) >> shift).clamp(-32768, 32767),
        ((e3 + o3 + add) >> shift).clamp(-32768, 32767),
        ((e3 - o3 + add) >> shift).clamp(-32768, 32767),
        ((e2 - o2 + add) >> shift).clamp(-32768, 32767),
        ((e1 - o1 + add) >> shift).clamp(-32768, 32767),
        ((e0 - o0 + add) >> shift).clamp(-32768, 32767),
    ]
}

/// Inverse 8x8 DCT — dispatches to AVX2 when available, scalar fallback otherwise
pub fn idct8(coeffs: &[i16; 64], output: &mut [i16; 64], bit_depth: u8) {
    incant!(idct8(coeffs, output, bit_depth), [v3])
}

/// Scalar 8x8 IDCT using partial butterfly (called by SIMD scalar fallback)
pub(crate) fn idct8_inner(coeffs: &[i16; 64], output: &mut [i16; 64], bit_depth: u8) {
    let shift1 = 7i32;
    let shift2 = 20 - bit_depth as i32;

    let mut tmp = [0i32; 64];

    // First pass: vertical (column-wise)
    for col in 0..8 {
        let src = [
            coeffs[col] as i32,
            coeffs[8 + col] as i32,
            coeffs[16 + col] as i32,
            coeffs[24 + col] as i32,
            coeffs[32 + col] as i32,
            coeffs[40 + col] as i32,
            coeffs[48 + col] as i32,
            coeffs[56 + col] as i32,
        ];
        let d = idct8_1d(src, shift1);
        for row in 0..8 {
            tmp[row * 8 + col] = d[row];
        }
    }

    // Second pass: horizontal (row-wise)
    for row in 0..8 {
        let base = row * 8;
        let src = [
            tmp[base],
            tmp[base + 1],
            tmp[base + 2],
            tmp[base + 3],
            tmp[base + 4],
            tmp[base + 5],
            tmp[base + 6],
            tmp[base + 7],
        ];
        let d = idct8_1d(src, shift2);
        for col in 0..8 {
            output[base + col] = d[col] as i16;
        }
    }
}

/// 16-point partial butterfly IDCT (H.265 8.6.4.2)
#[inline(always)]
fn idct16_1d(src: [i32; 16], shift: i32) -> [i32; 16] {
    let add = 1i32 << (shift - 1);

    // Odd part: 8 inputs (odd indices) × 8 outputs = 64 multiply-adds
    let s1 = src[1];
    let s3 = src[3];
    let s5 = src[5];
    let s7 = src[7];
    let s9 = src[9];
    let s11 = src[11];
    let s13 = src[13];
    let s15 = src[15];

    let o0 = 90 * s1 + 87 * s3 + 80 * s5 + 70 * s7 + 57 * s9 + 43 * s11 + 25 * s13 + 9 * s15;
    let o1 = 87 * s1 + 57 * s3 + 9 * s5 - 43 * s7 - 80 * s9 - 90 * s11 - 70 * s13 - 25 * s15;
    let o2 = 80 * s1 + 9 * s3 - 70 * s5 - 87 * s7 - 25 * s9 + 57 * s11 + 90 * s13 + 43 * s15;
    let o3 = 70 * s1 - 43 * s3 - 87 * s5 + 9 * s7 + 90 * s9 + 25 * s11 - 80 * s13 - 57 * s15;
    let o4 = 57 * s1 - 80 * s3 - 25 * s5 + 90 * s7 - 9 * s9 - 87 * s11 + 43 * s13 + 70 * s15;
    let o5 = 43 * s1 - 90 * s3 + 57 * s5 + 25 * s7 - 87 * s9 + 70 * s11 + 9 * s13 - 80 * s15;
    let o6 = 25 * s1 - 70 * s3 + 90 * s5 - 80 * s7 + 43 * s9 + 9 * s11 - 57 * s13 + 87 * s15;
    let o7 = 9 * s1 - 25 * s3 + 43 * s5 - 57 * s7 + 70 * s9 - 80 * s11 + 87 * s13 - 90 * s15;

    // Even part: reuse 8-point butterfly on even indices
    let s0 = src[0];
    let s2 = src[2];
    let s4 = src[4];
    let s6 = src[6];
    let s8 = src[8];
    let s10 = src[10];
    let s12 = src[12];
    let s14 = src[14];

    // Even-odd: 4 coefficients
    let eo0 = 89 * s2 + 75 * s6 + 50 * s10 + 18 * s14;
    let eo1 = 75 * s2 - 18 * s6 - 89 * s10 - 50 * s14;
    let eo2 = 50 * s2 - 89 * s6 + 18 * s10 + 75 * s14;
    let eo3 = 18 * s2 - 50 * s6 + 75 * s10 - 89 * s14;

    // Even-even
    let eee0 = 64 * s0 + 64 * s8;
    let eee1 = 64 * s0 - 64 * s8;
    let eeo0 = 83 * s4 + 36 * s12;
    let eeo1 = 36 * s4 - 83 * s12;

    let ee0 = eee0 + eeo0;
    let ee1 = eee1 + eeo1;
    let ee2 = eee1 - eeo1;
    let ee3 = eee0 - eeo0;

    let e0 = ee0 + eo0;
    let e1 = ee1 + eo1;
    let e2 = ee2 + eo2;
    let e3 = ee3 + eo3;
    let e4 = ee3 - eo3;
    let e5 = ee2 - eo2;
    let e6 = ee1 - eo1;
    let e7 = ee0 - eo0;

    [
        ((e0 + o0 + add) >> shift).clamp(-32768, 32767),
        ((e1 + o1 + add) >> shift).clamp(-32768, 32767),
        ((e2 + o2 + add) >> shift).clamp(-32768, 32767),
        ((e3 + o3 + add) >> shift).clamp(-32768, 32767),
        ((e4 + o4 + add) >> shift).clamp(-32768, 32767),
        ((e5 + o5 + add) >> shift).clamp(-32768, 32767),
        ((e6 + o6 + add) >> shift).clamp(-32768, 32767),
        ((e7 + o7 + add) >> shift).clamp(-32768, 32767),
        ((e7 - o7 + add) >> shift).clamp(-32768, 32767),
        ((e6 - o6 + add) >> shift).clamp(-32768, 32767),
        ((e5 - o5 + add) >> shift).clamp(-32768, 32767),
        ((e4 - o4 + add) >> shift).clamp(-32768, 32767),
        ((e3 - o3 + add) >> shift).clamp(-32768, 32767),
        ((e2 - o2 + add) >> shift).clamp(-32768, 32767),
        ((e1 - o1 + add) >> shift).clamp(-32768, 32767),
        ((e0 - o0 + add) >> shift).clamp(-32768, 32767),
    ]
}

/// Inverse 16x16 DCT — dispatches to AVX2 when available, scalar fallback otherwise
pub fn idct16(coeffs: &[i16; 256], output: &mut [i16; 256], bit_depth: u8) {
    incant!(idct16(coeffs, output, bit_depth), [v3])
}

/// Scalar 16x16 IDCT using partial butterfly (called by SIMD scalar fallback)
pub(crate) fn idct16_inner(coeffs: &[i16; 256], output: &mut [i16; 256], bit_depth: u8) {
    let shift1 = 7i32;
    let shift2 = 20 - bit_depth as i32;

    let mut tmp = [0i32; 256];

    // First pass: vertical
    for col in 0..16 {
        let mut src = [0i32; 16];
        for k in 0..16 {
            src[k] = coeffs[k * 16 + col] as i32;
        }
        let d = idct16_1d(src, shift1);
        for row in 0..16 {
            tmp[row * 16 + col] = d[row];
        }
    }

    // Second pass: horizontal
    for row in 0..16 {
        let base = row * 16;
        let mut src = [0i32; 16];
        src.copy_from_slice(&tmp[base..base + 16]);
        let d = idct16_1d(src, shift2);
        for col in 0..16 {
            output[base + col] = d[col] as i16;
        }
    }
}

/// 32-point partial butterfly IDCT (H.265 8.6.4.2)
///
/// Uses 5 stages of butterfly decomposition to reduce 1024 multiply-adds
/// per column to ~350.
#[inline(always)]
fn idct32_1d(src: [i32; 32], shift: i32) -> [i32; 32] {
    let add = 1i32 << (shift - 1);

    // Stage 1: Odd part — 16 inputs (odd indices) × 16 outputs
    let s1 = src[1];
    let s3 = src[3];
    let s5 = src[5];
    let s7 = src[7];
    let s9 = src[9];
    let s11 = src[11];
    let s13 = src[13];
    let s15 = src[15];
    let s17 = src[17];
    let s19 = src[19];
    let s21 = src[21];
    let s23 = src[23];
    let s25 = src[25];
    let s27 = src[27];
    let s29 = src[29];
    let s31 = src[31];

    // DCT32 odd coefficients from H.265 Table 8-5 (rows 1,3,5,...,31)
    let o0 = 90 * s1
        + 90 * s3
        + 88 * s5
        + 85 * s7
        + 82 * s9
        + 78 * s11
        + 73 * s13
        + 67 * s15
        + 61 * s17
        + 54 * s19
        + 46 * s21
        + 38 * s23
        + 31 * s25
        + 22 * s27
        + 13 * s29
        + 4 * s31;
    let o1 = 90 * s1 + 82 * s3 + 67 * s5 + 46 * s7 + 22 * s9
        - 4 * s11
        - 31 * s13
        - 54 * s15
        - 73 * s17
        - 85 * s19
        - 90 * s21
        - 88 * s23
        - 78 * s25
        - 61 * s27
        - 38 * s29
        - 13 * s31;
    let o2 = 88 * s1 + 67 * s3 + 31 * s5
        - 13 * s7
        - 54 * s9
        - 82 * s11
        - 90 * s13
        - 78 * s15
        - 46 * s17
        - 4 * s19
        + 38 * s21
        + 73 * s23
        + 90 * s25
        + 85 * s27
        + 61 * s29
        + 22 * s31;
    let o3 = 85 * s1 + 46 * s3 - 13 * s5 - 67 * s7 - 90 * s9 - 73 * s11 - 22 * s13
        + 38 * s15
        + 82 * s17
        + 88 * s19
        + 54 * s21
        - 4 * s23
        - 61 * s25
        - 90 * s27
        - 78 * s29
        - 31 * s31;
    let o4 =
        82 * s1 + 22 * s3 - 54 * s5 - 90 * s7 - 61 * s9 + 13 * s11 + 78 * s13 + 85 * s15 + 31 * s17
            - 46 * s19
            - 90 * s21
            - 67 * s23
            + 4 * s25
            + 73 * s27
            + 88 * s29
            + 38 * s31;
    let o5 = 78 * s1 - 4 * s3 - 82 * s5 - 73 * s7 + 13 * s9 + 85 * s11 + 67 * s13
        - 22 * s15
        - 88 * s17
        - 61 * s19
        + 31 * s21
        + 90 * s23
        + 54 * s25
        - 38 * s27
        - 90 * s29
        - 46 * s31;
    let o6 =
        73 * s1 - 31 * s3 - 90 * s5 - 22 * s7 + 78 * s9 + 67 * s11 - 38 * s13 - 90 * s15 - 13 * s17
            + 82 * s19
            + 61 * s21
            - 46 * s23
            - 88 * s25
            - 4 * s27
            + 85 * s29
            + 54 * s31;
    let o7 = 67 * s1 - 54 * s3 - 78 * s5 + 38 * s7 + 85 * s9 - 22 * s11 - 90 * s13
        + 4 * s15
        + 90 * s17
        + 13 * s19
        - 88 * s21
        - 31 * s23
        + 82 * s25
        + 46 * s27
        - 73 * s29
        - 61 * s31;
    let o8 = 61 * s1 - 73 * s3 - 46 * s5 + 82 * s7 + 31 * s9 - 88 * s11 - 13 * s13 + 90 * s15
        - 4 * s17
        - 90 * s19
        + 22 * s21
        + 85 * s23
        - 38 * s25
        - 78 * s27
        + 54 * s29
        + 67 * s31;
    let o9 = 54 * s1 - 85 * s3 - 4 * s5 + 88 * s7 - 46 * s9 - 61 * s11 + 82 * s13 + 13 * s15
        - 90 * s17
        + 38 * s19
        + 67 * s21
        - 78 * s23
        - 22 * s25
        + 90 * s27
        - 31 * s29
        - 73 * s31;
    let o10 = 46 * s1 - 90 * s3 + 38 * s5 + 54 * s7 - 90 * s9 + 31 * s11 + 61 * s13 - 88 * s15
        + 22 * s17
        + 67 * s19
        - 85 * s21
        + 13 * s23
        + 73 * s25
        - 82 * s27
        + 4 * s29
        + 78 * s31;
    let o11 = 38 * s1 - 88 * s3 + 73 * s5 - 4 * s7 - 67 * s9 + 90 * s11 - 46 * s13 - 31 * s15
        + 85 * s17
        - 78 * s19
        + 13 * s21
        + 61 * s23
        - 90 * s25
        + 54 * s27
        + 22 * s29
        - 82 * s31;
    let o12 = 31 * s1 - 78 * s3 + 90 * s5 - 61 * s7 + 4 * s9 + 54 * s11 - 88 * s13 + 82 * s15
        - 38 * s17
        - 22 * s19
        + 73 * s21
        - 90 * s23
        + 67 * s25
        - 13 * s27
        - 46 * s29
        + 85 * s31;
    let o13 = 22 * s1 - 61 * s3 + 85 * s5 - 90 * s7 + 73 * s9 - 38 * s11 - 4 * s13 + 46 * s15
        - 78 * s17
        + 90 * s19
        - 82 * s21
        + 54 * s23
        - 13 * s25
        - 31 * s27
        + 67 * s29
        - 88 * s31;
    let o14 = 13 * s1 - 38 * s3 + 61 * s5 - 78 * s7 + 88 * s9 - 90 * s11 + 85 * s13 - 73 * s15
        + 54 * s17
        - 31 * s19
        + 4 * s21
        + 22 * s23
        - 46 * s25
        + 67 * s27
        - 82 * s29
        + 90 * s31;
    let o15 = 4 * s1 - 13 * s3 + 22 * s5 - 31 * s7 + 38 * s9 - 46 * s11 + 54 * s13 - 61 * s15
        + 67 * s17
        - 73 * s19
        + 78 * s21
        - 82 * s23
        + 85 * s25
        - 88 * s27
        + 90 * s29
        - 90 * s31;

    // Even part: 16-point butterfly on even indices
    let s0 = src[0];
    let s2 = src[2];
    let s4 = src[4];
    let s6 = src[6];
    let s8 = src[8];
    let s10 = src[10];
    let s12 = src[12];
    let s14 = src[14];
    let s16 = src[16];
    let s18 = src[18];
    let s20 = src[20];
    let s22 = src[22];
    let s24 = src[24];
    let s26 = src[26];
    let s28 = src[28];
    let s30 = src[30];

    // Even-odd: 8 outputs from odd-indexed even inputs
    let eo0 = 90 * s2 + 87 * s6 + 80 * s10 + 70 * s14 + 57 * s18 + 43 * s22 + 25 * s26 + 9 * s30;
    let eo1 = 87 * s2 + 57 * s6 + 9 * s10 - 43 * s14 - 80 * s18 - 90 * s22 - 70 * s26 - 25 * s30;
    let eo2 = 80 * s2 + 9 * s6 - 70 * s10 - 87 * s14 - 25 * s18 + 57 * s22 + 90 * s26 + 43 * s30;
    let eo3 = 70 * s2 - 43 * s6 - 87 * s10 + 9 * s14 + 90 * s18 + 25 * s22 - 80 * s26 - 57 * s30;
    let eo4 = 57 * s2 - 80 * s6 - 25 * s10 + 90 * s14 - 9 * s18 - 87 * s22 + 43 * s26 + 70 * s30;
    let eo5 = 43 * s2 - 90 * s6 + 57 * s10 + 25 * s14 - 87 * s18 + 70 * s22 + 9 * s26 - 80 * s30;
    let eo6 = 25 * s2 - 70 * s6 + 90 * s10 - 80 * s14 + 43 * s18 + 9 * s22 - 57 * s26 + 87 * s30;
    let eo7 = 9 * s2 - 25 * s6 + 43 * s10 - 57 * s14 + 70 * s18 - 80 * s22 + 87 * s26 - 90 * s30;

    // Even-even: 8-point butterfly on doubly-even inputs
    let eeo0 = 89 * s4 + 75 * s12 + 50 * s20 + 18 * s28;
    let eeo1 = 75 * s4 - 18 * s12 - 89 * s20 - 50 * s28;
    let eeo2 = 50 * s4 - 89 * s12 + 18 * s20 + 75 * s28;
    let eeo3 = 18 * s4 - 50 * s12 + 75 * s20 - 89 * s28;

    let eeee0 = 64 * s0 + 64 * s16;
    let eeee1 = 64 * s0 - 64 * s16;
    let eeeo0 = 83 * s8 + 36 * s24;
    let eeeo1 = 36 * s8 - 83 * s24;

    let eee0 = eeee0 + eeeo0;
    let eee1 = eeee1 + eeeo1;
    let eee2 = eeee1 - eeeo1;
    let eee3 = eeee0 - eeeo0;

    let ee0 = eee0 + eeo0;
    let ee1 = eee1 + eeo1;
    let ee2 = eee2 + eeo2;
    let ee3 = eee3 + eeo3;
    let ee4 = eee3 - eeo3;
    let ee5 = eee2 - eeo2;
    let ee6 = eee1 - eeo1;
    let ee7 = eee0 - eeo0;

    let e0 = ee0 + eo0;
    let e1 = ee1 + eo1;
    let e2 = ee2 + eo2;
    let e3 = ee3 + eo3;
    let e4 = ee4 + eo4;
    let e5 = ee5 + eo5;
    let e6 = ee6 + eo6;
    let e7 = ee7 + eo7;
    let e8 = ee7 - eo7;
    let e9 = ee6 - eo6;
    let e10 = ee5 - eo5;
    let e11 = ee4 - eo4;
    let e12 = ee3 - eo3;
    let e13 = ee2 - eo2;
    let e14 = ee1 - eo1;
    let e15 = ee0 - eo0;

    [
        ((e0 + o0 + add) >> shift).clamp(-32768, 32767),
        ((e1 + o1 + add) >> shift).clamp(-32768, 32767),
        ((e2 + o2 + add) >> shift).clamp(-32768, 32767),
        ((e3 + o3 + add) >> shift).clamp(-32768, 32767),
        ((e4 + o4 + add) >> shift).clamp(-32768, 32767),
        ((e5 + o5 + add) >> shift).clamp(-32768, 32767),
        ((e6 + o6 + add) >> shift).clamp(-32768, 32767),
        ((e7 + o7 + add) >> shift).clamp(-32768, 32767),
        ((e8 + o8 + add) >> shift).clamp(-32768, 32767),
        ((e9 + o9 + add) >> shift).clamp(-32768, 32767),
        ((e10 + o10 + add) >> shift).clamp(-32768, 32767),
        ((e11 + o11 + add) >> shift).clamp(-32768, 32767),
        ((e12 + o12 + add) >> shift).clamp(-32768, 32767),
        ((e13 + o13 + add) >> shift).clamp(-32768, 32767),
        ((e14 + o14 + add) >> shift).clamp(-32768, 32767),
        ((e15 + o15 + add) >> shift).clamp(-32768, 32767),
        ((e15 - o15 + add) >> shift).clamp(-32768, 32767),
        ((e14 - o14 + add) >> shift).clamp(-32768, 32767),
        ((e13 - o13 + add) >> shift).clamp(-32768, 32767),
        ((e12 - o12 + add) >> shift).clamp(-32768, 32767),
        ((e11 - o11 + add) >> shift).clamp(-32768, 32767),
        ((e10 - o10 + add) >> shift).clamp(-32768, 32767),
        ((e9 - o9 + add) >> shift).clamp(-32768, 32767),
        ((e8 - o8 + add) >> shift).clamp(-32768, 32767),
        ((e7 - o7 + add) >> shift).clamp(-32768, 32767),
        ((e6 - o6 + add) >> shift).clamp(-32768, 32767),
        ((e5 - o5 + add) >> shift).clamp(-32768, 32767),
        ((e4 - o4 + add) >> shift).clamp(-32768, 32767),
        ((e3 - o3 + add) >> shift).clamp(-32768, 32767),
        ((e2 - o2 + add) >> shift).clamp(-32768, 32767),
        ((e1 - o1 + add) >> shift).clamp(-32768, 32767),
        ((e0 - o0 + add) >> shift).clamp(-32768, 32767),
    ]
}

/// Inverse 32x32 DCT — dispatches to AVX2 when available, scalar fallback otherwise
pub fn idct32(coeffs: &[i16; 1024], output: &mut [i16; 1024], bit_depth: u8) {
    incant!(idct32(coeffs, output, bit_depth), [v3])
}

/// Scalar 32x32 IDCT using partial butterfly (called by SIMD scalar fallback)
pub(crate) fn idct32_inner(coeffs: &[i16; 1024], output: &mut [i16; 1024], bit_depth: u8) {
    let shift1 = 7i32;
    let shift2 = 20 - bit_depth as i32;

    let mut tmp = [0i32; 1024];

    // First pass: vertical
    for col in 0..32 {
        let mut src = [0i32; 32];
        for k in 0..32 {
            src[k] = coeffs[k * 32 + col] as i32;
        }
        let d = idct32_1d(src, shift1);
        for row in 0..32 {
            tmp[row * 32 + col] = d[row];
        }
    }

    // Second pass: horizontal
    for row in 0..32 {
        let base = row * 32;
        let mut src = [0i32; 32];
        src.copy_from_slice(&tmp[base..base + 32]);
        let d = idct32_1d(src, shift2);
        for col in 0..32 {
            output[base + col] = d[col] as i16;
        }
    }
}

/// Dequantization parameters
#[derive(Debug, Clone, Copy)]
pub struct DequantParams {
    /// QP value
    pub qp: i32,
    /// Bit depth
    pub bit_depth: u8,
    /// Transform size log2
    pub log2_tr_size: u8,
}

/// Dequantize coefficients (flat scaling — when scaling lists disabled)
pub fn dequantize(coeffs: &mut [i16], params: DequantParams) {
    // Scaling factors from H.265 Table 8-8
    static LEVEL_SCALE: [i32; 6] = [40, 45, 51, 57, 64, 72];

    let qp_per = params.qp / 6;
    let qp_rem = params.qp % 6;
    let scale = LEVEL_SCALE[qp_rem as usize];
    let combined_scale = scale * (1 << qp_per);

    // When m[x][y]=16 (flat), absorb the factor into shift: bdShift - 4
    let shift = params.bit_depth as i32 - 9 + params.log2_tr_size as i32;
    let add = if shift > 0 { 1 << (shift - 1) } else { 0 };

    if shift >= 0 {
        incant!(dequantize(coeffs, combined_scale, shift, add), [v3]);
    } else {
        // Negative shift (left shift) — rare, keep scalar
        let neg_shift = -shift;
        for coef in coeffs.iter_mut() {
            let value = (*coef as i32 * combined_scale) << neg_shift;
            *coef = value.clamp(-32768, 32767) as i16;
        }
    }
}

/// Dequantize coefficients with per-position scaling factors (H.265 8.6.3 Eq 8-309)
///
/// `scaling_matrix`: pre-computed m[x][y] values in raster order (size*size entries)
pub fn dequantize_scaled(coeffs: &mut [i16], params: DequantParams, scaling_matrix: &[u8]) {
    static LEVEL_SCALE: [i32; 6] = [40, 45, 51, 57, 64, 72];

    let qp_per = params.qp / 6;
    let qp_rem = params.qp % 6;
    let level_scale = LEVEL_SCALE[qp_rem as usize];

    // Full bdShift = BitDepth + Log2(nTbS) - 5 (H.265 Eq 8-309)
    let bd_shift = params.bit_depth as i32 + params.log2_tr_size as i32 - 5;
    let add = if bd_shift > 0 { 1 << (bd_shift - 1) } else { 0 };

    if bd_shift >= 0 {
        for (i, coef) in coeffs.iter_mut().enumerate() {
            let m = scaling_matrix.get(i).copied().unwrap_or(16) as i32;
            let value = (*coef as i32 * m * level_scale * (1 << qp_per) + add) >> bd_shift;
            *coef = value.clamp(-32768, 32767) as i16;
        }
    } else {
        let neg_shift = -bd_shift;
        for (i, coef) in coeffs.iter_mut().enumerate() {
            let m = scaling_matrix.get(i).copied().unwrap_or(16) as i32;
            let value = (*coef as i32 * m * level_scale * (1 << qp_per)) << neg_shift;
            *coef = value.clamp(-32768, 32767) as i16;
        }
    }
}

/// Generic inverse transform dispatch
#[inline(always)]
pub fn inverse_transform(
    coeffs: &[i16],
    output: &mut [i16],
    size: usize,
    bit_depth: u8,
    is_intra_4x4_luma: bool,
) {
    match size {
        4 => {
            // Use try_into to get sized array references without copies
            let in_arr: &[i16; 16] = coeffs[..16].try_into().unwrap();
            let out_arr: &mut [i16; 16] = (&mut output[..16]).try_into().unwrap();

            if is_intra_4x4_luma {
                idst4(in_arr, out_arr, bit_depth);
            } else {
                idct4(in_arr, out_arr, bit_depth);
            }
        }
        8 => {
            let in_arr: &[i16; 64] = coeffs[..64].try_into().unwrap();
            let out_arr: &mut [i16; 64] = (&mut output[..64]).try_into().unwrap();
            idct8(in_arr, out_arr, bit_depth);
        }
        16 => {
            let in_arr: &[i16; 256] = coeffs[..256].try_into().unwrap();
            let out_arr: &mut [i16; 256] = (&mut output[..256]).try_into().unwrap();
            idct16(in_arr, out_arr, bit_depth);
        }
        32 => {
            let in_arr: &[i16; 1024] = coeffs[..1024].try_into().unwrap();
            let out_arr: &mut [i16; 1024] = (&mut output[..1024]).try_into().unwrap();
            idct32(in_arr, out_arr, bit_depth);
        }
        _ => {}
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_idct4_dc_only() {
        // With DC coefficient = 64 (after dequant), all output samples should be equal
        let mut coeffs = [0i16; 16];
        coeffs[0] = 64; // DC coefficient at (0,0)

        let mut output = [0i16; 16];
        idct4(&coeffs, &mut output, 8);

        println!("IDCT4 output with DC=64:");
        for y in 0..4 {
            println!("  {:?}", &output[y * 4..y * 4 + 4]);
        }

        // For DC-only input, DCT should produce uniform output
        // DC value propagates as: DC * 64 * 64 >> 7 >> 12 = DC >> 7 = 0 for DC=64
        // Actually: 64 * 64 >> 7 = 32 for first pass per sample
        // Then 32 * 64 * 4 >> 12 = 32 for each output
        // Let me just verify all outputs are equal
        let first = output[0];
        for &v in &output {
            assert_eq!(v, first, "DC-only should produce uniform output");
        }
    }

    #[test]
    fn test_idst4_dc_only() {
        let mut coeffs = [0i16; 16];
        coeffs[0] = 64; // DC coefficient

        let mut output = [0i16; 16];
        idst4(&coeffs, &mut output, 8);

        println!("IDST4 output with DC=64:");
        for y in 0..4 {
            println!("  {:?}", &output[y * 4..y * 4 + 4]);
        }

        // DST doesn't produce uniform output for DC input (unlike DCT)
        // Just verify it produces non-zero values
        let non_zero = output.iter().any(|&v| v != 0);
        assert!(
            non_zero,
            "IDST4 should produce non-zero output for DC input"
        );
    }

    #[test]
    fn test_idst4_with_real_coeffs() {
        // Use actual coefficients from our first decoded TU
        let mut coeffs = [0i16; 16];
        // Dequantized coeffs: [144, -3024, -288, 0, -144, -432, -288, 0, 144, -576, 432, 0, -144, 288, 288, 0]
        coeffs[0] = 144;
        coeffs[1] = -3024;
        coeffs[2] = -288;
        coeffs[4] = -144;
        coeffs[5] = -432;
        coeffs[6] = -288;
        coeffs[8] = 144;
        coeffs[9] = -576;
        coeffs[10] = 432;
        coeffs[12] = -144;
        coeffs[13] = 288;
        coeffs[14] = 288;

        let mut output = [0i16; 16];
        idst4(&coeffs, &mut output, 8);

        println!("IDST4 output with real coefficients:");
        for y in 0..4 {
            println!("  {:?}", &output[y * 4..y * 4 + 4]);
        }
        println!(
            "Expected residuals: [-18, -23, -4, 23, -41, -24, 11, 22, -28, -22, 3, 18, -33, -34, 3, 44]"
        );
    }
}
