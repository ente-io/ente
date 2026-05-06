//! CTU (Coding Tree Unit) and CU (Coding Unit) decoding
//!
//! This module handles the hierarchical quad-tree structure of HEVC:
//! - CTU: Coding Tree Unit (largest block, typically 64x64)
//! - CU: Coding Unit (result of quad-tree split, 8x8 to 64x64)
//! - PU: Prediction Unit (for motion/intra prediction)
//! - TU: Transform Unit (for residual coding)

use alloc::vec;
use alloc::vec::Vec;
use core::sync::atomic::{AtomicU32, Ordering};

/// Set to true to enable verbose debug tracing to stderr
const DEBUG_TRACE: bool = false;

/// Debug print macro gated behind DEBUG_TRACE const
macro_rules! debug_trace {
    ($($arg:tt)*) => {
        #[cfg(feature = "std")]
        if DEBUG_TRACE {
            eprintln!($($arg)*);
        }
    };
}

use super::cabac::{CabacDecoder, ContextModel, INIT_VALUES, context};
use super::debug;
use super::intra;
use super::params::{Pps, Sps};
use super::picture::DecodedFrame;
use super::residual::{self, ScanOrder};
use super::sao::SaoMap;
use super::slice::{IntraPredMode, PartMode, PredMode, SliceHeader};
use super::transform;
use super::transform_simd::add_residual_block_scalar;
#[cfg(target_arch = "x86_64")]
use super::transform_simd::add_residual_block_v3;
use crate::heic_decoder::error::HevcError;
use archmage::incant;

type Result<T> = core::result::Result<T, HevcError>;

/// Global SE counter for syntax element tracing
pub static SE_COUNTER: AtomicU32 = AtomicU32::new(0);
pub const SE_TRACE_LIMIT: u32 = 0;

/// Log a syntax element decode for differential testing.
/// Set SE_TRACE_LIMIT > 0 to enable tracing.
#[allow(clippy::absurd_extreme_comparisons)]
fn se_trace(name: &str, val: i64, cabac: &CabacDecoder) {
    let num = SE_COUNTER.fetch_add(1, Ordering::Relaxed);
    if num < SE_TRACE_LIMIT {
        #[cfg(feature = "std")]
        {
            let (range, _, _) = cabac.get_state_extended();
            let (byte_pos, _, _) = cabac.get_position();
            eprintln!(
                "SE#{} {} val={} range={} byte={}",
                num, name, val, range, byte_pos
            );
        }
    }
    let _ = (name, val, cabac);
}

/// Chroma QP mapping table (H.265 Table 8-10)
/// Maps qPi (0-57) to QpC for 8-bit video
fn chroma_qp_mapping(qp_i: i32) -> i32 {
    // Table 8-10: qPi to QpC mapping
    // For qPi 0-29, QpC = qPi
    // For qPi 30-57, QpC follows the table
    static CHROMA_QP_TABLE: [i32; 58] = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 29, 30, 31, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37, 37, 38, 39, 40, 41,
        42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
    ];
    CHROMA_QP_TABLE[qp_i.clamp(0, 57) as usize]
}

/// Decoding context for a slice
pub struct SliceContext<'a> {
    /// Sequence parameter set
    pub sps: &'a Sps,
    /// Picture parameter set
    pub pps: &'a Pps,
    /// Slice header
    pub header: &'a SliceHeader,
    /// CABAC decoder
    pub cabac: CabacDecoder<'a>,
    /// Context models
    pub ctx: [ContextModel; context::NUM_CONTEXTS],
    /// Current CTB X position (in CTB units)
    pub ctb_x: u32,
    /// Current CTB Y position (in CTB units)
    pub ctb_y: u32,
    /// Current luma QP value
    pub qp_y: i32,
    /// Current Cb QP value
    pub qp_cb: i32,
    /// Current Cr QP value
    pub qp_cr: i32,
    /// Is CU QP delta coded flag
    pub is_cu_qp_delta_coded: bool,
    /// CU QP delta value
    pub cu_qp_delta: i32,
    /// CU transquant bypass flag
    pub cu_transquant_bypass_flag: bool,
    /// Debug flag for current CTU
    debug_ctu: bool,
    /// Debug: track chroma prediction calls
    #[allow(dead_code)]
    chroma_pred_count: u32,
    /// CT depth map for split_cu_flag context derivation (indexed by min_cb_size grid)
    ct_depth_map: Vec<u8>,
    /// Width of ct_depth_map in min_cb_size units
    ct_depth_map_stride: u32,
    /// Intra luma mode map (indexed by min_pu_size grid, stores IntraPredMode as u8)
    /// min_pu_size = min_cb_size / 2, to support NxN PU resolution
    intra_mode_map: Vec<u8>,
    /// Width of intra_mode_map in min_pu_size units
    intra_mode_map_stride: u32,
    /// Intra chroma mode map (indexed by min_pu_size grid, stores IntraPredMode as u8)
    intra_chroma_mode_map: Vec<u8>,
    /// Current CU base position (set at decode_coding_unit start)
    cu_base_x: u32,
    cu_base_y: u32,
    /// Current CU log2 size (set at decode_coding_unit start)
    cu_log2_size: u8,
    /// QP map: stores per-CU QPY values (indexed by min_tb_size grid)
    qp_map: Vec<i8>,
    /// Width of QP map in min_tb_size units
    qp_map_stride: u32,
    /// Current QPY for the current quantization group
    current_qpy: i32,
    /// Last QPY from previous quantization group (for prediction)
    last_qpy_in_prev_qg: i32,
    /// Current quantization group position
    current_qg_x: i32,
    current_qg_y: i32,
    /// SAO parameters per CTB
    pub sao_map: SaoMap,
    /// Reusable residual buffer (inverse transform writes all elements, no re-zeroing needed)
    residual_buf: [i16; 1024],
    /// Reusable scaling matrix buffer
    scaling_buf: [u8; 1024],
}

impl<'a> SliceContext<'a> {
    /// Create a new slice context
    pub fn new(
        sps: &'a Sps,
        pps: &'a Pps,
        header: &'a SliceHeader,
        slice_data: &'a [u8],
    ) -> Result<Self> {
        // DEBUG: Print first few bytes of slice data
        debug_trace!(
            "DEBUG: Slice data first 16 bytes: {:02x?}",
            &slice_data[..16.min(slice_data.len())]
        );
        debug_trace!(
            "DEBUG: SPS: {}x{}, ctb_size={}, min_cb_size={}, scaling_list={}",
            sps.pic_width_in_luma_samples,
            sps.pic_height_in_luma_samples,
            sps.ctb_size(),
            1 << sps.log2_min_cb_size(),
            sps.scaling_list_enabled_flag
        );
        debug_trace!(
            "DEBUG: SPS: max_transform_hierarchy_depth_intra={}",
            sps.max_transform_hierarchy_depth_intra
        );
        debug_trace!(
            "DEBUG: SPS: log2_min_tb={}, log2_max_tb={}",
            sps.log2_min_tb_size(),
            sps.log2_max_tb_size()
        );

        let cabac = CabacDecoder::new(slice_data)?;
        let (range, offset) = cabac.get_state();
        debug_trace!(
            "DEBUG: CABAC init state: range={}, offset={}",
            range,
            offset
        );

        // Initialize context models
        let mut ctx = [ContextModel::new(154); context::NUM_CONTEXTS];
        let slice_qp = header.slice_qp_y;

        for (i, init_val) in INIT_VALUES.iter().enumerate() {
            ctx[i].init(*init_val, slice_qp);
        }

        // Calculate chroma QP values (H.265 Table 8-10 and section 8.6.1)
        // qPi_Cb = qP_Y + pps_cb_qp_offset + slice_cb_qp_offset
        // qPi_Cr = qP_Y + pps_cr_qp_offset + slice_cr_qp_offset
        let qp_i_cb = slice_qp + pps.pps_cb_qp_offset as i32 + header.slice_cb_qp_offset as i32;
        let qp_i_cr = slice_qp + pps.pps_cr_qp_offset as i32 + header.slice_cr_qp_offset as i32;

        // Apply chroma QP mapping table (H.265 Table 8-10)
        let qp_cb = chroma_qp_mapping(qp_i_cb.clamp(0, 57));
        let qp_cr = chroma_qp_mapping(qp_i_cr.clamp(0, 57));

        debug_trace!(
            "DEBUG: Chroma QP: qp_y={}, qp_cb={}, qp_cr={}",
            slice_qp,
            qp_cb,
            qp_cr
        );
        debug_trace!(
            "DEBUG: sign_data_hiding_enabled_flag={}",
            pps.sign_data_hiding_enabled_flag
        );
        debug_trace!(
            "DEBUG: tiles_enabled={} entropy_coding_sync={}",
            pps.tiles_enabled_flag,
            pps.entropy_coding_sync_enabled_flag
        );
        // Initialize ct_depth_map for split_cu_flag context derivation
        // Map is in units of min_cb_size (typically 8x8)
        let min_cb_size = 1u32 << sps.log2_min_cb_size();
        let ct_depth_map_stride = sps.pic_width_in_luma_samples.div_ceil(min_cb_size);
        let ct_depth_map_height = sps.pic_height_in_luma_samples.div_ceil(min_cb_size);
        let ct_map_size = (ct_depth_map_stride * ct_depth_map_height) as usize;
        let ct_depth_map = vec![0xFF; ct_map_size];

        // Intra mode map at min_pu_size granularity (= min_cb_size / 2)
        // This supports NxN partition PU-level resolution
        let min_pu_size = (min_cb_size / 2).max(1);
        let intra_mode_map_stride = sps.pic_width_in_luma_samples.div_ceil(min_pu_size);
        let intra_mode_map_height = sps.pic_height_in_luma_samples.div_ceil(min_pu_size);
        let pu_map_size = (intra_mode_map_stride * intra_mode_map_height) as usize;
        let intra_mode_map = vec![IntraPredMode::Dc.as_u8(); pu_map_size];
        let intra_chroma_mode_map = vec![IntraPredMode::Dc.as_u8(); pu_map_size];

        // QP map at min_tb_size granularity
        let min_tb_size = 1u32 << sps.log2_min_tb_size();
        let qp_map_stride = sps.pic_width_in_luma_samples.div_ceil(min_tb_size);
        let qp_map_height = sps.pic_height_in_luma_samples.div_ceil(min_tb_size);
        let qp_map = vec![slice_qp as i8; (qp_map_stride * qp_map_height) as usize];

        Ok(Self {
            sps,
            pps,
            header,
            cabac,
            ctx,
            ctb_x: 0,
            ctb_y: 0,
            qp_y: slice_qp,
            qp_cb,
            qp_cr,
            is_cu_qp_delta_coded: false,
            cu_qp_delta: 0,
            cu_transquant_bypass_flag: false,
            debug_ctu: false,
            chroma_pred_count: 0,
            ct_depth_map,
            ct_depth_map_stride,
            intra_mode_map,
            intra_mode_map_stride,
            intra_chroma_mode_map,
            cu_base_x: 0,
            cu_base_y: 0,
            cu_log2_size: 0,
            qp_map,
            qp_map_stride,
            current_qpy: slice_qp,
            last_qpy_in_prev_qg: slice_qp,
            current_qg_x: -1,
            current_qg_y: -1,
            sao_map: SaoMap::new(sps.pic_width_in_ctbs(), sps.pic_height_in_ctbs()),
            residual_buf: [0i16; 1024],
            scaling_buf: [16u8; 1024],
        })
    }

    /// Decode all CTUs in the slice
    pub fn decode_slice(&mut self, frame: &mut DecodedFrame) -> Result<()> {
        // Initialize CABAC tracker for debugging
        debug::init_tracker();

        let ctb_size = self.sps.ctb_size();
        let pic_width_in_ctbs = self.sps.pic_width_in_ctbs();
        let pic_height_in_ctbs = self.sps.pic_height_in_ctbs();
        let wpp = self.pps.entropy_coding_sync_enabled_flag;

        // Start from slice segment address
        let start_addr = self.header.slice_segment_address;
        self.ctb_y = start_addr / pic_width_in_ctbs;
        self.ctb_x = start_addr % pic_width_in_ctbs;

        let mut ctu_count = 0u32;
        let total_ctus = pic_width_in_ctbs * pic_height_in_ctbs;

        // WPP: saved context models from CTB column 1 of previous row
        let mut wpp_saved_ctx: Option<[super::cabac::ContextModel; context::NUM_CONTEXTS]> = None;

        loop {
            // WPP: at start of each new row (ctb_x==0, ctb_y>0), restore saved context
            if wpp
                && self.ctb_x == 0
                && self.ctb_y > 0
                && pic_width_in_ctbs > 1
                && let Some(saved) = wpp_saved_ctx
            {
                self.ctx = saved;
            }

            // Decode one CTU
            let x_ctb = self.ctb_x * ctb_size;
            let y_ctb = self.ctb_y * ctb_size;

            // Track CTU position for debugging
            let (byte_pos, _, _) = self.cabac.get_position();
            debug::track_ctu_start(ctu_count, byte_pos);

            // DEBUG: Print CTU state periodically
            if ctu_count.is_multiple_of(50) || ctu_count <= 3 {
                let (range, offset) = self.cabac.get_state();
                debug_trace!(
                    "DEBUG: CTU {} byte={} cabac=({},{}) x={} y={}",
                    ctu_count,
                    byte_pos,
                    range,
                    offset,
                    self.ctb_x,
                    self.ctb_y
                );
            }
            // Enable debug for CTU 1 (where first large coefficient occurs)
            self.debug_ctu = ctu_count == 1;

            self.decode_ctu(x_ctb, y_ctb, frame)?;
            ctu_count += 1;

            // WPP: save context models after CTB column 1
            if wpp && self.ctb_x == 1 && self.ctb_y < pic_height_in_ctbs - 1 {
                wpp_saved_ctx = Some(self.ctx);
            }

            // Check for end of slice segment
            let end_of_slice = self.cabac.decode_terminate()?;
            se_trace("end_of_slice", end_of_slice as i64, &self.cabac);
            if end_of_slice != 0 {
                debug_trace!(
                    "DEBUG: end_of_slice after CTU {}, decoded {}/{} CTUs",
                    ctu_count,
                    ctu_count,
                    total_ctus
                );
                break;
            }

            // Track previous row for WPP boundary detection
            let prev_ctb_y = self.ctb_y;

            // Move to next CTB
            self.ctb_x += 1;
            if self.ctb_x >= pic_width_in_ctbs {
                self.ctb_x = 0;
                self.ctb_y += 1;
            }

            // WPP: at row boundaries, decode end_of_sub_stream and reinit CABAC
            if wpp && self.ctb_y != prev_ctb_y {
                let _eoss = self.cabac.decode_terminate()?;
                self.cabac.reinit();
            }

            // Check for end of picture
            if self.ctb_y >= pic_height_in_ctbs {
                break;
            }
        }

        if DEBUG_TRACE {
            debug::print_tracker_summary();
        }
        Ok(())
    }

    /// Decode a single CTU (Coding Tree Unit)
    fn decode_ctu(&mut self, x_ctb: u32, y_ctb: u32, frame: &mut DecodedFrame) -> Result<()> {
        let log2_ctb_size = self.sps.log2_ctb_size();

        // Reset per-CTU state
        if self.pps.cu_qp_delta_enabled_flag {
            self.is_cu_qp_delta_coded = false;
            self.cu_qp_delta = 0;
        }

        // Decode SAO syntax elements (must consume from CABAC stream even if not applied)
        if self.header.slice_sao_luma_flag || self.header.slice_sao_chroma_flag {
            self.decode_sao(x_ctb, y_ctb)?;
        }

        // Decode the coding quadtree
        self.decode_coding_quadtree(x_ctb, y_ctb, log2_ctb_size, 0, frame)
    }

    /// Decode SAO (Sample Adaptive Offset) syntax elements from CABAC stream
    /// and store them in the SAO map for later filtering.
    fn decode_sao(&mut self, x_ctb_pixels: u32, y_ctb_pixels: u32) -> Result<()> {
        let ctb_size = self.sps.ctb_size();
        let x_ctb = x_ctb_pixels / ctb_size;
        let y_ctb = y_ctb_pixels / ctb_size;

        let mut sao_merge_left_flag = false;
        let mut sao_merge_up_flag = false;

        // sao_merge_left_flag
        if x_ctb > 0 {
            let pic_width_ctbs = self.sps.pic_width_in_ctbs();
            let ctb_addr_rs = y_ctb * pic_width_ctbs + x_ctb;
            let slice_addr_rs = 0u32;
            let left_in_slice = ctb_addr_rs > slice_addr_rs;
            if left_in_slice {
                let ctx_idx = context::SAO_MERGE_FLAG;
                sao_merge_left_flag = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
                se_trace("sao_merge_left", sao_merge_left_flag as i64, &self.cabac);
            }
        }

        // sao_merge_up_flag
        if y_ctb > 0 && !sao_merge_left_flag {
            let pic_width_ctbs = self.sps.pic_width_in_ctbs();
            let ctb_addr_rs = y_ctb * pic_width_ctbs + x_ctb;
            let slice_addr_rs = 0u32;
            let up_in_slice = ctb_addr_rs >= pic_width_ctbs + slice_addr_rs;
            if up_in_slice {
                let ctx_idx = context::SAO_MERGE_FLAG;
                sao_merge_up_flag = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
                se_trace("sao_merge_up", sao_merge_up_flag as i64, &self.cabac);
            }
        }

        let sao_info = if sao_merge_left_flag {
            *self.sao_map.get(x_ctb - 1, y_ctb)
        } else if sao_merge_up_flag {
            *self.sao_map.get(x_ctb, y_ctb - 1)
        } else {
            let mut info = super::sao::SaoInfo::default();
            let is_mono = self.sps.chroma_format_idc == 0;
            let n_chroma = if is_mono { 1 } else { 3 };

            #[allow(unused_assignments)]
            let mut sao_type_idx_luma = 0u8;
            let mut sao_type_idx_chroma = 0u8;
            let mut eo_class_chroma = 0u8;

            for c_idx in 0..n_chroma {
                let should_decode = (self.header.slice_sao_luma_flag && c_idx == 0)
                    || (self.header.slice_sao_chroma_flag && c_idx > 0);

                if !should_decode {
                    continue;
                }

                let sao_type_idx = if c_idx == 0 {
                    sao_type_idx_luma = self.decode_sao_type_idx()?;
                    se_trace("sao_type_idx_luma", sao_type_idx_luma as i64, &self.cabac);
                    sao_type_idx_luma
                } else if c_idx == 1 {
                    sao_type_idx_chroma = self.decode_sao_type_idx()?;
                    se_trace(
                        "sao_type_idx_chroma",
                        sao_type_idx_chroma as i64,
                        &self.cabac,
                    );
                    sao_type_idx_chroma
                } else {
                    sao_type_idx_chroma
                };

                info.sao_type_idx[c_idx] = sao_type_idx;

                if sao_type_idx != 0 {
                    let bit_depth = if c_idx == 0 {
                        self.sps.bit_depth_y() as u32
                    } else {
                        self.sps.bit_depth_c() as u32
                    };
                    let c_max = (1u32 << (bit_depth.min(10) - 5)) - 1;
                    let offset_scale = 1i32 << (bit_depth.saturating_sub(bit_depth.min(10)));

                    let mut offsets_abs = [0u32; 4];
                    for elem in &mut offsets_abs {
                        *elem = self.decode_cabac_tu_bypass(c_max)?;
                        se_trace("sao_offset_abs", *elem as i64, &self.cabac);
                    }

                    if sao_type_idx == 1 {
                        // Band offset: decode signs + band position
                        let mut signed_offsets = [0i8; 4];
                        for i in 0..4 {
                            if offsets_abs[i] != 0 {
                                let sign = self.cabac.decode_bypass()?;
                                se_trace("sao_offset_sign", sign as i64, &self.cabac);
                                let val = (offsets_abs[i] as i32 * offset_scale) as i8;
                                signed_offsets[i] = if sign != 0 { -val } else { val };
                            }
                        }
                        info.sao_offset_val[c_idx] = signed_offsets;

                        let band_pos = self.cabac.decode_bypass_bits(5)?;
                        se_trace("sao_band_position", band_pos as i64, &self.cabac);
                        info.sao_band_position[c_idx] = band_pos as u8;
                    } else {
                        // Edge offset: store absolute values (sign applied during filtering)
                        for (i, &offset) in offsets_abs.iter().enumerate() {
                            info.sao_offset_val[c_idx][i] = (offset as i32 * offset_scale) as i8;
                        }

                        if c_idx <= 1 {
                            let eo_class = self.cabac.decode_bypass_bits(2)?;
                            se_trace("sao_eo_class", eo_class as i64, &self.cabac);
                            if c_idx == 0 {
                                info.sao_eo_class[0] = eo_class as u8;
                            } else {
                                eo_class_chroma = eo_class as u8;
                                info.sao_eo_class[1] = eo_class_chroma;
                            }
                        } else {
                            info.sao_eo_class[2] = eo_class_chroma;
                        }
                    }
                }
            }
            info
        };

        *self.sao_map.get_mut(x_ctb, y_ctb) = sao_info;
        Ok(())
    }

    /// Decode sao_type_idx: context bin + optional bypass bin
    fn decode_sao_type_idx(&mut self) -> Result<u8> {
        let ctx_idx = context::SAO_TYPE_IDX;
        let bit0 = self.cabac.decode_bin(&mut self.ctx[ctx_idx])?;
        if bit0 == 0 {
            Ok(0)
        } else {
            let bit1 = self.cabac.decode_bypass()?;
            if bit1 == 0 { Ok(1) } else { Ok(2) }
        }
    }

    /// Decode truncated unary with bypass bins (for sao_offset_abs)
    fn decode_cabac_tu_bypass(&mut self, c_max: u32) -> Result<u32> {
        for i in 0..c_max {
            let bit = self.cabac.decode_bypass()?;
            if bit == 0 {
                return Ok(i);
            }
        }
        Ok(c_max)
    }

    /// Decode coding quadtree recursively
    fn decode_coding_quadtree(
        &mut self,
        x0: u32,
        y0: u32,
        log2_cb_size: u8,
        ct_depth: u8,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        let cb_size = 1u32 << log2_cb_size;
        let pic_width = self.sps.pic_width_in_luma_samples;
        let pic_height = self.sps.pic_height_in_luma_samples;
        let log2_min_cb_size = self.sps.log2_min_cb_size();

        // Determine if we need to split
        let split_flag = if x0 + cb_size <= pic_width
            && y0 + cb_size <= pic_height
            && log2_cb_size > log2_min_cb_size
        {
            // Decode split_cu_flag
            let flag = self.decode_split_cu_flag(x0, y0, ct_depth)?;
            if self.debug_ctu {
                let (r, o) = self.cabac.get_state();
                debug_trace!(
                    "  CTU37: split_cu_flag at ({},{}) depth={} log2={} → {} (r={},o={})",
                    x0,
                    y0,
                    ct_depth,
                    log2_cb_size,
                    flag,
                    r,
                    o
                );
            }
            flag
        } else if log2_cb_size > log2_min_cb_size {
            // Must split if partially outside picture
            if self.debug_ctu {
                debug_trace!(
                    "  CTU37: forced split at ({},{}) depth={} - outside picture",
                    x0,
                    y0,
                    ct_depth
                );
            }
            true
        } else {
            // At minimum size, don't split
            if self.debug_ctu {
                debug_trace!(
                    "  CTU37: no split at ({},{}) depth={} - min size",
                    x0,
                    y0,
                    ct_depth
                );
            }
            false
        };

        // Handle QP delta depth: reset at quantization group boundaries
        // Log2MinCuQpDeltaSize = Log2CtbSizeY - diff_cu_qp_delta_depth
        if self.pps.cu_qp_delta_enabled_flag
            && log2_cb_size >= self.sps.log2_ctb_size() - self.pps.diff_cu_qp_delta_depth
        {
            self.is_cu_qp_delta_coded = false;
            self.cu_qp_delta = 0;
        }

        if split_flag {
            let half = cb_size / 2;
            let x1 = x0 + half;
            let y1 = y0 + half;

            // Decode four sub-CUs
            self.decode_coding_quadtree(x0, y0, log2_cb_size - 1, ct_depth + 1, frame)?;

            if x1 < pic_width {
                self.decode_coding_quadtree(x1, y0, log2_cb_size - 1, ct_depth + 1, frame)?;
            }

            if y1 < pic_height {
                self.decode_coding_quadtree(x0, y1, log2_cb_size - 1, ct_depth + 1, frame)?;
            }

            if x1 < pic_width && y1 < pic_height {
                self.decode_coding_quadtree(x1, y1, log2_cb_size - 1, ct_depth + 1, frame)?;
            }
        } else {
            // Decode the coding unit
            self.decode_coding_unit(x0, y0, log2_cb_size, ct_depth, frame)?;
        }

        Ok(())
    }

    /// Get ctDepth at a pixel position (returns 0xFF if not yet decoded)
    fn get_ct_depth(&self, x: u32, y: u32) -> u8 {
        let min_cb_size = 1u32 << self.sps.log2_min_cb_size();
        let map_x = x / min_cb_size;
        let map_y = y / min_cb_size;

        if map_x >= self.ct_depth_map_stride
            || map_y * self.ct_depth_map_stride + map_x >= self.ct_depth_map.len() as u32
        {
            return 0xFF; // Out of bounds
        }

        self.ct_depth_map[(map_y * self.ct_depth_map_stride + map_x) as usize]
    }

    /// Set ctDepth for a CU region
    fn set_ct_depth(&mut self, x0: u32, y0: u32, log2_cb_size: u8, ct_depth: u8) {
        let min_cb_size = 1u32 << self.sps.log2_min_cb_size();
        let cb_size = 1u32 << log2_cb_size;

        // Fill the ct_depth_map for this CU region
        let start_x = x0 / min_cb_size;
        let start_y = y0 / min_cb_size;
        let num_blocks = cb_size / min_cb_size;

        for dy in 0..num_blocks {
            for dx in 0..num_blocks {
                let map_x = start_x + dx;
                let map_y = start_y + dy;
                if map_x < self.ct_depth_map_stride {
                    let idx = (map_y * self.ct_depth_map_stride + map_x) as usize;
                    if idx < self.ct_depth_map.len() {
                        self.ct_depth_map[idx] = ct_depth;
                    }
                }
            }
        }
    }

    /// Check if a neighbor position is available (within picture bounds)
    fn is_neighbor_available(&self, x: i32, y: i32) -> bool {
        x >= 0
            && y >= 0
            && (x as u32) < self.sps.pic_width_in_luma_samples
            && (y as u32) < self.sps.pic_height_in_luma_samples
    }

    /// Decode split_cu_flag using CABAC
    fn decode_split_cu_flag(&mut self, x0: u32, y0: u32, ct_depth: u8) -> Result<bool> {
        // Context selection based on neighboring CU depths (H.265 9.3.4.2.2)
        // condTermL: 1 if left neighbor has larger depth (was split more)
        // condTermA: 1 if above neighbor has larger depth
        // ctxInc = condTermL + condTermA

        let available_l = self.is_neighbor_available(x0 as i32 - 1, y0 as i32);
        let available_a = self.is_neighbor_available(x0 as i32, y0 as i32 - 1);

        let mut cond_l = 0;
        let mut cond_a = 0;

        if available_l {
            let depth_l = self.get_ct_depth(x0 - 1, y0);
            if depth_l != 0xFF && depth_l > ct_depth {
                cond_l = 1;
            }
        }

        if available_a {
            let depth_a = self.get_ct_depth(x0, y0 - 1);
            if depth_a != 0xFF && depth_a > ct_depth {
                cond_a = 1;
            }
        }

        let ctx_idx = context::SPLIT_CU_FLAG + cond_l + cond_a;
        let bin = self.cabac.decode_bin(&mut self.ctx[ctx_idx])?;
        se_trace("split_cu_flag", bin as i64, &self.cabac);

        Ok(bin != 0)
    }

    /// Decode a coding unit
    fn decode_coding_unit(
        &mut self,
        x0: u32,
        y0: u32,
        log2_cb_size: u8,
        ct_depth: u8,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        let cb_size = 1u32 << log2_cb_size;
        let _ = cb_size; // Used in PartNxN

        // Track CU base position for transform unit QP derivation
        self.cu_base_x = x0;
        self.cu_base_y = y0;
        self.cu_log2_size = log2_cb_size;

        // Decode quantization parameters at CU start (H.265 8.6.1)
        self.decode_quantization_parameters(x0, y0, x0, y0);
        self.store_qpy(x0, y0, log2_cb_size, self.current_qpy);

        // Set ct_depth for this CU (used by split_cu_flag context derivation)
        self.set_ct_depth(x0, y0, log2_cb_size, ct_depth);

        // For I-slices, prediction mode is always INTRA
        let pred_mode = PredMode::Intra;

        // Decode transquant_bypass_flag if enabled
        self.cu_transquant_bypass_flag = if self.pps.transquant_bypass_enabled_flag {
            let ctx_idx = context::CU_TRANSQUANT_BYPASS_FLAG;
            self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0
        } else {
            false
        };

        // Decode partition mode
        let part_mode = if log2_cb_size == self.sps.log2_min_cb_size() {
            // At minimum size, can be 2Nx2N or NxN
            let pm = self.decode_part_mode(pred_mode, log2_cb_size)?;
            // Debug: log part_mode for first CTU (and count NxN)
            if pm == PartMode::PartNxN {
                static NXN_COUNT: core::sync::atomic::AtomicU32 =
                    core::sync::atomic::AtomicU32::new(0);
                let count = NXN_COUNT.fetch_add(1, core::sync::atomic::Ordering::Relaxed);
                if count == 0 || x0 < 64 && y0 < 64 {
                    let (r, o) = self.cabac.get_state();
                    debug_trace!(
                        "DEBUG: part_mode at ({},{}) log2={}: {:?} cabac=({},{})",
                        x0,
                        y0,
                        log2_cb_size,
                        pm,
                        r,
                        o
                    );
                }
            }
            if self.debug_ctu {
                let (r, o) = self.cabac.get_state();
                debug_trace!(
                    "  CTU37: CU at ({},{}) log2={} part_mode={:?} (r={},o={})",
                    x0,
                    y0,
                    log2_cb_size,
                    pm,
                    r,
                    o
                );
            }
            pm
        } else {
            // Larger sizes are always 2Nx2N for intra
            if self.debug_ctu {
                debug_trace!(
                    "  CTU37: CU at ({},{}) log2={} part_mode=2Nx2N (implicit)",
                    x0,
                    y0,
                    log2_cb_size
                );
            }
            PartMode::Part2Nx2N
        };

        // Decode prediction info and get intra modes for scan order
        let (intra_luma_mode, intra_chroma_mode) = match part_mode {
            PartMode::Part2Nx2N => {
                // Single PU covering entire CU
                let modes = self.decode_intra_prediction(x0, y0, log2_cb_size, true, frame)?;
                if self.debug_ctu {
                    let (r, o) = self.cabac.get_state();
                    debug_trace!(
                        "  CTU37: After intra_prediction at (1144,120): mode={:?} (r={},o={}) bits={}",
                        modes,
                        r,
                        o,
                        self.cabac.get_position().2
                    );
                }
                modes
            }
            PartMode::PartNxN => {
                // Four PUs (only at minimum CU size for intra)
                // For 4:2:0, all four 4x4 luma PUs share one 4x4 chroma block
                let half = cb_size / 2;
                let log2_pu_size = log2_cb_size - 1;

                // Per H.265 spec 7.3.8.5 and libde265 slice.cc:4385-4458:
                // FIRST pass: decode ALL prev_intra_luma_pred_flag (context-coded bins)
                let prev_flags = [
                    self.decode_prev_intra_luma_pred_flag()?,
                    self.decode_prev_intra_luma_pred_flag()?,
                    self.decode_prev_intra_luma_pred_flag()?,
                    self.decode_prev_intra_luma_pred_flag()?,
                ];

                // SECOND pass: decode mpm_idx/rem (bypass bins) and store IMMEDIATELY
                // per libde265: each PU mode stored before next PU's neighbor lookup
                let luma_mode_0 = self.derive_intra_luma_mode(x0, y0, prev_flags[0])?;
                self.store_intra_mode(x0, y0, log2_pu_size, luma_mode_0);

                let luma_mode_1 = self.derive_intra_luma_mode(x0 + half, y0, prev_flags[1])?;
                self.store_intra_mode(x0 + half, y0, log2_pu_size, luma_mode_1);

                let luma_mode_2 = self.derive_intra_luma_mode(x0, y0 + half, prev_flags[2])?;
                self.store_intra_mode(x0, y0 + half, log2_pu_size, luma_mode_2);

                let luma_mode_3 =
                    self.derive_intra_luma_mode(x0 + half, y0 + half, prev_flags[3])?;
                self.store_intra_mode(x0 + half, y0 + half, log2_pu_size, luma_mode_3);

                // Decode chroma mode once (using first luma mode for derivation if mode=4)
                let chroma_mode = self.decode_intra_chroma_mode(luma_mode_0)?;

                // Store chroma mode for the whole CU region
                self.store_intra_chroma_mode(x0, y0, log2_cb_size, chroma_mode);

                // NOTE: Prediction is NOT done here. It happens in decode_transform_unit_leaf
                // and the 8x8→4x4 chroma split handler, so each TU is predicted →
                // reconstructed before the next TU reads its neighbors.

                (luma_mode_0, chroma_mode)
            }
            _ => {
                // Other partition modes not used for intra
                return Err(HevcError::InvalidBitstream("invalid intra partition mode"));
            }
        };

        // Decode rqt_root_cbf (residual quad-tree coded block flag)
        // For intra, this is always coded (not signaled, assumed 1)
        // unless transquant_bypass is enabled
        if !self.cu_transquant_bypass_flag {
            // Decode transform tree
            let intra_split_flag = part_mode == PartMode::PartNxN;
            self.decode_transform_tree(
                x0,
                y0,
                log2_cb_size,
                0, // trafo_depth
                intra_luma_mode,
                intra_chroma_mode,
                intra_split_flag,
                frame,
            )?;

            if self.debug_ctu {
                let (r, o) = self.cabac.get_state();
                debug_trace!(
                    "  CTU37: After transform_tree at ({},{}) log2={} (r={},o={})",
                    x0,
                    y0,
                    log2_cb_size,
                    r,
                    o
                );
            }
        }

        Ok(())
    }

    /// Decode transform tree recursively
    #[allow(clippy::too_many_arguments)]
    fn decode_transform_tree(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        trafo_depth: u8,
        intra_luma_mode: IntraPredMode,
        intra_chroma_mode: IntraPredMode,
        intra_split_flag: bool,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        // For 4:2:0, start with root having chroma responsibility
        self.decode_transform_tree_inner(
            x0,
            y0,
            log2_size,
            trafo_depth,
            intra_luma_mode,
            intra_chroma_mode,
            intra_split_flag,
            true,
            true,
            frame,
        )
    }

    /// Inner transform tree decoding
    /// cbf_cb_parent/cbf_cr_parent: whether parent says chroma has residuals (or true at root)
    #[allow(clippy::too_many_arguments)]
    fn decode_transform_tree_inner(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        trafo_depth: u8,
        intra_luma_mode: IntraPredMode,
        intra_chroma_mode: IntraPredMode,
        intra_split_flag: bool,
        cbf_cb_parent: bool,
        cbf_cr_parent: bool,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        // Per H.265: MaxTrafoDepth = max_transform_hierarchy_depth_intra + IntraSplitFlag
        let max_trafo_depth =
            self.sps.max_transform_hierarchy_depth_intra + if intra_split_flag { 1 } else { 0 };
        let log2_min_trafo_size = self.sps.log2_min_tb_size();
        let log2_max_trafo_size = self.sps.log2_max_tb_size();

        // Per HEVC spec 7.3.8.7, the order is:
        // 1. split_transform_flag (if applicable)
        // 2. cbf_cb (if applicable)
        // 3. cbf_cr (if applicable)

        // Debug for specific position
        let debug_tt = self.debug_ctu;

        // Step 1: Determine if we should split
        // Per H.265: decode split_transform_flag only when all conditions met AND
        // NOT (IntraSplitFlag && trafoDepth == 0)
        let split_transform = if log2_size <= log2_max_trafo_size
            && log2_size > log2_min_trafo_size
            && trafo_depth < max_trafo_depth
            && !(intra_split_flag && trafo_depth == 0)
        {
            // Decode split_transform_flag
            let ctx_idx = context::SPLIT_TRANSFORM_FLAG + (5 - log2_size as usize).min(2);
            let flag = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
            se_trace("split_transform", flag as i64, &self.cabac);
            flag
        } else if log2_size > log2_max_trafo_size || (intra_split_flag && trafo_depth == 0) {
            true // Must split: larger than max OR IntraSplitFlag at depth 0
        } else {
            if debug_tt {
                debug_trace!(
                    "    TT(1144,120): no split (log2={} min={} max={} depth={} maxdepth={})",
                    log2_size,
                    log2_min_trafo_size,
                    log2_max_trafo_size,
                    trafo_depth,
                    max_trafo_depth
                );
            }
            false
        };

        // Step 2: Decode cbf_cb and cbf_cr
        // For 4:2:0, decode chroma cbf at this level if log2_size > 2
        // cbf_cb/cbf_cr decoded if log2_size > 2 AND (trafoDepth == 0 OR parent cbf is set)
        let (cbf_cb, cbf_cr) = if log2_size > 2 {
            // Decode cbf_cb if trafo_depth == 0 (always) or parent had cbf_cb
            let cb = if trafo_depth == 0 || cbf_cb_parent {
                let ctx_idx = context::CBF_CBCR + trafo_depth as usize;
                let val = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
                se_trace("cbf_cb", val as i64, &self.cabac);
                val
            } else {
                false
            };
            // Decode cbf_cr if trafo_depth == 0 (always) or parent had cbf_cr
            let cr = if trafo_depth == 0 || cbf_cr_parent {
                let ctx_idx = context::CBF_CBCR + trafo_depth as usize;
                let val = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
                se_trace("cbf_cr", val as i64, &self.cabac);
                val
            } else {
                false
            };
            (cb, cr)
        } else {
            // log2_size == 2: inherit from parent (chroma decoded at parent level)
            (cbf_cb_parent, cbf_cr_parent)
        };

        if split_transform {
            let half = 1u32 << (log2_size - 1);
            let new_depth = trafo_depth + 1;
            let new_log2_size = log2_size - 1;

            self.decode_transform_tree_inner(
                x0,
                y0,
                new_log2_size,
                new_depth,
                intra_luma_mode,
                intra_chroma_mode,
                intra_split_flag,
                cbf_cb,
                cbf_cr,
                frame,
            )?;
            self.decode_transform_tree_inner(
                x0 + half,
                y0,
                new_log2_size,
                new_depth,
                intra_luma_mode,
                intra_chroma_mode,
                intra_split_flag,
                cbf_cb,
                cbf_cr,
                frame,
            )?;
            self.decode_transform_tree_inner(
                x0,
                y0 + half,
                new_log2_size,
                new_depth,
                intra_luma_mode,
                intra_chroma_mode,
                intra_split_flag,
                cbf_cb,
                cbf_cr,
                frame,
            )?;
            self.decode_transform_tree_inner(
                x0 + half,
                y0 + half,
                new_log2_size,
                new_depth,
                intra_luma_mode,
                intra_chroma_mode,
                intra_split_flag,
                cbf_cb,
                cbf_cr,
                frame,
            )?;

            // For 4:2:0, if we split from 8x8 to 4x4, predict + decode chroma now
            // (because 4x4 children can't have chroma TUs in 4:2:0).
            // For 4:4:4, each child handles its own chroma — skip this.
            if log2_size == 3 && frame.chroma_format != 3 {
                let sis = self.sps.strong_intra_smoothing_enabled_flag;
                let scan_order = residual::get_scan_order(2, intra_chroma_mode.as_u8(), 1);

                // Predict and apply Cb
                intra::predict_intra(frame, x0 / 2, y0 / 2, 2, intra_chroma_mode, 1, sis);
                if cbf_cb {
                    self.decode_and_apply_residual(x0 / 2, y0 / 2, 2, 1, scan_order, frame)?;
                }

                // Predict and apply Cr
                intra::predict_intra(frame, x0 / 2, y0 / 2, 2, intra_chroma_mode, 2, sis);
                if cbf_cr {
                    self.decode_and_apply_residual(x0 / 2, y0 / 2, 2, 2, scan_order, frame)?;
                }
            }
        } else {
            // Decode transform unit (leaf node)
            self.decode_transform_unit_leaf(
                x0,
                y0,
                log2_size,
                trafo_depth,
                intra_luma_mode,
                intra_chroma_mode,
                cbf_cb,
                cbf_cr,
                frame,
            )?;
        }

        Ok(())
    }

    /// Decode transform unit at leaf node
    ///
    /// Per libde265's decode_TU(): prediction and reconstruction happen PER TU,
    /// so each TU is fully predicted + reconstructed before the next TU starts.
    /// This ensures subsequent TUs read reconstructed neighbor samples (not just
    /// prediction values) for their own intra prediction.
    #[allow(clippy::too_many_arguments)]
    fn decode_transform_unit_leaf(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        trafo_depth: u8,
        _intra_luma_mode: IntraPredMode,
        intra_chroma_mode: IntraPredMode,
        cbf_cb: bool,
        cbf_cr: bool,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        let debug_tt = self.debug_ctu;

        // Decode cbf_luma - per H.265 spec 7.3.8.6:
        // cbf_luma is coded if: CuPredMode == MODE_INTRA || trafoDepth != 0 || cbf_cb || cbf_cr
        // For INTRA mode (all HEIC images), cbf_luma is ALWAYS coded
        // Context: offset 0 if trafo_depth > 0, offset 1 if trafo_depth == 0
        let ctx_offset = if trafo_depth == 0 { 1 } else { 0 };
        let ctx_idx = context::CBF_LUMA + ctx_offset;
        let cbf_luma = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
        se_trace("cbf_luma", cbf_luma as i64, &self.cabac);

        // Per H.265 7.3.8.11: decode cu_qp_delta before residuals
        // Condition: (cbf_luma || cbf_cb || cbf_cr) && cu_qp_delta_enabled_flag && !IsCuQpDeltaCoded
        if (cbf_luma || cbf_cb || cbf_cr)
            && self.pps.cu_qp_delta_enabled_flag
            && !self.is_cu_qp_delta_coded
        {
            let cu_qp_delta_abs = self.decode_cu_qp_delta_abs()?;
            let cu_qp_delta_sign = if cu_qp_delta_abs != 0 {
                self.cabac.decode_bypass()?
            } else {
                0
            };
            self.is_cu_qp_delta_coded = true;
            self.cu_qp_delta = cu_qp_delta_abs as i32 * (1 - 2 * cu_qp_delta_sign as i32);
            se_trace("cu_qp_delta", self.cu_qp_delta as i64, &self.cabac);

            // Re-derive quantization parameters with the actual delta
            let cu_x = self.cu_base_x;
            let cu_y = self.cu_base_y;
            let cu_log2 = self.cu_log2_size;
            self.decode_quantization_parameters(x0, y0, cu_x, cu_y);
            // Store QPY in the QP map for neighbor lookups
            self.store_qpy(cu_x, cu_y, cu_log2, self.current_qpy);
            // Mirror libde265 behavior: once cu_qp_delta is decoded, QPY applies
            // to the whole CU. Re-stamp the deblock QP map so TU leaves decoded
            // earlier in the same CU do not retain stale pre-delta QP values.
            frame.store_block_qp(cu_x, cu_y, 1u32 << cu_log2, self.current_qpy as i8);
        }

        // Mark TU boundary and store QP for deblocking
        let tu_size = 1u32 << log2_size;
        frame.mark_tu_boundary(x0, y0, tu_size);
        frame.store_block_qp(x0, y0, tu_size, self.current_qpy as i8);

        // Look up intra mode at actual TU position (correct for NxN where sub-TUs differ)
        let actual_luma_mode = self.get_intra_mode_at(x0, y0);
        let sis = self.sps.strong_intra_smoothing_enabled_flag;

        // Predict luma at TU level BEFORE residual application
        // This ensures each TU reads reconstructed neighbors from prior TUs
        intra::predict_intra(frame, x0, y0, log2_size, actual_luma_mode, 0, sis);

        let scan_order = residual::get_scan_order(log2_size, actual_luma_mode.as_u8(), 0);

        // Decode and apply luma residuals (adds to prediction already in frame)
        if cbf_luma {
            if debug_tt {
                let (r, o) = self.cabac.get_state();
                debug_trace!(
                    "    TT: decoding luma residual at ({},{}) log2={} (r={},o={})",
                    x0,
                    y0,
                    log2_size,
                    r,
                    o
                );
            }
            self.decode_and_apply_residual(x0, y0, log2_size, 0, scan_order, frame)?;
        }

        // Decode chroma: predict + residual per component if not handled by parent.
        // For 4:2:0: chroma TU is half the luma TU size, minimum 4x4 (log2=2),
        //   so chroma is only decoded here when log2_size >= 3 (8x8+ luma → 4x4+ chroma).
        //   When log2_size < 3, the parent 8x8 node handles chroma.
        // For 4:4:4: chroma TU is the same size as luma, always decoded here.
        let is_444 = frame.chroma_format == 3;
        let chroma_here = if is_444 {
            true // 4:4:4: chroma always at TU level
        } else {
            log2_size >= 3 // 4:2:0: only when luma TU >= 8x8
        };

        if chroma_here {
            let (chroma_log2_size, cx, cy) = if is_444 {
                (log2_size, x0, y0)
            } else {
                (log2_size - 1, x0 / 2, y0 / 2)
            };
            let chroma_scan_order =
                residual::get_scan_order(chroma_log2_size, intra_chroma_mode.as_u8(), 1);

            // Predict and apply Cb
            intra::predict_intra(frame, cx, cy, chroma_log2_size, intra_chroma_mode, 1, sis);
            if cbf_cb {
                self.decode_and_apply_residual(
                    cx,
                    cy,
                    chroma_log2_size,
                    1,
                    chroma_scan_order,
                    frame,
                )?;
            }

            // Predict and apply Cr
            intra::predict_intra(frame, cx, cy, chroma_log2_size, intra_chroma_mode, 2, sis);
            if cbf_cr {
                self.decode_and_apply_residual(
                    cx,
                    cy,
                    chroma_log2_size,
                    2,
                    chroma_scan_order,
                    frame,
                )?;
            }
        }
        // Note: for 4:2:0, if log2_size < 3, chroma was predicted+decoded by parent when splitting from 8x8

        Ok(())
    }

    /// Decode cu_qp_delta_abs per H.265 section 7.3.8.11
    /// TU prefix (up to 5 context-coded bins) + EGk bypass suffix
    fn decode_cu_qp_delta_abs(&mut self) -> Result<u32> {
        let first_bin = self
            .cabac
            .decode_bin(&mut self.ctx[context::CU_QP_DELTA_ABS])?;
        if first_bin == 0 {
            return Ok(0);
        }
        let mut prefix = 1u32;
        for _ in 0..4 {
            let bin = self
                .cabac
                .decode_bin(&mut self.ctx[context::CU_QP_DELTA_ABS + 1])?;
            if bin == 0 {
                break;
            }
            prefix += 1;
        }
        if prefix == 5 {
            // EGk(0) bypass suffix
            let suffix = self.cabac.decode_egk_bypass(0)?;
            Ok(suffix + 5)
        } else {
            Ok(prefix)
        }
    }

    /// Decode residual coefficients and apply to frame
    fn decode_and_apply_residual(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        c_idx: u8,
        scan_order: ScanOrder,
        frame: &mut DecodedFrame,
    ) -> Result<()> {
        // Decode coefficients via CABAC
        let (mut coeff_buf, transform_skip) = residual::decode_residual(
            &mut self.cabac,
            &mut self.ctx,
            log2_size,
            c_idx,
            scan_order,
            self.pps.sign_data_hiding_enabled_flag,
            self.cu_transquant_bypass_flag,
            self.pps.transform_skip_enabled_flag,
            x0,
            y0,
        )?;

        if coeff_buf.is_zero() {
            return Ok(());
        }

        let size = 1usize << log2_size;
        let num_coeffs = size * size;

        // Dequantize coefficients in-place
        let coeffs = &mut coeff_buf.coeffs;

        let (qp, bit_depth) = match c_idx {
            0 => (self.qp_y, self.sps.bit_depth_y()),
            1 => (self.qp_cb, self.sps.bit_depth_c()),
            2 => (self.qp_cr, self.sps.bit_depth_c()),
            _ => (self.qp_y, self.sps.bit_depth_y()),
        };
        let dequant_params = transform::DequantParams {
            qp,
            bit_depth,
            log2_tr_size: log2_size,
        };

        // Use scaling list if enabled (H.265 8.6.3)
        // Per spec: use PPS scaling list if present, else SPS scaling list
        let scaling_list = if self.sps.scaling_list_enabled_flag && !transform_skip {
            self.pps
                .pps_scaling_list
                .as_ref()
                .or(self.sps.scaling_list.as_ref())
        } else {
            None
        };

        if let Some(sl) = scaling_list {
            // matrixId: intra Y=0, Cb=1, Cr=2 (all HEIC is intra)
            let matrix_id = c_idx;
            // Build scaling matrix in raster order for this TU (reuse persistent buffer)
            let scaling_matrix = &mut self.scaling_buf;
            for py in 0..size {
                for px in 0..size {
                    scaling_matrix[py * size + px] =
                        sl.get_scaling_factor(log2_size, matrix_id, px as u32, py as u32);
                }
            }
            transform::dequantize_scaled(
                &mut coeffs[..num_coeffs],
                dequant_params,
                &scaling_matrix[..num_coeffs],
            );
        } else {
            transform::dequantize(&mut coeffs[..num_coeffs], dequant_params);
        }

        // Apply inverse transform (or skip for transform_skip mode)
        // Reuse persistent buffer — transform writes all size*size elements, no zeroing needed
        let residual = &mut self.residual_buf;
        if transform_skip {
            // Per H.265 8.6.4.1 / libde265 transform_skip_residual_fallback():
            // tsShift = 5 + Log2(nTbS)
            // bdShift = max(20 - bit_depth, 0)
            // residual = (coeff << tsShift + rnd) >> bdShift
            let ts_shift = 5 + log2_size as i32;
            let bd_shift = (20 - bit_depth as i32).max(0);
            let rnd = if bd_shift > 0 {
                1i32 << (bd_shift - 1)
            } else {
                0
            };
            for i in 0..num_coeffs {
                let c = (coeffs[i] as i32) << ts_shift;
                residual[i] = ((c + rnd) >> bd_shift) as i16;
            }
        } else {
            let is_intra_4x4_luma = log2_size == 2 && c_idx == 0;
            transform::inverse_transform(coeffs, residual, size, bit_depth, is_intra_4x4_luma);
        }

        // Add residual to prediction — single SIMD dispatch for entire block
        let max_val = (1i32 << bit_depth) - 1;
        let (plane, stride) = frame.plane_mut(c_idx);
        let last_row_end = (y0 as usize + size - 1) * stride + x0 as usize + size;
        if last_row_end <= plane.len() {
            incant!(
                add_residual_block(
                    plane,
                    stride,
                    x0 as usize,
                    y0 as usize,
                    residual,
                    size,
                    max_val
                ),
                [v3]
            );
        } else {
            for py in 0..size {
                let row_start = (y0 as usize + py) * stride + x0 as usize;
                for px in 0..size {
                    let idx = row_start + px;
                    if idx < plane.len() {
                        let pred = plane[idx] as i32;
                        let r = residual[py * size + px] as i32;
                        plane[idx] = (pred + r).clamp(0, max_val) as u16;
                    }
                }
            }
        }

        Ok(())
    }

    /// Decode partition mode
    fn decode_part_mode(&mut self, pred_mode: PredMode, log2_cb_size: u8) -> Result<PartMode> {
        if pred_mode == PredMode::Intra {
            // For intra, first bin distinguishes 2Nx2N from NxN
            let ctx_idx = context::PART_MODE;
            let bin = self.cabac.decode_bin(&mut self.ctx[ctx_idx])?;
            se_trace("part_mode", bin as i64, &self.cabac);

            if bin != 0 {
                Ok(PartMode::Part2Nx2N)
            } else {
                // NxN only allowed at minimum CU size
                if log2_cb_size == self.sps.log2_min_cb_size() {
                    Ok(PartMode::PartNxN)
                } else {
                    Err(HevcError::InvalidBitstream("NxN not allowed at this size"))
                }
            }
        } else {
            // Inter partition modes (not implemented)
            Err(HevcError::Unsupported("inter partition modes"))
        }
    }

    /// Decode intra prediction modes and apply prediction
    /// Returns (luma_mode, chroma_mode)
    fn decode_intra_prediction(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        _apply_chroma: bool,
        frame: &mut DecodedFrame,
    ) -> Result<(IntraPredMode, IntraPredMode)> {
        let (intra_luma_mode, intra_chroma_mode) =
            self.decode_intra_prediction_modes(x0, y0, log2_size, frame)?;

        // Store intra modes in the mode map for neighbor lookups and transform tree
        self.store_intra_mode(x0, y0, log2_size, intra_luma_mode);
        self.store_intra_chroma_mode(x0, y0, log2_size, intra_chroma_mode);

        // NOTE: Prediction is NOT applied here. It happens in decode_transform_unit_leaf
        // and the 8x8→4x4 chroma split handler, so each TU is predicted →
        // reconstructed before the next TU reads its neighbors.

        Ok((intra_luma_mode, intra_chroma_mode))
    }

    /// Decode prev_intra_luma_pred_flag (context-coded bin)
    fn decode_prev_intra_luma_pred_flag(&mut self) -> Result<bool> {
        let ctx_idx = context::PREV_INTRA_LUMA_PRED_FLAG;
        let val = self.cabac.decode_bin(&mut self.ctx[ctx_idx])? != 0;
        se_trace("prev_intra_luma_pred", val as i64, &self.cabac);
        Ok(val)
    }

    /// Derive intra luma mode from prev_flag using neighbor-based MPM candidates
    ///
    /// Looks up left and above neighbors from the intra mode map, with proper
    /// CTB row boundary check for the above neighbor (H.265 8.4.2).
    fn derive_intra_luma_mode(
        &mut self,
        x0: u32,
        y0: u32,
        prev_flag: bool,
    ) -> Result<IntraPredMode> {
        let cand_a = self.get_neighbor_intra_mode_left(x0, y0);
        let cand_b = self.get_neighbor_intra_mode_above(x0, y0);
        let mpm = intra::fill_mpm_candidates(cand_a, cand_b);

        if prev_flag {
            let mpm_idx = self.decode_mpm_idx()?;
            Ok(mpm[mpm_idx as usize])
        } else {
            let rem = self.decode_rem_intra_luma_pred_mode()?;
            Ok(self.map_rem_mode_to_intra(rem, &mpm))
        }
    }

    /// Decode intra luma mode: flag + mpm/rem in one call (for Part2Nx2N)
    fn decode_intra_luma_mode(&mut self, x0: u32, y0: u32) -> Result<IntraPredMode> {
        let prev_flag = self.decode_prev_intra_luma_pred_flag()?;
        self.derive_intra_luma_mode(x0, y0, prev_flag)
    }

    /// Decode intra chroma mode
    /// Per HEVC spec Table 8-2 and libde265 map_chroma_pred_mode():
    /// - First bin (context-coded): if 0 → mode 4 (derived from luma)
    /// - If first bin is 1: read 2 fixed-length bypass bits → modes 0-3
    /// - If candidate mode collides with luma mode → Angular34
    fn decode_intra_chroma_mode(&mut self, luma_mode: IntraPredMode) -> Result<IntraPredMode> {
        let ctx_idx = context::INTRA_CHROMA_PRED_MODE;
        let first_bin = self.cabac.decode_bin(&mut self.ctx[ctx_idx])?;
        if first_bin == 0 {
            // Mode 4: derived from luma
            se_trace("intra_chroma_mode", 4, &self.cabac);
            return Ok(luma_mode);
        }

        // Read 2 fixed-length bypass bits for modes 0-3
        let mode_idx = self.cabac.decode_bypass_bits(2)? as u8;
        se_trace("intra_chroma_mode", mode_idx as i64, &self.cabac);

        let candidate = match mode_idx {
            0 => IntraPredMode::Planar,
            1 => IntraPredMode::Angular26, // Vertical
            2 => IntraPredMode::Angular10, // Horizontal
            _ => IntraPredMode::Dc,        // mode_idx == 3
        };

        // Per Table 8-2: if candidate collides with luma mode, use Angular34
        let intra_chroma_mode = if candidate == luma_mode {
            IntraPredMode::Angular34
        } else {
            candidate
        };

        Ok(intra_chroma_mode)
    }

    /// Decode intra prediction modes (luma + chroma) for Part2Nx2N
    fn decode_intra_prediction_modes(
        &mut self,
        x0: u32,
        y0: u32,
        log2_size: u8,
        _frame: &DecodedFrame,
    ) -> Result<(IntraPredMode, IntraPredMode)> {
        let intra_luma_mode = self.decode_intra_luma_mode(x0, y0)?;

        // DEBUG: Print first few intra modes
        if x0 < 16 && y0 < 16 {
            debug_trace!(
                "DEBUG: intra_mode at ({},{}) size={}: mode={:?}",
                x0,
                y0,
                1u32 << log2_size,
                intra_luma_mode
            );
        }

        let intra_chroma_mode = self.decode_intra_chroma_mode(intra_luma_mode)?;

        Ok((intra_luma_mode, intra_chroma_mode))
    }

    /// Get min PU size (= min_cb_size / 2, at least 1)
    fn min_pu_size(&self) -> u32 {
        ((1u32 << self.sps.log2_min_cb_size()) / 2).max(1)
    }

    /// Store intra luma mode for a region (in min_pu_size units)
    fn store_intra_mode(&mut self, x0: u32, y0: u32, log2_size: u8, mode: IntraPredMode) {
        let min_pu = self.min_pu_size();
        let stride = self.intra_mode_map_stride;
        let count = ((1u32 << log2_size) / min_pu).max(1);
        let start_x = x0 / min_pu;
        let start_y = y0 / min_pu;
        for dy in 0..count {
            for dx in 0..count {
                let idx = ((start_y + dy) * stride + (start_x + dx)) as usize;
                if idx < self.intra_mode_map.len() {
                    self.intra_mode_map[idx] = mode.as_u8();
                }
            }
        }
    }

    /// Store intra chroma mode for a region (in min_pu_size units)
    fn store_intra_chroma_mode(&mut self, x0: u32, y0: u32, log2_size: u8, mode: IntraPredMode) {
        let min_pu = self.min_pu_size();
        let stride = self.intra_mode_map_stride;
        let count = ((1u32 << log2_size) / min_pu).max(1);
        let start_x = x0 / min_pu;
        let start_y = y0 / min_pu;
        for dy in 0..count {
            for dx in 0..count {
                let idx = ((start_y + dy) * stride + (start_x + dx)) as usize;
                if idx < self.intra_chroma_mode_map.len() {
                    self.intra_chroma_mode_map[idx] = mode.as_u8();
                }
            }
        }
    }

    /// Get intra luma prediction mode at a sample position
    fn get_intra_mode_at(&self, x: u32, y: u32) -> IntraPredMode {
        let min_pu = self.min_pu_size();
        let stride = self.intra_mode_map_stride;
        let idx = ((y / min_pu) * stride + (x / min_pu)) as usize;
        if idx < self.intra_mode_map.len() {
            IntraPredMode::from_u8(self.intra_mode_map[idx]).unwrap_or(IntraPredMode::Dc)
        } else {
            IntraPredMode::Dc
        }
    }

    /// Get intra chroma prediction mode at a sample position
    #[allow(dead_code)]
    fn get_intra_chroma_mode_at(&self, x: u32, y: u32) -> IntraPredMode {
        let min_pu = self.min_pu_size();
        let stride = self.intra_mode_map_stride;
        let idx = ((y / min_pu) * stride + (x / min_pu)) as usize;
        if idx < self.intra_chroma_mode_map.len() {
            IntraPredMode::from_u8(self.intra_chroma_mode_map[idx]).unwrap_or(IntraPredMode::Dc)
        } else {
            IntraPredMode::Dc
        }
    }

    /// Get intra prediction mode of the left neighbor (x0-1, y0)
    ///
    /// Returns DC if the left neighbor is outside the picture boundary.
    fn get_neighbor_intra_mode_left(&self, x0: u32, y0: u32) -> IntraPredMode {
        if x0 == 0 {
            return IntraPredMode::Dc;
        }
        self.get_intra_mode_at(x0 - 1, y0)
    }

    /// Get intra prediction mode of the above neighbor (x0, y0-1)
    ///
    /// Returns DC if:
    /// - The above neighbor is outside the picture boundary (y0 == 0)
    /// - The above neighbor is in a different CTB row (H.265 8.4.2 / libde265 intrapred.cc:107-109)
    fn get_neighbor_intra_mode_above(&self, x0: u32, y0: u32) -> IntraPredMode {
        if y0 == 0 {
            return IntraPredMode::Dc;
        }
        // CTB row boundary check: if the above sample is in a different CTB row, use DC
        // This implements: y-1 < ((y >> Log2CtbSizeY) << Log2CtbSizeY)
        let ctb_size = self.sps.ctb_size();
        let ctb_y_start = (y0 / ctb_size) * ctb_size;
        if y0 - 1 < ctb_y_start {
            return IntraPredMode::Dc;
        }
        self.get_intra_mode_at(x0, y0 - 1)
    }

    /// Map rem_intra_luma_pred_mode to actual mode (excluding MPM candidates)
    fn map_rem_mode_to_intra(&self, rem: u32, mpm: &[IntraPredMode; 3]) -> IntraPredMode {
        // Sort MPM candidates
        let mut mpm_vals = [mpm[0].as_u8(), mpm[1].as_u8(), mpm[2].as_u8()];
        mpm_vals.sort_unstable();

        // Map remaining mode
        let mut mode = rem as u8;
        for &mpm_val in &mpm_vals {
            if mode >= mpm_val {
                mode += 1;
            }
        }

        IntraPredMode::from_u8(mode).unwrap_or(IntraPredMode::Dc)
    }

    /// Decode mpm_idx (0, 1, or 2)
    fn decode_mpm_idx(&mut self) -> Result<u8> {
        // Truncated unary: 0, 10, 11
        let val = if self.cabac.decode_bypass()? == 0 {
            0
        } else if self.cabac.decode_bypass()? == 0 {
            1
        } else {
            2
        };
        se_trace("mpm_idx", val as i64, &self.cabac);
        Ok(val)
    }

    /// Decode rem_intra_luma_pred_mode (5 bits)
    fn decode_rem_intra_luma_pred_mode(&mut self) -> Result<u32> {
        let mut val = 0u32;
        for _ in 0..5 {
            val = (val << 1) | self.cabac.decode_bypass()? as u32;
        }
        se_trace("rem_intra_luma", val as i64, &self.cabac);
        Ok(val)
    }

    /// H.265 Table 8-6: chroma QP mapping for 4:2:0
    fn chroma_qp_from_luma(qpi: i32) -> i32 {
        static TAB8_22: [i32; 13] = [29, 30, 31, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37];
        if qpi < 30 {
            qpi
        } else if qpi >= 43 {
            qpi - 6
        } else {
            TAB8_22[(qpi - 30) as usize]
        }
    }

    /// Get QPY at a sample position from the QP map
    fn get_qpy_at(&self, x: u32, y: u32) -> i32 {
        let min_tb = 1u32 << self.sps.log2_min_tb_size();
        let idx = ((y / min_tb) * self.qp_map_stride + (x / min_tb)) as usize;
        if idx < self.qp_map.len() {
            self.qp_map[idx] as i32
        } else {
            self.header.slice_qp_y
        }
    }

    /// Store QPY for a CU region in the QP map
    fn store_qpy(&mut self, x0: u32, y0: u32, log2_cb_size: u8, qpy: i32) {
        let min_tb = 1u32 << self.sps.log2_min_tb_size();
        let count = ((1u32 << log2_cb_size) / min_tb).max(1);
        let start_x = x0 / min_tb;
        let start_y = y0 / min_tb;
        for dy in 0..count {
            for dx in 0..count {
                let idx = ((start_y + dy) * self.qp_map_stride + (start_x + dx)) as usize;
                if idx < self.qp_map.len() {
                    self.qp_map[idx] = qpy as i8;
                }
            }
        }
    }

    /// Decode quantization parameters (H.265 section 8.6.1)
    /// Matching libde265's decode_quantization_parameters()
    fn decode_quantization_parameters(
        &mut self,
        x0: u32,
        _y0: u32,
        x_cu_base: u32,
        y_cu_base: u32,
    ) {
        let log2_min_cu_qp_delta_size = self.sps.log2_ctb_size() - self.pps.diff_cu_qp_delta_depth;
        let qg_mask = (1u32 << log2_min_cu_qp_delta_size) - 1;

        // Top-left pixel of current quantization group
        let x_qg = (x_cu_base & !qg_mask) as i32;
        let y_qg = (y_cu_base & !qg_mask) as i32;

        // Track QG transitions
        if x_qg != self.current_qg_x || y_qg != self.current_qg_y {
            self.last_qpy_in_prev_qg = self.current_qpy;
            self.current_qg_x = x_qg;
            self.current_qg_y = y_qg;
        }

        // Determine QP prediction
        let ctb_mask = ((1u32 << self.sps.log2_ctb_size()) - 1) as i32;
        let first_in_ctb_row = x_qg == 0 && (y_qg & ctb_mask) == 0;

        let first_ctb_in_slice = self.header.slice_segment_address;
        let slice_start_x = (first_ctb_in_slice % self.sps.pic_width_in_ctbs()) as i32
            * (1 << self.sps.log2_ctb_size());
        let slice_start_y = (first_ctb_in_slice / self.sps.pic_width_in_ctbs()) as i32
            * (1 << self.sps.log2_ctb_size());
        let first_qg_in_slice = slice_start_x == x_qg && slice_start_y == y_qg;

        let qp_y_pred = if first_qg_in_slice
            || (first_in_ctb_row && self.pps.entropy_coding_sync_enabled_flag)
        {
            self.header.slice_qp_y
        } else {
            self.last_qpy_in_prev_qg
        };

        // Get neighbor QP values for averaging
        let qp_y_a = if x_qg > 0 {
            // Check if left neighbor is in same CTB
            let left_x = (x_qg - 1) as u32;
            let left_y = y_qg as u32;
            // Simplified: check if in same CTB
            let ctb_size = self.sps.ctb_size();
            let our_ctb_x = x0 / ctb_size;
            let left_ctb_x = left_x / ctb_size;
            if our_ctb_x == left_ctb_x || (x_qg as u32) < ctb_size {
                // Left neighbor might be in previous CTB, use prediction
                if left_ctb_x == self.ctb_x {
                    self.get_qpy_at(left_x, left_y)
                } else {
                    qp_y_pred
                }
            } else {
                qp_y_pred
            }
        } else {
            qp_y_pred
        };

        let qp_y_b = if y_qg > 0 {
            let above_x = x_qg as u32;
            let above_y = (y_qg - 1) as u32;
            let ctb_size = self.sps.ctb_size();
            let above_ctb_y = above_y / ctb_size;
            if above_ctb_y == self.ctb_y {
                self.get_qpy_at(above_x, above_y)
            } else {
                qp_y_pred
            }
        } else {
            qp_y_pred
        };

        let qp_y_pred = (qp_y_a + qp_y_b + 1) >> 1;

        // Compute final QPY
        let qp_bd_offset_y = 6 * (self.sps.bit_depth_y() as i32 - 8);
        let qpy = ((qp_y_pred + self.cu_qp_delta + 52 + 2 * qp_bd_offset_y)
            % (52 + qp_bd_offset_y))
            - qp_bd_offset_y;

        self.qp_y = qpy + qp_bd_offset_y;
        if self.qp_y < 0 {
            self.qp_y = 0;
        }

        // Compute chroma QP (4:2:0)
        let qp_bd_offset_c = 6 * (self.sps.bit_depth_c() as i32 - 8);
        let qpi_cb =
            (qpy + self.pps.pps_cb_qp_offset as i32 + self.header.slice_cb_qp_offset as i32)
                .clamp(-qp_bd_offset_c, 57);
        let qpi_cr =
            (qpy + self.pps.pps_cr_qp_offset as i32 + self.header.slice_cr_qp_offset as i32)
                .clamp(-qp_bd_offset_c, 57);

        self.qp_cb = Self::chroma_qp_from_luma(qpi_cb) + qp_bd_offset_c;
        self.qp_cr = Self::chroma_qp_from_luma(qpi_cr) + qp_bd_offset_c;

        self.current_qpy = qpy;
    }
}
