//! AVX2 SIMD implementations of HEVC inverse transforms (IDCT 8/16/32)
//!
//! Uses the interleave + madd_epi16 approach from libde265, adapted for AVX2.
//! The key operation is `_mm256_madd_epi16`: multiply 16 pairs of i16, sum adjacent
//! pairs → 8 i32. This perfectly matches the DCT butterfly's multiply-accumulate pattern.

use archmage::prelude::*;

#[cfg(target_arch = "x86_64")]
use safe_unaligned_simd::x86_64::{
    _mm_loadu_si128, _mm_storeu_si128, _mm256_loadu_si256, _mm256_storeu_si256,
};

/// Pack two i16 coefficients into one i32 for `_mm256_set1_epi32` + `_mm256_madd_epi16`.
/// `a` goes in the low 16 bits (multiplies the first element of each interleaved pair),
/// `b` goes in the high 16 bits (multiplies the second element).
#[cfg(target_arch = "x86_64")]
const fn pack(a: i16, b: i16) -> i32 {
    (a as i32 & 0xFFFF) | ((b as i32) << 16)
}

// =============================================================================
// 8x8 IDCT
// =============================================================================

/// Transpose an 8x8 matrix of i16 values stored in 8 __m128i registers.
/// Uses 3 phases of unpack operations (24 instructions total).
#[cfg(target_arch = "x86_64")]
#[rite]
#[allow(clippy::too_many_arguments)]
fn transpose_8x8(
    _token: X64V3Token,
    r0: __m128i,
    r1: __m128i,
    r2: __m128i,
    r3: __m128i,
    r4: __m128i,
    r5: __m128i,
    r6: __m128i,
    r7: __m128i,
) -> (
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
) {
    // Phase 1: interleave 16-bit pairs
    let t0 = _mm_unpacklo_epi16(r0, r1);
    let t1 = _mm_unpackhi_epi16(r0, r1);
    let t2 = _mm_unpacklo_epi16(r2, r3);
    let t3 = _mm_unpackhi_epi16(r2, r3);
    let t4 = _mm_unpacklo_epi16(r4, r5);
    let t5 = _mm_unpackhi_epi16(r4, r5);
    let t6 = _mm_unpacklo_epi16(r6, r7);
    let t7 = _mm_unpackhi_epi16(r6, r7);

    // Phase 2: interleave 32-bit pairs
    let u0 = _mm_unpacklo_epi32(t0, t2);
    let u1 = _mm_unpackhi_epi32(t0, t2);
    let u2 = _mm_unpacklo_epi32(t1, t3);
    let u3 = _mm_unpackhi_epi32(t1, t3);
    let u4 = _mm_unpacklo_epi32(t4, t6);
    let u5 = _mm_unpackhi_epi32(t4, t6);
    let u6 = _mm_unpacklo_epi32(t5, t7);
    let u7 = _mm_unpackhi_epi32(t5, t7);

    // Phase 3: interleave 64-bit pairs
    (
        _mm_unpacklo_epi64(u0, u4),
        _mm_unpackhi_epi64(u0, u4),
        _mm_unpacklo_epi64(u1, u5),
        _mm_unpackhi_epi64(u1, u5),
        _mm_unpacklo_epi64(u2, u6),
        _mm_unpackhi_epi64(u2, u6),
        _mm_unpacklo_epi64(u3, u7),
        _mm_unpackhi_epi64(u3, u7),
    )
}

/// 8-point 1D IDCT on 8 columns simultaneously.
/// Input: 8 rows as __m128i (each row = 8 i16 values, one per column).
/// Output: 8 transformed rows as __m128i (i16, clamped via saturating pack).
#[cfg(target_arch = "x86_64")]
#[rite]
#[allow(clippy::too_many_arguments)]
fn idct8_1d_columns(
    _token: X64V3Token,
    r0: __m128i,
    r1: __m128i,
    r2: __m128i,
    r3: __m128i,
    r4: __m128i,
    r5: __m128i,
    r6: __m128i,
    r7: __m128i,
    shift: __m128i,
    add: __m256i,
) -> (
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
    __m128i,
) {
    // Interleave odd rows: (r1,r3) and (r5,r7)
    // Each pair produces a __m256i with interleaved values for all 8 columns
    let i13 = _mm256_set_m128i(_mm_unpackhi_epi16(r1, r3), _mm_unpacklo_epi16(r1, r3));
    let i57 = _mm256_set_m128i(_mm_unpackhi_epi16(r5, r7), _mm_unpacklo_epi16(r5, r7));

    // Odd part: O[k] = sum of coefficient * odd_row products
    // O[0] = 89*r1 + 75*r3 + 50*r5 + 18*r7
    let o0 = _mm256_add_epi32(
        _mm256_madd_epi16(i13, _mm256_set1_epi32(pack(89, 75))),
        _mm256_madd_epi16(i57, _mm256_set1_epi32(pack(50, 18))),
    );
    // O[1] = 75*r1 - 18*r3 - 89*r5 - 50*r7
    let o1 = _mm256_add_epi32(
        _mm256_madd_epi16(i13, _mm256_set1_epi32(pack(75, -18))),
        _mm256_madd_epi16(i57, _mm256_set1_epi32(pack(-89, -50))),
    );
    // O[2] = 50*r1 - 89*r3 + 18*r5 + 75*r7
    let o2 = _mm256_add_epi32(
        _mm256_madd_epi16(i13, _mm256_set1_epi32(pack(50, -89))),
        _mm256_madd_epi16(i57, _mm256_set1_epi32(pack(18, 75))),
    );
    // O[3] = 18*r1 - 50*r3 + 75*r5 - 89*r7
    let o3 = _mm256_add_epi32(
        _mm256_madd_epi16(i13, _mm256_set1_epi32(pack(18, -50))),
        _mm256_madd_epi16(i57, _mm256_set1_epi32(pack(75, -89))),
    );

    // Interleave even rows: (r0,r4) and (r2,r6)
    let i04 = _mm256_set_m128i(_mm_unpackhi_epi16(r0, r4), _mm_unpacklo_epi16(r0, r4));
    let i26 = _mm256_set_m128i(_mm_unpackhi_epi16(r2, r6), _mm_unpacklo_epi16(r2, r6));

    // Even-even: EE[0] = 64*r0 + 64*r4, EE[1] = 64*r0 - 64*r4
    let ee0 = _mm256_madd_epi16(i04, _mm256_set1_epi32(pack(64, 64)));
    let ee1 = _mm256_madd_epi16(i04, _mm256_set1_epi32(pack(64, -64)));

    // Even-odd: EO[0] = 83*r2 + 36*r6, EO[1] = 36*r2 - 83*r6
    let eo0 = _mm256_madd_epi16(i26, _mm256_set1_epi32(pack(83, 36)));
    let eo1 = _mm256_madd_epi16(i26, _mm256_set1_epi32(pack(36, -83)));

    // Even combination: E[0..3]
    let e0 = _mm256_add_epi32(ee0, eo0);
    let e1 = _mm256_add_epi32(ee1, eo1);
    let e2 = _mm256_sub_epi32(ee1, eo1);
    let e3 = _mm256_sub_epi32(ee0, eo0);

    // Butterfly + round + shift: d[k] = (E[k] ± O[k] + add) >> shift
    let d0 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32(e0, o0), add), shift);
    let d1 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32(e1, o1), add), shift);
    let d2 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32(e2, o2), add), shift);
    let d3 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32(e3, o3), add), shift);
    let d4 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32(e3, o3), add), shift);
    let d5 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32(e2, o2), add), shift);
    let d6 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32(e1, o1), add), shift);
    let d7 = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32(e0, o0), add), shift);

    // Pack i32→i16 with saturation (provides the spec-required clamp to [-32768, 32767])
    // _mm256_packs_epi32 operates within 128-bit lanes, so we fix with permute4x64
    let p01 = _mm256_permute4x64_epi64::<0xD8>(_mm256_packs_epi32(d0, d1));
    let p23 = _mm256_permute4x64_epi64::<0xD8>(_mm256_packs_epi32(d2, d3));
    let p45 = _mm256_permute4x64_epi64::<0xD8>(_mm256_packs_epi32(d4, d5));
    let p67 = _mm256_permute4x64_epi64::<0xD8>(_mm256_packs_epi32(d6, d7));

    // Extract individual rows
    (
        _mm256_castsi256_si128(p01),
        _mm256_extracti128_si256::<1>(p01),
        _mm256_castsi256_si128(p23),
        _mm256_extracti128_si256::<1>(p23),
        _mm256_castsi256_si128(p45),
        _mm256_extracti128_si256::<1>(p45),
        _mm256_castsi256_si128(p67),
        _mm256_extracti128_si256::<1>(p67),
    )
}

/// AVX2 8x8 IDCT entry point
#[arcane]
pub(crate) fn idct8_v3(
    _token: X64V3Token,
    coeffs: &[i16; 64],
    output: &mut [i16; 64],
    bit_depth: u8,
) {
    // Load 8 input rows
    let r0 = _mm_loadu_si128::<[i16; 8]>(coeffs[0..8].try_into().unwrap());
    let r1 = _mm_loadu_si128::<[i16; 8]>(coeffs[8..16].try_into().unwrap());
    let r2 = _mm_loadu_si128::<[i16; 8]>(coeffs[16..24].try_into().unwrap());
    let r3 = _mm_loadu_si128::<[i16; 8]>(coeffs[24..32].try_into().unwrap());
    let r4 = _mm_loadu_si128::<[i16; 8]>(coeffs[32..40].try_into().unwrap());
    let r5 = _mm_loadu_si128::<[i16; 8]>(coeffs[40..48].try_into().unwrap());
    let r6 = _mm_loadu_si128::<[i16; 8]>(coeffs[48..56].try_into().unwrap());
    let r7 = _mm_loadu_si128::<[i16; 8]>(coeffs[56..64].try_into().unwrap());

    // Pass 1: vertical (column transform), shift = 7
    let shift1 = _mm_cvtsi32_si128(7);
    let add1 = _mm256_set1_epi32(1 << 6); // 1 << (7-1) = 64
    let (d0, d1, d2, d3, d4, d5, d6, d7) =
        idct8_1d_columns(_token, r0, r1, r2, r3, r4, r5, r6, r7, shift1, add1);

    // Transpose for horizontal pass
    let (t0, t1, t2, t3, t4, t5, t6, t7) = transpose_8x8(_token, d0, d1, d2, d3, d4, d5, d6, d7);

    // Pass 2: horizontal (row transform), shift = 20 - bit_depth
    let shift2 = 20 - bit_depth as i32;
    let shift2_v = _mm_cvtsi32_si128(shift2);
    let add2 = _mm256_set1_epi32(1 << (shift2 - 1));
    let (e0, e1, e2, e3, e4, e5, e6, e7) =
        idct8_1d_columns(_token, t0, t1, t2, t3, t4, t5, t6, t7, shift2_v, add2);

    // Transpose back for row-major storage
    let (f0, f1, f2, f3, f4, f5, f6, f7) = transpose_8x8(_token, e0, e1, e2, e3, e4, e5, e6, e7);

    // Store 8 output rows (combine pairs into __m256i for efficient 256-bit stores)
    let out01 = _mm256_set_m128i(f1, f0);
    let out23 = _mm256_set_m128i(f3, f2);
    let out45 = _mm256_set_m128i(f5, f4);
    let out67 = _mm256_set_m128i(f7, f6);
    _mm256_storeu_si256::<[i16; 16]>((&mut output[0..16]).try_into().unwrap(), out01);
    _mm256_storeu_si256::<[i16; 16]>((&mut output[16..32]).try_into().unwrap(), out23);
    _mm256_storeu_si256::<[i16; 16]>((&mut output[32..48]).try_into().unwrap(), out45);
    _mm256_storeu_si256::<[i16; 16]>((&mut output[48..64]).try_into().unwrap(), out67);
}

/// Scalar fallback for 8x8 IDCT
pub(crate) fn idct8_scalar(
    _token: ScalarToken,
    coeffs: &[i16; 64],
    output: &mut [i16; 64],
    bit_depth: u8,
) {
    super::transform::idct8_inner(coeffs, output, bit_depth);
}

// =============================================================================
// 16x16 IDCT
// =============================================================================

/// 16-point 1D IDCT on 16 columns simultaneously.
/// Input: 16 rows as __m256i (each row = 16 i16 values).
/// Output: 16 transformed rows as __m256i (i16, clamped via saturating pack).
///
/// The odd part processes 8 odd-indexed inputs (rows 1,3,5,7,9,11,13,15) to
/// produce 8 outputs. The even part recursively applies the 8-point structure
/// on even-indexed inputs.
#[cfg(target_arch = "x86_64")]
#[rite]
#[allow(clippy::too_many_arguments)]
fn idct16_1d_columns(
    _token: X64V3Token,
    r: &[__m256i; 16],
    shift: __m128i,
    add: __m256i,
) -> [__m256i; 16] {
    // For 256-bit rows, unpacklo/hi_epi16 operates within each 128-bit lane,
    // which naturally processes columns 0-3,8-11 (lo) and 4-7,12-15 (hi).
    // After packs_epi32(lo_result, hi_result), columns reassemble correctly.

    // Helper: interleave two 256-bit rows and madd with coefficient pair
    macro_rules! interleave_madd {
        ($ra:expr, $rb:expr, $ca:expr, $cb:expr) => {{
            let lo = _mm256_unpacklo_epi16($ra, $rb);
            let hi = _mm256_unpackhi_epi16($ra, $rb);
            let coeff = _mm256_set1_epi32(pack($ca, $cb));
            (_mm256_madd_epi16(lo, coeff), _mm256_madd_epi16(hi, coeff))
        }};
    }

    // Helper: accumulate 4 pairs of madd results into (lo, hi) sums
    macro_rules! sum4_pairs {
        (($ra1:expr, $rb1:expr, $ca1:expr, $cb1:expr),
         ($ra2:expr, $rb2:expr, $ca2:expr, $cb2:expr),
         ($ra3:expr, $rb3:expr, $ca3:expr, $cb3:expr),
         ($ra4:expr, $rb4:expr, $ca4:expr, $cb4:expr)) => {{
            let (l1, h1) = interleave_madd!($ra1, $rb1, $ca1, $cb1);
            let (l2, h2) = interleave_madd!($ra2, $rb2, $ca2, $cb2);
            let (l3, h3) = interleave_madd!($ra3, $rb3, $ca3, $cb3);
            let (l4, h4) = interleave_madd!($ra4, $rb4, $ca4, $cb4);
            (
                _mm256_add_epi32(_mm256_add_epi32(l1, l2), _mm256_add_epi32(l3, l4)),
                _mm256_add_epi32(_mm256_add_epi32(h1, h2), _mm256_add_epi32(h3, h4)),
            )
        }};
    }

    // Odd part: 8 outputs from rows 1,3,5,7,9,11,13,15
    // O[0] = 90*r1 + 87*r3 + 80*r5 + 70*r7 + 57*r9 + 43*r11 + 25*r13 + 9*r15
    let (o0l, o0h) = sum4_pairs!(
        (r[1], r[3], 90, 87),
        (r[5], r[7], 80, 70),
        (r[9], r[11], 57, 43),
        (r[13], r[15], 25, 9)
    );
    let (o1l, o1h) = sum4_pairs!(
        (r[1], r[3], 87, 57),
        (r[5], r[7], 9, -43),
        (r[9], r[11], -80, -90),
        (r[13], r[15], -70, -25)
    );
    let (o2l, o2h) = sum4_pairs!(
        (r[1], r[3], 80, 9),
        (r[5], r[7], -70, -87),
        (r[9], r[11], -25, 57),
        (r[13], r[15], 90, 43)
    );
    let (o3l, o3h) = sum4_pairs!(
        (r[1], r[3], 70, -43),
        (r[5], r[7], -87, 9),
        (r[9], r[11], 90, 25),
        (r[13], r[15], -80, -57)
    );
    let (o4l, o4h) = sum4_pairs!(
        (r[1], r[3], 57, -80),
        (r[5], r[7], -25, 90),
        (r[9], r[11], -9, -87),
        (r[13], r[15], 43, 70)
    );
    let (o5l, o5h) = sum4_pairs!(
        (r[1], r[3], 43, -90),
        (r[5], r[7], 57, 25),
        (r[9], r[11], -87, 70),
        (r[13], r[15], 9, -80)
    );
    let (o6l, o6h) = sum4_pairs!(
        (r[1], r[3], 25, -70),
        (r[5], r[7], 90, -80),
        (r[9], r[11], 43, 9),
        (r[13], r[15], -57, 87)
    );
    let (o7l, o7h) = sum4_pairs!(
        (r[1], r[3], 9, -25),
        (r[5], r[7], 43, -57),
        (r[9], r[11], 70, -80),
        (r[13], r[15], 87, -90)
    );

    // Even part: 8-point butterfly on even rows (0,2,4,6,8,10,12,14)
    // Even-odd: EO[k] from rows 2,6,10,14
    macro_rules! sum2_pairs {
        (($ra1:expr, $rb1:expr, $ca1:expr, $cb1:expr),
         ($ra2:expr, $rb2:expr, $ca2:expr, $cb2:expr)) => {{
            let (l1, h1) = interleave_madd!($ra1, $rb1, $ca1, $cb1);
            let (l2, h2) = interleave_madd!($ra2, $rb2, $ca2, $cb2);
            (_mm256_add_epi32(l1, l2), _mm256_add_epi32(h1, h2))
        }};
    }

    let (eo0l, eo0h) = sum2_pairs!((r[2], r[6], 89, 75), (r[10], r[14], 50, 18));
    let (eo1l, eo1h) = sum2_pairs!((r[2], r[6], 75, -18), (r[10], r[14], -89, -50));
    let (eo2l, eo2h) = sum2_pairs!((r[2], r[6], 50, -89), (r[10], r[14], 18, 75));
    let (eo3l, eo3h) = sum2_pairs!((r[2], r[6], 18, -50), (r[10], r[14], 75, -89));

    // Even-even: from rows 0,4,8,12
    let (eee0l, eee0h) = interleave_madd!(r[0], r[8], 64, 64);
    let (eee1l, eee1h) = interleave_madd!(r[0], r[8], 64, -64);
    let (eeo0l, eeo0h) = interleave_madd!(r[4], r[12], 83, 36);
    let (eeo1l, eeo1h) = interleave_madd!(r[4], r[12], 36, -83);

    // EE[0..3]
    let ee0l = _mm256_add_epi32(eee0l, eeo0l);
    let ee0h = _mm256_add_epi32(eee0h, eeo0h);
    let ee1l = _mm256_add_epi32(eee1l, eeo1l);
    let ee1h = _mm256_add_epi32(eee1h, eeo1h);
    let ee2l = _mm256_sub_epi32(eee1l, eeo1l);
    let ee2h = _mm256_sub_epi32(eee1h, eeo1h);
    let ee3l = _mm256_sub_epi32(eee0l, eeo0l);
    let ee3h = _mm256_sub_epi32(eee0h, eeo0h);

    // E[0..7] = EE ± EO
    let e0l = _mm256_add_epi32(ee0l, eo0l);
    let e0h = _mm256_add_epi32(ee0h, eo0h);
    let e1l = _mm256_add_epi32(ee1l, eo1l);
    let e1h = _mm256_add_epi32(ee1h, eo1h);
    let e2l = _mm256_add_epi32(ee2l, eo2l);
    let e2h = _mm256_add_epi32(ee2h, eo2h);
    let e3l = _mm256_add_epi32(ee3l, eo3l);
    let e3h = _mm256_add_epi32(ee3h, eo3h);
    let e4l = _mm256_sub_epi32(ee3l, eo3l);
    let e4h = _mm256_sub_epi32(ee3h, eo3h);
    let e5l = _mm256_sub_epi32(ee2l, eo2l);
    let e5h = _mm256_sub_epi32(ee2h, eo2h);
    let e6l = _mm256_sub_epi32(ee1l, eo1l);
    let e6h = _mm256_sub_epi32(ee1h, eo1h);
    let e7l = _mm256_sub_epi32(ee0l, eo0l);
    let e7h = _mm256_sub_epi32(ee0h, eo0h);

    // Butterfly + round + shift + pack for all 16 output rows
    // Helper: compute (e ± o + add) >> shift, pack lo and hi halves back to __m256i of i16
    macro_rules! butterfly_pack {
        ($el:expr, $eh:expr, $ol:expr, $oh:expr, add) => {{
            let dl = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32($el, $ol), add), shift);
            let dh = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32($eh, $oh), add), shift);
            _mm256_packs_epi32(dl, dh)
        }};
        ($el:expr, $eh:expr, $ol:expr, $oh:expr, sub) => {{
            let dl = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32($el, $ol), add), shift);
            let dh = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32($eh, $oh), add), shift);
            _mm256_packs_epi32(dl, dh)
        }};
    }

    [
        butterfly_pack!(e0l, e0h, o0l, o0h, add),
        butterfly_pack!(e1l, e1h, o1l, o1h, add),
        butterfly_pack!(e2l, e2h, o2l, o2h, add),
        butterfly_pack!(e3l, e3h, o3l, o3h, add),
        butterfly_pack!(e4l, e4h, o4l, o4h, add),
        butterfly_pack!(e5l, e5h, o5l, o5h, add),
        butterfly_pack!(e6l, e6h, o6l, o6h, add),
        butterfly_pack!(e7l, e7h, o7l, o7h, add),
        butterfly_pack!(e7l, e7h, o7l, o7h, sub),
        butterfly_pack!(e6l, e6h, o6l, o6h, sub),
        butterfly_pack!(e5l, e5h, o5l, o5h, sub),
        butterfly_pack!(e4l, e4h, o4l, o4h, sub),
        butterfly_pack!(e3l, e3h, o3l, o3h, sub),
        butterfly_pack!(e2l, e2h, o2l, o2h, sub),
        butterfly_pack!(e1l, e1h, o1l, o1h, sub),
        butterfly_pack!(e0l, e0h, o0l, o0h, sub),
    ]
}

/// Transpose a 16x16 matrix of i16 stored in 16 __m256i registers.
/// Uses four 8x8 sub-transposes with corner swaps.
#[cfg(target_arch = "x86_64")]
#[rite]
fn transpose_16x16(token: X64V3Token, r: &[__m256i; 16]) -> [__m256i; 16] {
    // Extract 128-bit halves
    macro_rules! lo {
        ($v:expr) => {
            _mm256_castsi256_si128($v)
        };
    }
    macro_rules! hi {
        ($v:expr) => {
            _mm256_extracti128_si256::<1>($v)
        };
    }
    macro_rules! combine {
        ($l:expr, $h:expr) => {
            _mm256_set_m128i($h, $l)
        };
    }

    // Sub-transpose top-left (rows 0-7, cols 0-7) and top-right (rows 0-7, cols 8-15)
    let (tl0, tl1, tl2, tl3, tl4, tl5, tl6, tl7) = transpose_8x8(
        token,
        lo!(r[0]),
        lo!(r[1]),
        lo!(r[2]),
        lo!(r[3]),
        lo!(r[4]),
        lo!(r[5]),
        lo!(r[6]),
        lo!(r[7]),
    );
    let (tr0, tr1, tr2, tr3, tr4, tr5, tr6, tr7) = transpose_8x8(
        token,
        hi!(r[0]),
        hi!(r[1]),
        hi!(r[2]),
        hi!(r[3]),
        hi!(r[4]),
        hi!(r[5]),
        hi!(r[6]),
        hi!(r[7]),
    );
    // Sub-transpose bottom-left (rows 8-15, cols 0-7) and bottom-right (rows 8-15, cols 8-15)
    let (bl0, bl1, bl2, bl3, bl4, bl5, bl6, bl7) = transpose_8x8(
        token,
        lo!(r[8]),
        lo!(r[9]),
        lo!(r[10]),
        lo!(r[11]),
        lo!(r[12]),
        lo!(r[13]),
        lo!(r[14]),
        lo!(r[15]),
    );
    let (br0, br1, br2, br3, br4, br5, br6, br7) = transpose_8x8(
        token,
        hi!(r[8]),
        hi!(r[9]),
        hi!(r[10]),
        hi!(r[11]),
        hi!(r[12]),
        hi!(r[13]),
        hi!(r[14]),
        hi!(r[15]),
    );

    // Combine: output row k gets top-left col k (now row k of tl) as low half,
    // and bottom-left col k (now row k of bl) as high half, etc.
    // After transpose, tl holds cols 0-7 of rows 0-7, bl holds cols 0-7 of rows 8-15
    // Output row 0 = [tl0 (col 0 of rows 0-7), bl0 (col 0 of rows 8-15)]
    [
        combine!(tl0, bl0),
        combine!(tl1, bl1),
        combine!(tl2, bl2),
        combine!(tl3, bl3),
        combine!(tl4, bl4),
        combine!(tl5, bl5),
        combine!(tl6, bl6),
        combine!(tl7, bl7),
        combine!(tr0, br0),
        combine!(tr1, br1),
        combine!(tr2, br2),
        combine!(tr3, br3),
        combine!(tr4, br4),
        combine!(tr5, br5),
        combine!(tr6, br6),
        combine!(tr7, br7),
    ]
}

/// AVX2 16x16 IDCT entry point
#[arcane]
pub(crate) fn idct16_v3(
    _token: X64V3Token,
    coeffs: &[i16; 256],
    output: &mut [i16; 256],
    bit_depth: u8,
) {
    // Load 16 input rows
    let mut r = [_mm256_setzero_si256(); 16];
    for i in 0..16 {
        r[i] = _mm256_loadu_si256::<[i16; 16]>(coeffs[i * 16..(i + 1) * 16].try_into().unwrap());
    }

    // Pass 1: vertical, shift = 7
    let shift1 = _mm_cvtsi32_si128(7);
    let add1 = _mm256_set1_epi32(1 << 6);
    let d = idct16_1d_columns(_token, &r, shift1, add1);

    // Transpose
    let t = transpose_16x16(_token, &d);

    // Pass 2: horizontal, shift = 20 - bit_depth
    let shift2 = 20 - bit_depth as i32;
    let shift2_v = _mm_cvtsi32_si128(shift2);
    let add2 = _mm256_set1_epi32(1 << (shift2 - 1));
    let e = idct16_1d_columns(_token, &t, shift2_v, add2);

    // Transpose back
    let f = transpose_16x16(_token, &e);

    // Store 16 output rows
    for i in 0..16 {
        _mm256_storeu_si256::<[i16; 16]>(
            (&mut output[i * 16..(i + 1) * 16]).try_into().unwrap(),
            f[i],
        );
    }
}

/// Scalar fallback for 16x16 IDCT
pub(crate) fn idct16_scalar(
    _token: ScalarToken,
    coeffs: &[i16; 256],
    output: &mut [i16; 256],
    bit_depth: u8,
) {
    super::transform::idct16_inner(coeffs, output, bit_depth);
}

// =============================================================================
// 32x32 IDCT
// =============================================================================

/// 32-point 1D IDCT on 16 columns simultaneously.
/// Input: 32 rows as __m256i (each row = 16 i16 values, one per column).
/// Output: 32 transformed rows as __m256i (i16, clamped via saturating pack).
///
/// The structure has 5 levels of butterfly decomposition:
/// - Odd part: 16 outputs from 16 odd-indexed rows (1,3,...,31)
/// - Even part: 16-point butterfly on even rows (0,2,...,30)
///   - Even-Odd: 8 outputs from rows 2,6,10,14,18,22,26,30
///   - Even-Even: 8-point butterfly on rows 0,4,8,...,28
///     - Reuses the 8-point structure from idct8
#[cfg(target_arch = "x86_64")]
#[rite]
fn idct32_1d_columns(
    _token: X64V3Token,
    r: &[__m256i; 32],
    shift: __m128i,
    add: __m256i,
) -> [__m256i; 32] {
    // Helper: interleave two 256-bit rows and madd with coefficient pair
    macro_rules! interleave_madd {
        ($ra:expr, $rb:expr, $ca:expr, $cb:expr) => {{
            let lo = _mm256_unpacklo_epi16($ra, $rb);
            let hi = _mm256_unpackhi_epi16($ra, $rb);
            let coeff = _mm256_set1_epi32(pack($ca, $cb));
            (_mm256_madd_epi16(lo, coeff), _mm256_madd_epi16(hi, coeff))
        }};
    }

    // Helper: accumulate 4 pairs of madd results into (lo, hi) sums
    macro_rules! sum4_pairs {
        (($ra1:expr, $rb1:expr, $ca1:expr, $cb1:expr),
         ($ra2:expr, $rb2:expr, $ca2:expr, $cb2:expr),
         ($ra3:expr, $rb3:expr, $ca3:expr, $cb3:expr),
         ($ra4:expr, $rb4:expr, $ca4:expr, $cb4:expr)) => {{
            let (l1, h1) = interleave_madd!($ra1, $rb1, $ca1, $cb1);
            let (l2, h2) = interleave_madd!($ra2, $rb2, $ca2, $cb2);
            let (l3, h3) = interleave_madd!($ra3, $rb3, $ca3, $cb3);
            let (l4, h4) = interleave_madd!($ra4, $rb4, $ca4, $cb4);
            (
                _mm256_add_epi32(_mm256_add_epi32(l1, l2), _mm256_add_epi32(l3, l4)),
                _mm256_add_epi32(_mm256_add_epi32(h1, h2), _mm256_add_epi32(h3, h4)),
            )
        }};
    }

    // Helper: accumulate 8 pairs into (lo, hi) sums — for the 32-point odd part
    macro_rules! sum8_pairs {
        (($ra1:expr, $rb1:expr, $ca1:expr, $cb1:expr),
         ($ra2:expr, $rb2:expr, $ca2:expr, $cb2:expr),
         ($ra3:expr, $rb3:expr, $ca3:expr, $cb3:expr),
         ($ra4:expr, $rb4:expr, $ca4:expr, $cb4:expr),
         ($ra5:expr, $rb5:expr, $ca5:expr, $cb5:expr),
         ($ra6:expr, $rb6:expr, $ca6:expr, $cb6:expr),
         ($ra7:expr, $rb7:expr, $ca7:expr, $cb7:expr),
         ($ra8:expr, $rb8:expr, $ca8:expr, $cb8:expr)) => {{
            let (l1, h1) = interleave_madd!($ra1, $rb1, $ca1, $cb1);
            let (l2, h2) = interleave_madd!($ra2, $rb2, $ca2, $cb2);
            let (l3, h3) = interleave_madd!($ra3, $rb3, $ca3, $cb3);
            let (l4, h4) = interleave_madd!($ra4, $rb4, $ca4, $cb4);
            let (l5, h5) = interleave_madd!($ra5, $rb5, $ca5, $cb5);
            let (l6, h6) = interleave_madd!($ra6, $rb6, $ca6, $cb6);
            let (l7, h7) = interleave_madd!($ra7, $rb7, $ca7, $cb7);
            let (l8, h8) = interleave_madd!($ra8, $rb8, $ca8, $cb8);
            let la = _mm256_add_epi32(_mm256_add_epi32(l1, l2), _mm256_add_epi32(l3, l4));
            let lb = _mm256_add_epi32(_mm256_add_epi32(l5, l6), _mm256_add_epi32(l7, l8));
            let ha = _mm256_add_epi32(_mm256_add_epi32(h1, h2), _mm256_add_epi32(h3, h4));
            let hb = _mm256_add_epi32(_mm256_add_epi32(h5, h6), _mm256_add_epi32(h7, h8));
            (_mm256_add_epi32(la, lb), _mm256_add_epi32(ha, hb))
        }};
    }

    // =========================================================================
    // Odd part: 16 outputs O[0..15] from odd rows (1,3,5,...,31)
    // H.265 Table 8-5 coefficients
    // =========================================================================
    let (o0l, o0h) = sum8_pairs!(
        (r[1], r[3], 90, 90),
        (r[5], r[7], 88, 85),
        (r[9], r[11], 82, 78),
        (r[13], r[15], 73, 67),
        (r[17], r[19], 61, 54),
        (r[21], r[23], 46, 38),
        (r[25], r[27], 31, 22),
        (r[29], r[31], 13, 4)
    );
    let (o1l, o1h) = sum8_pairs!(
        (r[1], r[3], 90, 82),
        (r[5], r[7], 67, 46),
        (r[9], r[11], 22, -4),
        (r[13], r[15], -31, -54),
        (r[17], r[19], -73, -85),
        (r[21], r[23], -90, -88),
        (r[25], r[27], -78, -61),
        (r[29], r[31], -38, -13)
    );
    let (o2l, o2h) = sum8_pairs!(
        (r[1], r[3], 88, 67),
        (r[5], r[7], 31, -13),
        (r[9], r[11], -54, -82),
        (r[13], r[15], -90, -78),
        (r[17], r[19], -46, -4),
        (r[21], r[23], 38, 73),
        (r[25], r[27], 90, 85),
        (r[29], r[31], 61, 22)
    );
    let (o3l, o3h) = sum8_pairs!(
        (r[1], r[3], 85, 46),
        (r[5], r[7], -13, -67),
        (r[9], r[11], -90, -73),
        (r[13], r[15], -22, 38),
        (r[17], r[19], 82, 88),
        (r[21], r[23], 54, -4),
        (r[25], r[27], -61, -90),
        (r[29], r[31], -78, -31)
    );
    let (o4l, o4h) = sum8_pairs!(
        (r[1], r[3], 82, 22),
        (r[5], r[7], -54, -90),
        (r[9], r[11], -61, 13),
        (r[13], r[15], 78, 85),
        (r[17], r[19], 31, -46),
        (r[21], r[23], -90, -67),
        (r[25], r[27], 4, 73),
        (r[29], r[31], 88, 38)
    );
    let (o5l, o5h) = sum8_pairs!(
        (r[1], r[3], 78, -4),
        (r[5], r[7], -82, -73),
        (r[9], r[11], 13, 85),
        (r[13], r[15], 67, -22),
        (r[17], r[19], -88, -61),
        (r[21], r[23], 31, 90),
        (r[25], r[27], 54, -38),
        (r[29], r[31], -90, -46)
    );
    let (o6l, o6h) = sum8_pairs!(
        (r[1], r[3], 73, -31),
        (r[5], r[7], -90, -22),
        (r[9], r[11], 78, 67),
        (r[13], r[15], -38, -90),
        (r[17], r[19], -13, 82),
        (r[21], r[23], 61, -46),
        (r[25], r[27], -88, -4),
        (r[29], r[31], 85, 54)
    );
    let (o7l, o7h) = sum8_pairs!(
        (r[1], r[3], 67, -54),
        (r[5], r[7], -78, 38),
        (r[9], r[11], 85, -22),
        (r[13], r[15], -90, 4),
        (r[17], r[19], 90, 13),
        (r[21], r[23], -88, -31),
        (r[25], r[27], 82, 46),
        (r[29], r[31], -73, -61)
    );
    let (o8l, o8h) = sum8_pairs!(
        (r[1], r[3], 61, -73),
        (r[5], r[7], -46, 82),
        (r[9], r[11], 31, -88),
        (r[13], r[15], -13, 90),
        (r[17], r[19], -4, -90),
        (r[21], r[23], 22, 85),
        (r[25], r[27], -38, -78),
        (r[29], r[31], 54, 67)
    );
    let (o9l, o9h) = sum8_pairs!(
        (r[1], r[3], 54, -85),
        (r[5], r[7], -4, 88),
        (r[9], r[11], -46, -61),
        (r[13], r[15], 82, 13),
        (r[17], r[19], -90, 38),
        (r[21], r[23], 67, -78),
        (r[25], r[27], -22, 90),
        (r[29], r[31], -31, -73)
    );
    let (o10l, o10h) = sum8_pairs!(
        (r[1], r[3], 46, -90),
        (r[5], r[7], 38, 54),
        (r[9], r[11], -90, 31),
        (r[13], r[15], 61, -88),
        (r[17], r[19], 22, 67),
        (r[21], r[23], -85, 13),
        (r[25], r[27], 73, -82),
        (r[29], r[31], 4, 78)
    );
    let (o11l, o11h) = sum8_pairs!(
        (r[1], r[3], 38, -88),
        (r[5], r[7], 73, -4),
        (r[9], r[11], -67, 90),
        (r[13], r[15], -46, -31),
        (r[17], r[19], 85, -78),
        (r[21], r[23], 13, 61),
        (r[25], r[27], -90, 54),
        (r[29], r[31], 22, -82)
    );
    let (o12l, o12h) = sum8_pairs!(
        (r[1], r[3], 31, -78),
        (r[5], r[7], 90, -61),
        (r[9], r[11], 4, 54),
        (r[13], r[15], -88, 82),
        (r[17], r[19], -38, -22),
        (r[21], r[23], 73, -90),
        (r[25], r[27], 67, -13),
        (r[29], r[31], -46, 85)
    );
    let (o13l, o13h) = sum8_pairs!(
        (r[1], r[3], 22, -61),
        (r[5], r[7], 85, -90),
        (r[9], r[11], 73, -38),
        (r[13], r[15], -4, 46),
        (r[17], r[19], -78, 90),
        (r[21], r[23], -82, 54),
        (r[25], r[27], -13, -31),
        (r[29], r[31], 67, -88)
    );
    let (o14l, o14h) = sum8_pairs!(
        (r[1], r[3], 13, -38),
        (r[5], r[7], 61, -78),
        (r[9], r[11], 88, -90),
        (r[13], r[15], 85, -73),
        (r[17], r[19], 54, -31),
        (r[21], r[23], 4, 22),
        (r[25], r[27], -46, 67),
        (r[29], r[31], -82, 90)
    );
    let (o15l, o15h) = sum8_pairs!(
        (r[1], r[3], 4, -13),
        (r[5], r[7], 22, -31),
        (r[9], r[11], 38, -46),
        (r[13], r[15], 54, -61),
        (r[17], r[19], 67, -73),
        (r[21], r[23], 78, -82),
        (r[25], r[27], 85, -88),
        (r[29], r[31], 90, -90)
    );

    // =========================================================================
    // Even part: 16-point butterfly on even rows (0,2,4,...,30)
    // This reuses the 16-point structure with indices mapped: row k → r[2k]
    // =========================================================================

    // Even-Odd (EO): 8 outputs from rows 2,6,10,14,18,22,26,30
    // Same 16-point odd coefficients as idct16
    macro_rules! sum2_pairs {
        (($ra1:expr, $rb1:expr, $ca1:expr, $cb1:expr),
         ($ra2:expr, $rb2:expr, $ca2:expr, $cb2:expr)) => {{
            let (l1, h1) = interleave_madd!($ra1, $rb1, $ca1, $cb1);
            let (l2, h2) = interleave_madd!($ra2, $rb2, $ca2, $cb2);
            (_mm256_add_epi32(l1, l2), _mm256_add_epi32(h1, h2))
        }};
    }

    let (eo0l, eo0h) = sum4_pairs!(
        (r[2], r[6], 90, 87),
        (r[10], r[14], 80, 70),
        (r[18], r[22], 57, 43),
        (r[26], r[30], 25, 9)
    );
    let (eo1l, eo1h) = sum4_pairs!(
        (r[2], r[6], 87, 57),
        (r[10], r[14], 9, -43),
        (r[18], r[22], -80, -90),
        (r[26], r[30], -70, -25)
    );
    let (eo2l, eo2h) = sum4_pairs!(
        (r[2], r[6], 80, 9),
        (r[10], r[14], -70, -87),
        (r[18], r[22], -25, 57),
        (r[26], r[30], 90, 43)
    );
    let (eo3l, eo3h) = sum4_pairs!(
        (r[2], r[6], 70, -43),
        (r[10], r[14], -87, 9),
        (r[18], r[22], 90, 25),
        (r[26], r[30], -80, -57)
    );
    let (eo4l, eo4h) = sum4_pairs!(
        (r[2], r[6], 57, -80),
        (r[10], r[14], -25, 90),
        (r[18], r[22], -9, -87),
        (r[26], r[30], 43, 70)
    );
    let (eo5l, eo5h) = sum4_pairs!(
        (r[2], r[6], 43, -90),
        (r[10], r[14], 57, 25),
        (r[18], r[22], -87, 70),
        (r[26], r[30], 9, -80)
    );
    let (eo6l, eo6h) = sum4_pairs!(
        (r[2], r[6], 25, -70),
        (r[10], r[14], 90, -80),
        (r[18], r[22], 43, 9),
        (r[26], r[30], -57, 87)
    );
    let (eo7l, eo7h) = sum4_pairs!(
        (r[2], r[6], 9, -25),
        (r[10], r[14], 43, -57),
        (r[18], r[22], 70, -80),
        (r[26], r[30], 87, -90)
    );

    // Even-Even-Odd (EEO): 4 outputs from rows 4,12,20,28
    let (eeo0l, eeo0h) = sum2_pairs!((r[4], r[12], 89, 75), (r[20], r[28], 50, 18));
    let (eeo1l, eeo1h) = sum2_pairs!((r[4], r[12], 75, -18), (r[20], r[28], -89, -50));
    let (eeo2l, eeo2h) = sum2_pairs!((r[4], r[12], 50, -89), (r[20], r[28], 18, 75));
    let (eeo3l, eeo3h) = sum2_pairs!((r[4], r[12], 18, -50), (r[20], r[28], 75, -89));

    // Even-Even-Even (EEE): from rows 0,8,16,24
    let (eeee0l, eeee0h) = interleave_madd!(r[0], r[16], 64, 64);
    let (eeee1l, eeee1h) = interleave_madd!(r[0], r[16], 64, -64);
    let (eeeo0l, eeeo0h) = interleave_madd!(r[8], r[24], 83, 36);
    let (eeeo1l, eeeo1h) = interleave_madd!(r[8], r[24], 36, -83);

    // EEE[0..3]
    let eee0l = _mm256_add_epi32(eeee0l, eeeo0l);
    let eee0h = _mm256_add_epi32(eeee0h, eeeo0h);
    let eee1l = _mm256_add_epi32(eeee1l, eeeo1l);
    let eee1h = _mm256_add_epi32(eeee1h, eeeo1h);
    let eee2l = _mm256_sub_epi32(eeee1l, eeeo1l);
    let eee2h = _mm256_sub_epi32(eeee1h, eeeo1h);
    let eee3l = _mm256_sub_epi32(eeee0l, eeeo0l);
    let eee3h = _mm256_sub_epi32(eeee0h, eeeo0h);

    // EE[0..7] = EEE ± EEO
    let ee0l = _mm256_add_epi32(eee0l, eeo0l);
    let ee0h = _mm256_add_epi32(eee0h, eeo0h);
    let ee1l = _mm256_add_epi32(eee1l, eeo1l);
    let ee1h = _mm256_add_epi32(eee1h, eeo1h);
    let ee2l = _mm256_add_epi32(eee2l, eeo2l);
    let ee2h = _mm256_add_epi32(eee2h, eeo2h);
    let ee3l = _mm256_add_epi32(eee3l, eeo3l);
    let ee3h = _mm256_add_epi32(eee3h, eeo3h);
    let ee4l = _mm256_sub_epi32(eee3l, eeo3l);
    let ee4h = _mm256_sub_epi32(eee3h, eeo3h);
    let ee5l = _mm256_sub_epi32(eee2l, eeo2l);
    let ee5h = _mm256_sub_epi32(eee2h, eeo2h);
    let ee6l = _mm256_sub_epi32(eee1l, eeo1l);
    let ee6h = _mm256_sub_epi32(eee1h, eeo1h);
    let ee7l = _mm256_sub_epi32(eee0l, eeo0l);
    let ee7h = _mm256_sub_epi32(eee0h, eeo0h);

    // E[0..15] = EE ± EO
    let e0l = _mm256_add_epi32(ee0l, eo0l);
    let e0h = _mm256_add_epi32(ee0h, eo0h);
    let e1l = _mm256_add_epi32(ee1l, eo1l);
    let e1h = _mm256_add_epi32(ee1h, eo1h);
    let e2l = _mm256_add_epi32(ee2l, eo2l);
    let e2h = _mm256_add_epi32(ee2h, eo2h);
    let e3l = _mm256_add_epi32(ee3l, eo3l);
    let e3h = _mm256_add_epi32(ee3h, eo3h);
    let e4l = _mm256_add_epi32(ee4l, eo4l);
    let e4h = _mm256_add_epi32(ee4h, eo4h);
    let e5l = _mm256_add_epi32(ee5l, eo5l);
    let e5h = _mm256_add_epi32(ee5h, eo5h);
    let e6l = _mm256_add_epi32(ee6l, eo6l);
    let e6h = _mm256_add_epi32(ee6h, eo6h);
    let e7l = _mm256_add_epi32(ee7l, eo7l);
    let e7h = _mm256_add_epi32(ee7h, eo7h);
    let e8l = _mm256_sub_epi32(ee7l, eo7l);
    let e8h = _mm256_sub_epi32(ee7h, eo7h);
    let e9l = _mm256_sub_epi32(ee6l, eo6l);
    let e9h = _mm256_sub_epi32(ee6h, eo6h);
    let e10l = _mm256_sub_epi32(ee5l, eo5l);
    let e10h = _mm256_sub_epi32(ee5h, eo5h);
    let e11l = _mm256_sub_epi32(ee4l, eo4l);
    let e11h = _mm256_sub_epi32(ee4h, eo4h);
    let e12l = _mm256_sub_epi32(ee3l, eo3l);
    let e12h = _mm256_sub_epi32(ee3h, eo3h);
    let e13l = _mm256_sub_epi32(ee2l, eo2l);
    let e13h = _mm256_sub_epi32(ee2h, eo2h);
    let e14l = _mm256_sub_epi32(ee1l, eo1l);
    let e14h = _mm256_sub_epi32(ee1h, eo1h);
    let e15l = _mm256_sub_epi32(ee0l, eo0l);
    let e15h = _mm256_sub_epi32(ee0h, eo0h);

    // =========================================================================
    // Butterfly + round + shift + pack for all 32 output rows
    // =========================================================================
    macro_rules! butterfly_pack {
        ($el:expr, $eh:expr, $ol:expr, $oh:expr, add) => {{
            let dl = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32($el, $ol), add), shift);
            let dh = _mm256_sra_epi32(_mm256_add_epi32(_mm256_add_epi32($eh, $oh), add), shift);
            _mm256_packs_epi32(dl, dh)
        }};
        ($el:expr, $eh:expr, $ol:expr, $oh:expr, sub) => {{
            let dl = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32($el, $ol), add), shift);
            let dh = _mm256_sra_epi32(_mm256_add_epi32(_mm256_sub_epi32($eh, $oh), add), shift);
            _mm256_packs_epi32(dl, dh)
        }};
    }

    [
        butterfly_pack!(e0l, e0h, o0l, o0h, add),
        butterfly_pack!(e1l, e1h, o1l, o1h, add),
        butterfly_pack!(e2l, e2h, o2l, o2h, add),
        butterfly_pack!(e3l, e3h, o3l, o3h, add),
        butterfly_pack!(e4l, e4h, o4l, o4h, add),
        butterfly_pack!(e5l, e5h, o5l, o5h, add),
        butterfly_pack!(e6l, e6h, o6l, o6h, add),
        butterfly_pack!(e7l, e7h, o7l, o7h, add),
        butterfly_pack!(e8l, e8h, o8l, o8h, add),
        butterfly_pack!(e9l, e9h, o9l, o9h, add),
        butterfly_pack!(e10l, e10h, o10l, o10h, add),
        butterfly_pack!(e11l, e11h, o11l, o11h, add),
        butterfly_pack!(e12l, e12h, o12l, o12h, add),
        butterfly_pack!(e13l, e13h, o13l, o13h, add),
        butterfly_pack!(e14l, e14h, o14l, o14h, add),
        butterfly_pack!(e15l, e15h, o15l, o15h, add),
        butterfly_pack!(e15l, e15h, o15l, o15h, sub),
        butterfly_pack!(e14l, e14h, o14l, o14h, sub),
        butterfly_pack!(e13l, e13h, o13l, o13h, sub),
        butterfly_pack!(e12l, e12h, o12l, o12h, sub),
        butterfly_pack!(e11l, e11h, o11l, o11h, sub),
        butterfly_pack!(e10l, e10h, o10l, o10h, sub),
        butterfly_pack!(e9l, e9h, o9l, o9h, sub),
        butterfly_pack!(e8l, e8h, o8l, o8h, sub),
        butterfly_pack!(e7l, e7h, o7l, o7h, sub),
        butterfly_pack!(e6l, e6h, o6l, o6h, sub),
        butterfly_pack!(e5l, e5h, o5l, o5h, sub),
        butterfly_pack!(e4l, e4h, o4l, o4h, sub),
        butterfly_pack!(e3l, e3h, o3l, o3h, sub),
        butterfly_pack!(e2l, e2h, o2l, o2h, sub),
        butterfly_pack!(e1l, e1h, o1l, o1h, sub),
        butterfly_pack!(e0l, e0h, o0l, o0h, sub),
    ]
}

/// Transpose a 32x32 matrix of i16 stored as 32 pairs of __m256i (lo=cols 0-15, hi=cols 16-31).
/// Uses four 16x16 sub-transposes with corner swaps.
#[cfg(target_arch = "x86_64")]
#[rite]
fn transpose_32x32(
    token: X64V3Token,
    lo: &[__m256i; 32],
    hi: &[__m256i; 32],
) -> ([__m256i; 32], [__m256i; 32]) {
    // Sub-matrices:
    // TL = lo[0..16]  (rows 0-15, cols 0-15)
    // TR = hi[0..16]  (rows 0-15, cols 16-31)
    // BL = lo[16..32] (rows 16-31, cols 0-15)
    // BR = hi[16..32] (rows 16-31, cols 16-31)

    let tl_arr: [__m256i; 16] = lo[0..16].try_into().unwrap();
    let tr_arr: [__m256i; 16] = hi[0..16].try_into().unwrap();
    let bl_arr: [__m256i; 16] = lo[16..32].try_into().unwrap();
    let br_arr: [__m256i; 16] = hi[16..32].try_into().unwrap();

    let tl_t = transpose_16x16(token, &tl_arr);
    let tr_t = transpose_16x16(token, &tr_arr);
    let bl_t = transpose_16x16(token, &bl_arr);
    let br_t = transpose_16x16(token, &br_arr);

    // After transpose:
    // out_lo[i] = tl_t[i] for i < 16, tr_t[i-16] for i >= 16
    // out_hi[i] = bl_t[i] for i < 16, br_t[i-16] for i >= 16
    let mut out_lo = [_mm256_setzero_si256(); 32];
    let mut out_hi = [_mm256_setzero_si256(); 32];
    out_lo[..16].copy_from_slice(&tl_t);
    out_lo[16..].copy_from_slice(&tr_t);
    out_hi[..16].copy_from_slice(&bl_t);
    out_hi[16..].copy_from_slice(&br_t);
    (out_lo, out_hi)
}

/// AVX2 32x32 IDCT entry point.
/// Processes in two column groups (0-15 and 16-31), each fitting in __m256i.
#[arcane]
pub(crate) fn idct32_v3(
    _token: X64V3Token,
    coeffs: &[i16; 1024],
    output: &mut [i16; 1024],
    bit_depth: u8,
) {
    // Load 32 rows, each as two __m256i (cols 0-15 and cols 16-31)
    let mut lo = [_mm256_setzero_si256(); 32];
    let mut hi = [_mm256_setzero_si256(); 32];
    for i in 0..32 {
        let base = i * 32;
        lo[i] = _mm256_loadu_si256::<[i16; 16]>(coeffs[base..base + 16].try_into().unwrap());
        hi[i] = _mm256_loadu_si256::<[i16; 16]>(coeffs[base + 16..base + 32].try_into().unwrap());
    }

    // Pass 1: vertical (column transform), shift = 7
    let shift1 = _mm_cvtsi32_si128(7);
    let add1 = _mm256_set1_epi32(1 << 6);
    let d_lo = idct32_1d_columns(_token, &lo, shift1, add1);
    let d_hi = idct32_1d_columns(_token, &hi, shift1, add1);

    // Transpose 32x32
    let (t_lo, t_hi) = transpose_32x32(_token, &d_lo, &d_hi);

    // Pass 2: horizontal (row transform), shift = 20 - bit_depth
    let shift2 = 20 - bit_depth as i32;
    let shift2_v = _mm_cvtsi32_si128(shift2);
    let add2 = _mm256_set1_epi32(1 << (shift2 - 1));
    let e_lo = idct32_1d_columns(_token, &t_lo, shift2_v, add2);
    let e_hi = idct32_1d_columns(_token, &t_hi, shift2_v, add2);

    // Transpose back
    let (f_lo, f_hi) = transpose_32x32(_token, &e_lo, &e_hi);

    // Store 32 output rows
    for i in 0..32 {
        let base = i * 32;
        _mm256_storeu_si256::<[i16; 16]>(
            (&mut output[base..base + 16]).try_into().unwrap(),
            f_lo[i],
        );
        _mm256_storeu_si256::<[i16; 16]>(
            (&mut output[base + 16..base + 32]).try_into().unwrap(),
            f_hi[i],
        );
    }
}

/// Scalar fallback for 32x32 IDCT
pub(crate) fn idct32_scalar(
    _token: ScalarToken,
    coeffs: &[i16; 1024],
    output: &mut [i16; 1024],
    bit_depth: u8,
) {
    super::transform::idct32_inner(coeffs, output, bit_depth);
}

// =============================================================================
// SSE4.1 IDST 4x4: DST-VII inverse for intra 4x4 luma
// =============================================================================

/// SSE4.1 inverse DST 4x4: processes all 4 columns in parallel using 128-bit SIMD.
///
/// Two-pass approach:
/// - Pass 1 (vertical): load 4 rows as i32, multiply by DST4 coefficients, shift/clamp
/// - Transpose 4x4 i16 matrix (4 unpack instructions)
/// - Pass 2 (horizontal): same multiply pattern, pack and store
///
/// Key advantage over scalar: `_mm_packs_epi32` provides the spec-required i16 saturation
/// (H.265 Eq. 8-314) without any conditional branches. The scalar version generates 32
/// conditional jumps for 16 clamp operations.
#[cfg(target_arch = "x86_64")]
#[arcane]
pub(crate) fn idst4_v3(
    _token: X64V3Token,
    coeffs: &[i16; 16],
    output: &mut [i16; 16],
    bit_depth: u8,
) {
    // Load all 16 i16 coefficients as 4 rows of 4 i32 values
    let load01 = _mm_loadu_si128::<[i16; 8]>(coeffs[0..8].try_into().unwrap());
    let load23 = _mm_loadu_si128::<[i16; 8]>(coeffs[8..16].try_into().unwrap());
    let row0 = _mm_cvtepi16_epi32(load01);
    let row1 = _mm_cvtepi16_epi32(_mm_unpackhi_epi64(load01, load01));
    let row2 = _mm_cvtepi16_epi32(load23);
    let row3 = _mm_cvtepi16_epi32(_mm_unpackhi_epi64(load23, load23));

    // === Pass 1 (vertical): DST4^T × COEFFS, 4 columns in parallel ===
    let add1 = _mm_set1_epi32(64); // 1 << (7 - 1)

    // DST4 matrix applied column-wise:
    //   j=0: 29*r0 + 74*r1 + 84*r2 + 55*r3
    //   j=1: 55*r0 + 74*r1 - 29*r2 - 84*r3
    //   j=2: 74*(r0 - r2 + r3)  [coeff for r1 is 0]
    //   j=3: 84*r0 - 74*r1 + 55*r2 - 29*r3
    let t0 = _mm_srai_epi32::<7>(_mm_add_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_mullo_epi32(row0, _mm_set1_epi32(29)),
                _mm_mullo_epi32(row1, _mm_set1_epi32(74)),
            ),
            _mm_add_epi32(
                _mm_mullo_epi32(row2, _mm_set1_epi32(84)),
                _mm_mullo_epi32(row3, _mm_set1_epi32(55)),
            ),
        ),
        add1,
    ));

    let t1 = _mm_srai_epi32::<7>(_mm_add_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_mullo_epi32(row0, _mm_set1_epi32(55)),
                _mm_mullo_epi32(row1, _mm_set1_epi32(74)),
            ),
            _mm_add_epi32(
                _mm_mullo_epi32(row2, _mm_set1_epi32(-29)),
                _mm_mullo_epi32(row3, _mm_set1_epi32(-84)),
            ),
        ),
        add1,
    ));

    // j=2: coefficient for r1 is 0, factor out 74
    let t2 = _mm_srai_epi32::<7>(_mm_add_epi32(
        _mm_mullo_epi32(
            _mm_add_epi32(_mm_sub_epi32(row0, row2), row3),
            _mm_set1_epi32(74),
        ),
        add1,
    ));

    let t3 = _mm_srai_epi32::<7>(_mm_add_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_mullo_epi32(row0, _mm_set1_epi32(84)),
                _mm_mullo_epi32(row1, _mm_set1_epi32(-74)),
            ),
            _mm_add_epi32(
                _mm_mullo_epi32(row2, _mm_set1_epi32(55)),
                _mm_mullo_epi32(row3, _mm_set1_epi32(-29)),
            ),
        ),
        add1,
    ));

    // Clamp to i16 range (H.265 Eq. 8-314): packs_epi32 saturates i32 → i16
    let packed01 = _mm_packs_epi32(t0, t1);
    let packed23 = _mm_packs_epi32(t2, t3);

    // Transpose 4x4 i16 matrix for pass 2
    // Input: packed01 = [r0c0..r0c3, r1c0..r1c3], packed23 = [r2c0..r2c3, r3c0..r3c3]
    // Output: transposed so columns become rows
    let a = _mm_unpacklo_epi16(packed01, packed23);
    let b = _mm_unpackhi_epi16(packed01, packed23);
    let tp_lo = _mm_unpacklo_epi16(a, b); // [col0_as_row, col1_as_row]
    let tp_hi = _mm_unpackhi_epi16(a, b); // [col2_as_row, col3_as_row]

    // === Pass 2 (horizontal): DST4^T × TMP^T, then transpose output ===
    let r0 = _mm_cvtepi16_epi32(tp_lo);
    let r1 = _mm_cvtepi16_epi32(_mm_unpackhi_epi64(tp_lo, tp_lo));
    let r2 = _mm_cvtepi16_epi32(tp_hi);
    let r3 = _mm_cvtepi16_epi32(_mm_unpackhi_epi64(tp_hi, tp_hi));

    let shift2 = 20 - bit_depth as i32;
    let add2 = _mm_set1_epi32(1i32 << (shift2 - 1));
    let shift2_v = _mm_cvtsi32_si128(shift2);

    let o0 = _mm_sra_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_add_epi32(
                    _mm_mullo_epi32(r0, _mm_set1_epi32(29)),
                    _mm_mullo_epi32(r1, _mm_set1_epi32(74)),
                ),
                _mm_add_epi32(
                    _mm_mullo_epi32(r2, _mm_set1_epi32(84)),
                    _mm_mullo_epi32(r3, _mm_set1_epi32(55)),
                ),
            ),
            add2,
        ),
        shift2_v,
    );

    let o1 = _mm_sra_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_add_epi32(
                    _mm_mullo_epi32(r0, _mm_set1_epi32(55)),
                    _mm_mullo_epi32(r1, _mm_set1_epi32(74)),
                ),
                _mm_add_epi32(
                    _mm_mullo_epi32(r2, _mm_set1_epi32(-29)),
                    _mm_mullo_epi32(r3, _mm_set1_epi32(-84)),
                ),
            ),
            add2,
        ),
        shift2_v,
    );

    let o2 = _mm_sra_epi32(
        _mm_add_epi32(
            _mm_mullo_epi32(_mm_add_epi32(_mm_sub_epi32(r0, r2), r3), _mm_set1_epi32(74)),
            add2,
        ),
        shift2_v,
    );

    let o3 = _mm_sra_epi32(
        _mm_add_epi32(
            _mm_add_epi32(
                _mm_add_epi32(
                    _mm_mullo_epi32(r0, _mm_set1_epi32(84)),
                    _mm_mullo_epi32(r1, _mm_set1_epi32(-74)),
                ),
                _mm_add_epi32(
                    _mm_mullo_epi32(r2, _mm_set1_epi32(55)),
                    _mm_mullo_epi32(r3, _mm_set1_epi32(-29)),
                ),
            ),
            add2,
        ),
        shift2_v,
    );

    // Pack to i16 and transpose back to row-major
    let out01 = _mm_packs_epi32(o0, o1);
    let out23 = _mm_packs_epi32(o2, o3);

    let a = _mm_unpacklo_epi16(out01, out23);
    let b = _mm_unpackhi_epi16(out01, out23);
    let final_lo = _mm_unpacklo_epi16(a, b);
    let final_hi = _mm_unpackhi_epi16(a, b);

    _mm_storeu_si128::<[i16; 8]>((&mut output[0..8]).try_into().unwrap(), final_lo);
    _mm_storeu_si128::<[i16; 8]>((&mut output[8..16]).try_into().unwrap(), final_hi);
}

/// Scalar fallback for IDST 4x4
pub(crate) fn idst4_scalar(
    _token: ScalarToken,
    coeffs: &[i16; 16],
    output: &mut [i16; 16],
    bit_depth: u8,
) {
    super::transform::idst4_inner(coeffs, output, bit_depth);
}

// =============================================================================
// SIMD residual add: u16 prediction + i16 residual → clamped u16
// =============================================================================

/// Add i16 residual block to u16 prediction block with clamping to [0, max_val].
/// Processes full block (multiple rows) with single arcane entry point.
/// Plane rows are stride-separated; residual rows are contiguous (size*size).
#[cfg(target_arch = "x86_64")]
#[allow(clippy::too_many_arguments)]
#[arcane]
pub(crate) fn add_residual_block_v3(
    _token: X64V3Token,
    plane: &mut [u16],
    stride: usize,
    x0: usize,
    y0: usize,
    residual: &[i16],
    size: usize,
    max_val: i32,
) {
    let zero = _mm256_setzero_si256();
    let max_v = _mm256_set1_epi16(max_val as i16);

    for py in 0..size {
        let row_start = (y0 + py) * stride + x0;
        let row = &mut plane[row_start..row_start + size];
        let res_row = &residual[py * size..(py + 1) * size];

        let chunks = size / 16;
        for c in 0..chunks {
            let offset = c * 16;
            let pred =
                _mm256_loadu_si256::<[u16; 16]>(row[offset..offset + 16].try_into().unwrap());
            let res =
                _mm256_loadu_si256::<[i16; 16]>(res_row[offset..offset + 16].try_into().unwrap());
            let sum = _mm256_add_epi16(pred, res);
            let clamped = _mm256_min_epi16(_mm256_max_epi16(sum, zero), max_v);
            _mm256_storeu_si256::<[u16; 16]>(
                (&mut row[offset..offset + 16]).try_into().unwrap(),
                clamped,
            );
        }
        // Scalar remainder within same arcane context
        for i in (chunks * 16)..size {
            let pred = row[i] as i32;
            let r = res_row[i] as i32;
            row[i] = (pred + r).clamp(0, max_val) as u16;
        }
    }
}

/// Scalar fallback for residual block add
#[allow(clippy::too_many_arguments)]
pub(crate) fn add_residual_block_scalar(
    _token: ScalarToken,
    plane: &mut [u16],
    stride: usize,
    x0: usize,
    y0: usize,
    residual: &[i16],
    size: usize,
    max_val: i32,
) {
    for py in 0..size {
        let row_start = (y0 + py) * stride + x0;
        let row = &mut plane[row_start..row_start + size];
        let res_row = &residual[py * size..(py + 1) * size];
        for (out, &r) in row.iter_mut().zip(res_row.iter()) {
            let pred = *out as i32;
            *out = (pred + r as i32).clamp(0, max_val) as u16;
        }
    }
}

// =============================================================================
// SIMD dequantize: i16 × const → i16 with shift and clamp
// =============================================================================

/// Dequantize i16 coefficients: coeff * scale << qp_shift, then >> bd_shift with rounding.
/// Processes 16 coefficients per AVX2 iteration.
#[cfg(target_arch = "x86_64")]
#[arcane]
pub(crate) fn dequantize_v3(
    _token: X64V3Token,
    coeffs: &mut [i16],
    combined_scale: i32,
    shift: i32,
    add: i32,
) {
    // combined_scale = level_scale * (1 << qp_per) — fits in i16 for most QPs
    // Strategy: widen to i32, multiply, shift, pack back to i16
    let scale_v = _mm256_set1_epi32(combined_scale);
    let add_v = _mm256_set1_epi32(add);
    let shift_v = _mm_cvtsi32_si128(shift);

    let chunks = coeffs.len() / 16;
    for c in 0..chunks {
        let offset = c * 16;
        let src = _mm256_loadu_si256::<[i16; 16]>(coeffs[offset..offset + 16].try_into().unwrap());

        // Widen low/high 8 i16 to i32
        let lo_128 = _mm256_castsi256_si128(src);
        let hi_128 = _mm256_extracti128_si256::<1>(src);
        let lo_32 = _mm256_cvtepi16_epi32(lo_128);
        let hi_32 = _mm256_cvtepi16_epi32(hi_128);

        // Multiply by combined_scale
        let prod_lo = _mm256_mullo_epi32(lo_32, scale_v);
        let prod_hi = _mm256_mullo_epi32(hi_32, scale_v);

        // Add rounding and shift right
        let shifted_lo = _mm256_sra_epi32(_mm256_add_epi32(prod_lo, add_v), shift_v);
        let shifted_hi = _mm256_sra_epi32(_mm256_add_epi32(prod_hi, add_v), shift_v);

        // Pack back to i16 with saturation (provides the -32768..32767 clamp)
        let packed = _mm256_packs_epi32(shifted_lo, shifted_hi);
        // Fix AVX2 lane crossing: packs operates within 128-bit lanes
        let result = _mm256_permute4x64_epi64::<0xD8>(packed);

        _mm256_storeu_si256::<[i16; 16]>(
            (&mut coeffs[offset..offset + 16]).try_into().unwrap(),
            result,
        );
    }

    // Scalar remainder
    for coef in coeffs.iter_mut().skip(chunks * 16) {
        let value = (*coef as i32 * combined_scale + add) >> shift;
        *coef = value.clamp(-32768, 32767) as i16;
    }
}

/// Scalar fallback for dequantize
pub(crate) fn dequantize_scalar(
    _token: ScalarToken,
    coeffs: &mut [i16],
    combined_scale: i32,
    shift: i32,
    add: i32,
) {
    for coef in coeffs.iter_mut() {
        let value = (*coef as i32 * combined_scale + add) >> shift;
        *coef = value.clamp(-32768, 32767) as i16;
    }
}
