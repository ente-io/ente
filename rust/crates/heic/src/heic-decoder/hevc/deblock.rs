//! Deblocking filter (H.265 Section 8.7.2)
//!
//! Applies strong/weak filtering at CU and TU boundaries to reduce blocking artifacts.
//! For I-slices (HEIC still images), all boundaries have bS=2 since both sides are intra-coded.

use super::picture::{DEBLOCK_FLAG_HORIZ, DEBLOCK_FLAG_VERT, DecodedFrame};

/// Beta prime values for deblocking filter (Table 8-12)
/// Index 0-51 maps QP to beta prime threshold
#[rustfmt::skip]
static BETA_PRIME: [u16; 52] = [
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24,
    26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56,
    58, 60, 62, 64,
];

/// tC prime values for deblocking filter (Table 8-23)
/// Index 0-53 maps to tC prime threshold
#[rustfmt::skip]
static TC_PRIME: [u16; 54] = [
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  3,
     3,  3,  3,  4,  4,  4,  5,  5,  6,  6,  7,  8,  9, 10, 11, 13,
    14, 16, 18, 20, 22, 24,
];

/// Chroma QP mapping table (Table 8-10) for indices 30-42
#[rustfmt::skip]
static CHROMA_QP_TABLE: [i32; 13] = [
    29, 30, 31, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37,
];

/// Map intermediate chroma QP to actual chroma QP (4:2:0)
fn chroma_qp_mapping(qp_i: i32) -> i32 {
    if qp_i < 30 {
        qp_i
    } else if qp_i >= 43 {
        qp_i - 6
    } else {
        CHROMA_QP_TABLE[(qp_i - 30) as usize]
    }
}

/// Apply the deblocking filter to a decoded frame.
///
/// `beta_offset` and `tc_offset` come from slice header (slice_beta_offset_div2 * 2
/// and slice_tc_offset_div2 * 2).
/// `cb_qp_offset` and `cr_qp_offset` come from PPS (pps_cb_qp_offset / pps_cr_qp_offset).
pub fn apply_deblocking_filter(
    frame: &mut DecodedFrame,
    beta_offset: i32,
    tc_offset: i32,
    cb_qp_offset: i32,
    cr_qp_offset: i32,
) {
    let width = frame.width;
    let height = frame.height;

    // Pass 1: Vertical edges
    // Process at 8-sample intervals in x, 4-sample intervals in y
    let mut x = 8u32;
    while x < width {
        let mut y = 0u32;
        while y < height {
            let bx = x / 4;
            let by = y / 4;
            let idx = (by * frame.deblock_stride + bx) as usize;
            if idx < frame.deblock_flags.len()
                && (frame.deblock_flags[idx] & DEBLOCK_FLAG_VERT) != 0
            {
                // Get QP on both sides
                let qp_q = frame.qp_map[idx] as i32;
                let qp_p = if bx > 0 {
                    frame.qp_map[(by * frame.deblock_stride + bx - 1) as usize] as i32
                } else {
                    qp_q
                };

                filter_edge_luma(frame, x, y, true, qp_p, qp_q, beta_offset, tc_offset);
            }
            y += 4;
        }
        x += 8;
    }

    // Pass 2: Horizontal edges
    // Process at 4-sample intervals in x, 8-sample intervals in y
    let mut y = 8u32;
    while y < height {
        let mut x = 0u32;
        while x < width {
            let bx = x / 4;
            let by = y / 4;
            let idx = (by * frame.deblock_stride + bx) as usize;
            if idx < frame.deblock_flags.len()
                && (frame.deblock_flags[idx] & DEBLOCK_FLAG_HORIZ) != 0
            {
                let qp_q = frame.qp_map[idx] as i32;
                let qp_p = if by > 0 {
                    frame.qp_map[((by - 1) * frame.deblock_stride + bx) as usize] as i32
                } else {
                    qp_q
                };

                filter_edge_luma(frame, x, y, false, qp_p, qp_q, beta_offset, tc_offset);
            }
            x += 4;
        }
        y += 8;
    }

    // Chroma deblocking (only for bS=2, which is all edges for I-slices)
    if frame.chroma_format > 0 {
        apply_chroma_deblocking(frame, tc_offset, cb_qp_offset, cr_qp_offset);
    }
}

/// Filter a single luma edge (4 samples along the edge)
///
/// For vertical edges: x is the boundary position, filtering samples at x-1..x-4 and x..x+3
/// For horizontal edges: y is the boundary position, filtering samples at y-1..y-4 and y..y+3
///
/// Uses direct plane access with stride-based indexing to avoid per-sample bounds checks.
#[allow(clippy::too_many_arguments)]
fn filter_edge_luma(
    frame: &mut DecodedFrame,
    x: u32,
    y: u32,
    vertical: bool,
    qp_p: i32,
    qp_q: i32,
    beta_offset: i32,
    tc_offset: i32,
) {
    let bit_depth = frame.bit_depth as i32;
    let max_val = (1i32 << bit_depth) - 1;

    // For I-slices, bS is always 2 at boundaries
    let bs = 2i32;

    // Compute thresholds
    let qp_l = (qp_q + qp_p + 1) >> 1;
    let q_beta = (qp_l + beta_offset).clamp(0, 51);
    let beta = (BETA_PRIME[q_beta as usize] as i32) << (bit_depth - 8);
    let q_tc = (qp_l + 2 * (bs - 1) + tc_offset).clamp(0, 53);
    let tc = (TC_PRIME[q_tc as usize] as i32) << (bit_depth - 8);

    if tc == 0 {
        return;
    }

    let stride = frame.y_stride();
    let plane = &mut frame.y_plane;

    // Compute stride-based addressing:
    // - step_along: stride between adjacent samples along the edge (k direction)
    // - step_across: stride between adjacent samples perpendicular to edge (p/q direction)
    // - base_q: offset of q[0][0] in plane
    let (step_along, step_across, base_q) = if vertical {
        // Vertical edge: k steps in y (stride), p/q steps in x (1)
        (stride, 1usize, y as usize * stride + x as usize)
    } else {
        // Horizontal edge: k steps in x (1), p/q steps in y (stride)
        (1usize, stride, y as usize * stride + x as usize)
    };
    // base_p = one step before the boundary on the p side
    let base_p = base_q - step_across;

    // Bounds check: ensure all 4 samples on both sides are in-bounds
    // q side extends 3 steps across from base_q, plus 3 steps along
    // p side extends 3 steps across back from base_p (= base_q - step_across)
    if base_p < 3 * step_across {
        return;
    }
    let last_q = base_q + 3 * step_along + 3 * step_across;
    if last_q >= plane.len() {
        return;
    }

    // Read samples for edge decision at k=0 and k=3
    let k3 = 3 * step_along;
    let p0_0 = plane[base_p] as i32;
    let p1_0 = plane[base_p - step_across] as i32;
    let p2_0 = plane[base_p - 2 * step_across] as i32;
    let p3_0 = plane[base_p - 3 * step_across] as i32;
    let q0_0 = plane[base_q] as i32;
    let q1_0 = plane[base_q + step_across] as i32;
    let q2_0 = plane[base_q + 2 * step_across] as i32;
    let q3_0 = plane[base_q + 3 * step_across] as i32;

    let p0_3 = plane[base_p + k3] as i32;
    let p1_3 = plane[base_p + k3 - step_across] as i32;
    let p2_3 = plane[base_p + k3 - 2 * step_across] as i32;
    let p3_3 = plane[base_p + k3 - 3 * step_across] as i32;
    let q0_3 = plane[base_q + k3] as i32;
    let q1_3 = plane[base_q + k3 + step_across] as i32;
    let q2_3 = plane[base_q + k3 + 2 * step_across] as i32;
    let q3_3 = plane[base_q + k3 + 3 * step_across] as i32;

    // Edge decision (H.265 8.7.2.5.3)
    let dp0 = (p2_0 - 2 * p1_0 + p0_0).abs();
    let dp3 = (p2_3 - 2 * p1_3 + p0_3).abs();
    let dq0 = (q2_0 - 2 * q1_0 + q0_0).abs();
    let dq3 = (q2_3 - 2 * q1_3 + q0_3).abs();

    let dpq0 = dp0 + dq0;
    let dpq3 = dp3 + dq3;
    let dp = dp0 + dp3;
    let dq = dq0 + dq3;
    let d = dpq0 + dpq3;

    if d >= beta {
        return;
    }

    // Determine filter strength
    let d_sam0 = 2 * dpq0 < (beta >> 2)
        && (p3_0 - p0_0).abs() + (q0_0 - q3_0).abs() < (beta >> 3)
        && (p0_0 - q0_0).abs() < ((5 * tc + 1) >> 1);

    let d_sam3 = 2 * dpq3 < (beta >> 2)
        && (p3_3 - p0_3).abs() + (q0_3 - q3_3).abs() < (beta >> 3)
        && (p0_3 - q0_3).abs() < ((5 * tc + 1) >> 1);

    let strong = d_sam0 && d_sam3;
    let d_ep = dp < ((beta + (beta >> 1)) >> 3);
    let d_eq = dq < ((beta + (beta >> 1)) >> 3);

    // Apply filter for all 4 samples along the edge
    for k in 0..4usize {
        let k_off = k * step_along;

        // Read p[0..3] and q[0..3] for this sample
        let p0 = plane[base_p + k_off] as i32;
        let p1 = plane[base_p + k_off - step_across] as i32;
        let p2 = plane[base_p + k_off - 2 * step_across] as i32;
        let q0 = plane[base_q + k_off] as i32;
        let q1 = plane[base_q + k_off + step_across] as i32;
        let q2 = plane[base_q + k_off + 2 * step_across] as i32;

        if strong {
            let p3 = plane[base_p + k_off - 3 * step_across] as i32;
            let q3 = plane[base_q + k_off + 3 * step_across] as i32;
            let tc2 = 2 * tc;

            // Strong filter (H.265 8.7.2.5.7)
            let p0_f = ((p2 + 2 * p1 + 2 * p0 + 2 * q0 + q1 + 4) >> 3)
                .clamp(p0 - tc2, p0 + tc2)
                .clamp(0, max_val);
            let p1_f = ((p2 + p1 + p0 + q0 + 2) >> 2)
                .clamp(p1 - tc2, p1 + tc2)
                .clamp(0, max_val);
            let p2_f = ((2 * p3 + 3 * p2 + p1 + p0 + q0 + 4) >> 3)
                .clamp(p2 - tc2, p2 + tc2)
                .clamp(0, max_val);
            let q0_f = ((p1 + 2 * p0 + 2 * q0 + 2 * q1 + q2 + 4) >> 3)
                .clamp(q0 - tc2, q0 + tc2)
                .clamp(0, max_val);
            let q1_f = ((p0 + q0 + q1 + q2 + 2) >> 2)
                .clamp(q1 - tc2, q1 + tc2)
                .clamp(0, max_val);
            let q2_f = ((p0 + q0 + q1 + 3 * q2 + 2 * q3 + 4) >> 3)
                .clamp(q2 - tc2, q2 + tc2)
                .clamp(0, max_val);

            plane[base_p + k_off] = p0_f as u16;
            plane[base_p + k_off - step_across] = p1_f as u16;
            plane[base_p + k_off - 2 * step_across] = p2_f as u16;
            plane[base_q + k_off] = q0_f as u16;
            plane[base_q + k_off + step_across] = q1_f as u16;
            plane[base_q + k_off + 2 * step_across] = q2_f as u16;
        } else {
            // Weak filter
            let delta = (9 * (q0 - p0) - 3 * (q1 - p1) + 8) >> 4;

            if delta.abs() < 10 * tc {
                let delta = delta.clamp(-tc, tc);

                plane[base_p + k_off] = (p0 + delta).clamp(0, max_val) as u16;
                plane[base_q + k_off] = (q0 - delta).clamp(0, max_val) as u16;

                if d_ep {
                    let delta_p =
                        ((((p2 + p0 + 1) >> 1) - p1 + delta) >> 1).clamp(-(tc >> 1), tc >> 1);
                    plane[base_p + k_off - step_across] = (p1 + delta_p).clamp(0, max_val) as u16;
                }
                if d_eq {
                    let delta_q =
                        ((((q2 + q0 + 1) >> 1) - q1 - delta) >> 1).clamp(-(tc >> 1), tc >> 1);
                    plane[base_q + k_off + step_across] = (q1 + delta_q).clamp(0, max_val) as u16;
                }
            }
        }
    }
}

/// Apply chroma deblocking filter
///
/// For I-slices, all edges have bS=2, so chroma deblocking applies everywhere.
/// Chroma deblocking only modifies p0 and q0 (one sample on each side).
fn apply_chroma_deblocking(
    frame: &mut DecodedFrame,
    tc_offset: i32,
    cb_qp_offset: i32,
    cr_qp_offset: i32,
) {
    let width = frame.width;
    let height = frame.height;
    let bit_depth_c = frame.bit_depth as i32; // Same as luma for typical HEIC
    let max_val = (1i32 << bit_depth_c) - 1;

    // Chroma subsampling factors
    let (sub_x, sub_y) = match frame.chroma_format {
        1 => (2u32, 2u32),
        2 => (2, 1),
        3 => (1, 1),
        _ => return,
    };

    let c_stride = frame.c_stride();
    let c_height = height / sub_y;
    let c_width = width / sub_x;

    // For 4:2:0: chroma edges are at 8-chroma-pixel intervals (16 luma pixels).
    // Per H.265 8.7.2, chroma deblocking requires both sides to have width/height >= 8
    // in chroma samples. The edge processing unit is 4 chroma samples along the edge.
    //
    // Matching libde265: xIncr = 2*SubWidthC (in 4-luma-pixel deblock grid units),
    // yIncr = SubHeightC for vertical, yIncr = 2*SubHeightC for horizontal.
    let x_step_vert = 8 * sub_x; // luma x step for vertical edges (16 for 4:2:0)
    let y_step_vert = 4 * sub_y; // luma y step for vertical edges (8 for 4:2:0)
    let x_step_horiz = 4 * sub_x; // luma x step for horizontal edges (8 for 4:2:0)
    let y_step_horiz = 8 * sub_y; // luma y step for horizontal edges (16 for 4:2:0)

    // Pass 1: Vertical edges
    let mut x = x_step_vert;
    while x < width {
        let mut y = 0u32;
        while y < height {
            let bx = x / 4;
            let by = y / 4;
            let idx = (by * frame.deblock_stride + bx) as usize;
            if idx < frame.deblock_flags.len()
                && (frame.deblock_flags[idx] & DEBLOCK_FLAG_VERT) != 0
            {
                let qp_q = frame.qp_map[idx] as i32;
                let qp_p = if bx > 0 {
                    frame.qp_map[(by * frame.deblock_stride + bx - 1) as usize] as i32
                } else {
                    qp_q
                };

                let cx = x / sub_x;
                let cy = y / sub_y;

                for c_idx in 0..2 {
                    let qp_offset = if c_idx == 0 {
                        cb_qp_offset
                    } else {
                        cr_qp_offset
                    };
                    let qp_i = ((qp_q + qp_p + 1) >> 1) + qp_offset;
                    let qp_c = chroma_qp_mapping(qp_i);
                    let q_tc = (qp_c + 2 + tc_offset).clamp(0, 53);
                    let tc = (TC_PRIME[q_tc as usize] as i32) << (bit_depth_c - 8);

                    if tc == 0 {
                        continue;
                    }

                    let plane = if c_idx == 0 {
                        &mut frame.cb_plane
                    } else {
                        &mut frame.cr_plane
                    };

                    // Process 4 chroma samples along the edge
                    let num_samples = 4u32.min(c_height.saturating_sub(cy));
                    for k in 0..num_samples {
                        let row = (cy + k) as usize;
                        if cx < 2 || cx as usize >= c_stride || row >= plane.len() / c_stride {
                            continue;
                        }
                        let base = row * c_stride;
                        let ci = cx as usize;
                        if ci + 1 >= c_stride {
                            continue;
                        }
                        let p1 = plane[base + ci - 2] as i32;
                        let p0 = plane[base + ci - 1] as i32;
                        let q0 = plane[base + ci] as i32;
                        let q1 = plane[base + ci + 1] as i32;

                        let delta = (((q0 - p0) * 4 + p1 - q1 + 4) >> 3).clamp(-tc, tc);
                        plane[base + ci - 1] = (p0 + delta).clamp(0, max_val) as u16;
                        plane[base + ci] = (q0 - delta).clamp(0, max_val) as u16;
                    }
                }
            }
            y += y_step_vert;
        }
        x += x_step_vert;
    }

    // Pass 2: Horizontal edges
    let mut y = y_step_horiz;
    while y < height {
        let mut x = 0u32;
        while x < width {
            let bx = x / 4;
            let by = y / 4;
            let idx = (by * frame.deblock_stride + bx) as usize;
            if idx < frame.deblock_flags.len()
                && (frame.deblock_flags[idx] & DEBLOCK_FLAG_HORIZ) != 0
            {
                let qp_q = frame.qp_map[idx] as i32;
                let qp_p = if by > 0 {
                    frame.qp_map[((by - 1) * frame.deblock_stride + bx) as usize] as i32
                } else {
                    qp_q
                };

                let cx = x / sub_x;
                let cy = y / sub_y;

                for c_idx in 0..2 {
                    let qp_offset = if c_idx == 0 {
                        cb_qp_offset
                    } else {
                        cr_qp_offset
                    };
                    let qp_i = ((qp_q + qp_p + 1) >> 1) + qp_offset;
                    let qp_c = chroma_qp_mapping(qp_i);
                    let q_tc = (qp_c + 2 + tc_offset).clamp(0, 53);
                    let tc = (TC_PRIME[q_tc as usize] as i32) << (bit_depth_c - 8);

                    if tc == 0 {
                        continue;
                    }

                    let plane = if c_idx == 0 {
                        &mut frame.cb_plane
                    } else {
                        &mut frame.cr_plane
                    };

                    // Process 4 chroma samples along the edge
                    let num_samples = 4u32.min(c_width.saturating_sub(cx));
                    for k in 0..num_samples {
                        let col = (cx + k) as usize;
                        if cy < 2 || col >= c_stride {
                            continue;
                        }
                        let row_q = cy as usize;
                        let row_p = row_q - 1;
                        if row_q + 1 >= plane.len() / c_stride || row_p < 1 {
                            continue;
                        }

                        let p1 = plane[(row_p - 1) * c_stride + col] as i32;
                        let p0 = plane[row_p * c_stride + col] as i32;
                        let q0 = plane[row_q * c_stride + col] as i32;
                        let q1 = plane[(row_q + 1) * c_stride + col] as i32;

                        let delta = (((q0 - p0) * 4 + p1 - q1 + 4) >> 3).clamp(-tc, tc);
                        plane[row_p * c_stride + col] = (p0 + delta).clamp(0, max_val) as u16;
                        plane[row_q * c_stride + col] = (q0 - delta).clamp(0, max_val) as u16;
                    }
                }
            }
            x += x_step_horiz;
        }
        y += y_step_horiz;
    }
}
