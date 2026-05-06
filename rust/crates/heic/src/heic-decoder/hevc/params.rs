//! HEVC parameter set parsing (VPS, SPS, PPS)

use alloc::string::ToString;
use alloc::vec::Vec;

use super::bitstream::BitstreamReader;
use crate::heic_decoder::error::HevcError;

type Result<T> = core::result::Result<T, HevcError>;

/// Video Parameter Set
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct Vps {
    /// VPS ID
    pub vps_id: u8,
    /// Base layer internal flag
    pub base_layer_internal_flag: bool,
    /// Base layer available flag
    pub base_layer_available_flag: bool,
    /// Max layers minus 1
    pub max_layers_minus1: u8,
    /// Max sub-layers minus 1
    pub max_sub_layers_minus1: u8,
    /// Temporal ID nesting flag
    pub temporal_id_nesting_flag: bool,
    /// Profile tier level
    pub ptl: ProfileTierLevel,
}

/// Sequence Parameter Set
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct Sps {
    /// SPS ID
    pub sps_id: u8,
    /// VPS ID
    pub vps_id: u8,
    /// Max sub-layers minus 1
    pub max_sub_layers_minus1: u8,
    /// Temporal ID nesting flag
    pub temporal_id_nesting_flag: bool,
    /// Profile tier level
    pub ptl: ProfileTierLevel,
    /// Chroma format IDC (0=monochrome, 1=4:2:0, 2=4:2:2, 3=4:4:4)
    pub chroma_format_idc: u8,
    /// Separate color plane flag
    pub separate_colour_plane_flag: bool,
    /// Picture width in luma samples
    pub pic_width_in_luma_samples: u32,
    /// Picture height in luma samples
    pub pic_height_in_luma_samples: u32,
    /// Conformance window flag
    pub conformance_window_flag: bool,
    /// Conformance window offsets (left, right, top, bottom)
    pub conf_win_offset: (u32, u32, u32, u32),
    /// Bit depth luma minus 8
    pub bit_depth_luma_minus8: u8,
    /// Bit depth chroma minus 8
    pub bit_depth_chroma_minus8: u8,
    /// Log2 max POC LSB minus 4
    pub log2_max_pic_order_cnt_lsb_minus4: u8,
    /// Sub-layer ordering info present flag
    pub sub_layer_ordering_info_present_flag: bool,
    /// Log2 min luma coding block size minus 3
    pub log2_min_luma_coding_block_size_minus3: u8,
    /// Log2 diff max min luma coding block size
    pub log2_diff_max_min_luma_coding_block_size: u8,
    /// Log2 min luma transform block size minus 2
    pub log2_min_luma_transform_block_size_minus2: u8,
    /// Log2 diff max min luma transform block size
    pub log2_diff_max_min_luma_transform_block_size: u8,
    /// Max transform hierarchy depth inter
    pub max_transform_hierarchy_depth_inter: u8,
    /// Max transform hierarchy depth intra
    pub max_transform_hierarchy_depth_intra: u8,
    /// Scaling list enabled flag
    pub scaling_list_enabled_flag: bool,
    /// Scaling list data (if enabled)
    pub scaling_list: Option<ScalingListData>,
    /// AMP enabled flag
    pub amp_enabled_flag: bool,
    /// SAO enabled flag
    pub sample_adaptive_offset_enabled_flag: bool,
    /// PCM enabled flag
    pub pcm_enabled_flag: bool,
    /// PCM parameters (if enabled)
    pub pcm_params: Option<PcmParams>,
    /// Number of short-term reference picture sets
    pub num_short_term_ref_pic_sets: u8,
    /// Long-term reference pictures present flag
    pub long_term_ref_pics_present_flag: bool,
    /// Temporal MVP enabled flag
    pub sps_temporal_mvp_enabled_flag: bool,
    /// Strong intra smoothing enabled flag
    pub strong_intra_smoothing_enabled_flag: bool,
    /// VUI parameters present flag
    pub vui_parameters_present_flag: bool,
    /// Video full range flag (from VUI). true = full \[0,255\], false = limited \[16,235\]
    pub video_full_range_flag: bool,
    /// Matrix coefficients (from VUI). 1=BT.709, 5/6=BT.601, 9=BT.2020
    pub matrix_coeffs: u8,
}

impl Sps {
    /// Get ChromaArrayType
    pub fn chroma_array_type(&self) -> u8 {
        if self.separate_colour_plane_flag {
            0
        } else {
            self.chroma_format_idc
        }
    }

    /// Get bit depth for luma
    pub fn bit_depth_y(&self) -> u8 {
        8 + self.bit_depth_luma_minus8
    }

    /// Get bit depth for chroma
    pub fn bit_depth_c(&self) -> u8 {
        8 + self.bit_depth_chroma_minus8
    }

    /// Get log2 of min coding block size
    pub fn log2_min_cb_size(&self) -> u8 {
        self.log2_min_luma_coding_block_size_minus3 + 3
    }

    /// Get log2 of max coding block size (CTB size)
    pub fn log2_ctb_size(&self) -> u8 {
        self.log2_min_cb_size() + self.log2_diff_max_min_luma_coding_block_size
    }

    /// Get CTB size in samples
    pub fn ctb_size(&self) -> u32 {
        1 << self.log2_ctb_size()
    }

    /// Get picture width in CTBs
    pub fn pic_width_in_ctbs(&self) -> u32 {
        self.pic_width_in_luma_samples.div_ceil(self.ctb_size())
    }

    /// Get picture height in CTBs
    pub fn pic_height_in_ctbs(&self) -> u32 {
        self.pic_height_in_luma_samples.div_ceil(self.ctb_size())
    }

    /// Get log2 of min transform block size
    pub fn log2_min_tb_size(&self) -> u8 {
        self.log2_min_luma_transform_block_size_minus2 + 2
    }

    /// Get log2 of max transform block size
    pub fn log2_max_tb_size(&self) -> u8 {
        self.log2_min_tb_size() + self.log2_diff_max_min_luma_transform_block_size
    }
}

/// PCM parameters
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct PcmParams {
    /// PCM sample bit depth luma minus 1
    pub pcm_sample_bit_depth_luma_minus1: u8,
    /// PCM sample bit depth chroma minus 1
    pub pcm_sample_bit_depth_chroma_minus1: u8,
    /// Log2 min PCM luma coding block size minus 3
    pub log2_min_pcm_luma_coding_block_size_minus3: u8,
    /// Log2 diff max min PCM luma coding block size
    pub log2_diff_max_min_pcm_luma_coding_block_size: u8,
    /// PCM loop filter disabled flag
    pub pcm_loop_filter_disabled_flag: bool,
}

/// HEVC scaling list data (H.265 7.3.4)
///
/// Stores per-coefficient scaling factors for dequantization.
/// sizeId: 0=4x4, 1=8x8, 2=16x16, 3=32x32
/// matrixId: 0-2=intra(Y,Cb,Cr), 3-5=inter(Y,Cb,Cr)
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct ScalingListData {
    /// ScalingList coefficients in diagonal scan order.
    /// \[sizeId\]\[matrixId\]\[coef_index\]
    /// sizeId 0: 16 coefficients, sizeId 1-3: 64 coefficients
    pub lists: [[[u8; 64]; 6]; 4],
    /// DC coefficients for 16x16 (sizeId=2) and 32x32 (sizeId=3)
    /// Index 0 = sizeId 2, index 1 = sizeId 3
    pub dc_coef: [[u8; 6]; 2],
}

impl Default for ScalingListData {
    fn default() -> Self {
        Self::new_default()
    }
}

impl ScalingListData {
    /// Create scaling list with H.265 default values (Tables 7-5, 7-6)
    pub fn new_default() -> Self {
        let mut data = Self {
            lists: [[[16; 64]; 6]; 4],
            dc_coef: [[16; 6]; 2],
        };

        // Table 7-5: 4x4 default is all 16s (already set)

        // Table 7-6: 8x8/16x16/32x32 defaults
        // Intra (matrixId 0,1,2)
        #[rustfmt::skip]
        const DEFAULT_INTRA_8X8: [u8; 64] = [
            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 16, 17, 16, 17, 18,
            17, 18, 18, 17, 18, 21, 19, 20, 21, 20, 19, 21, 24, 22, 22, 24,
            24, 22, 22, 24, 25, 25, 27, 30, 27, 25, 25, 29, 31, 35, 35, 31,
            29, 36, 41, 44, 41, 36, 47, 54, 54, 47, 65, 70, 65, 88, 88, 115,
        ];
        // Inter (matrixId 3,4,5)
        #[rustfmt::skip]
        const DEFAULT_INTER_8X8: [u8; 64] = [
            16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 18,
            18, 18, 18, 18, 18, 20, 20, 20, 20, 20, 20, 20, 24, 24, 24, 24,
            24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 28, 28, 28, 28, 28,
            28, 33, 33, 33, 33, 33, 41, 41, 41, 41, 54, 54, 54, 71, 71, 91,
        ];

        for size_id in 1..4 {
            for matrix_id in 0..3 {
                data.lists[size_id][matrix_id] = DEFAULT_INTRA_8X8;
            }
            for matrix_id in 3..6 {
                data.lists[size_id][matrix_id] = DEFAULT_INTER_8X8;
            }
        }

        data
    }

    /// Create flat scaling list (all 16s) — equivalent to scaling_list_enabled_flag=0
    #[allow(dead_code)]
    pub fn new_flat() -> Self {
        Self {
            lists: [[[16; 64]; 6]; 4],
            dc_coef: [[16; 6]; 2],
        }
    }

    /// Get the scaling factor m\[x\]\[y\] for a given transform block.
    ///
    /// `log2_size`: log2 of transform block size (2=4x4, 3=8x8, 4=16x16, 5=32x32)
    /// `matrix_id`: from Table 7-4 (intra Y=0, intra Cb=1, intra Cr=2, inter Y=3, etc.)
    /// `x`, `y`: position within the transform block
    #[inline]
    pub fn get_scaling_factor(&self, log2_size: u8, matrix_id: u8, x: u32, y: u32) -> u8 {
        let size_id = (log2_size - 2) as usize;
        let mid = matrix_id as usize;

        match size_id {
            0 => {
                // 4x4: direct lookup via diagonal scan
                let idx = DIAG_SCAN_4X4_INV[y as usize][x as usize];
                self.lists[0][mid][idx]
            }
            1 => {
                // 8x8: direct lookup via diagonal scan
                let idx = DIAG_SCAN_8X8_INV[y as usize][x as usize];
                self.lists[1][mid][idx]
            }
            2 => {
                // 16x16: upscale from 8x8, DC override at (0,0)
                if x == 0 && y == 0 {
                    return self.dc_coef[0][mid];
                }
                let rx = (x / 2) as usize;
                let ry = (y / 2) as usize;
                let idx = DIAG_SCAN_8X8_INV[ry][rx];
                self.lists[2][mid][idx]
            }
            3 => {
                // 32x32: upscale from 8x8, DC override at (0,0)
                if x == 0 && y == 0 {
                    return self.dc_coef[1][mid];
                }
                let rx = (x / 4) as usize;
                let ry = (y / 4) as usize;
                let idx = DIAG_SCAN_8X8_INV[ry][rx];
                self.lists[3][mid][idx]
            }
            _ => 16,
        }
    }
}

/// Inverse diagonal scan for 4x4: DIAG_SCAN_4X4_INV[y][x] = scan_index
#[rustfmt::skip]
static DIAG_SCAN_4X4_INV: [[usize; 4]; 4] = [
    [ 0,  1,  3,  6],
    [ 2,  4,  7, 10],
    [ 5,  8, 11, 13],
    [ 9, 12, 14, 15],
];

/// Inverse diagonal scan for 8x8: DIAG_SCAN_8X8_INV[y][x] = scan_index
#[rustfmt::skip]
static DIAG_SCAN_8X8_INV: [[usize; 8]; 8] = [
    [ 0,  1,  3,  6, 10, 15, 21, 28],
    [ 2,  4,  7, 11, 16, 22, 29, 36],
    [ 5,  8, 12, 17, 23, 30, 37, 43],
    [ 9, 13, 18, 24, 31, 38, 44, 49],
    [14, 19, 25, 32, 39, 45, 50, 54],
    [20, 26, 33, 40, 46, 51, 55, 58],
    [27, 34, 41, 47, 52, 56, 59, 61],
    [35, 42, 48, 53, 57, 60, 62, 63],
];

/// Picture Parameter Set
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct Pps {
    /// PPS ID
    pub pps_id: u8,
    /// SPS ID
    pub sps_id: u8,
    /// Dependent slice segments enabled flag
    pub dependent_slice_segments_enabled_flag: bool,
    /// Output flag present flag
    pub output_flag_present_flag: bool,
    /// Num extra slice header bits
    pub num_extra_slice_header_bits: u8,
    /// Sign data hiding enabled flag
    pub sign_data_hiding_enabled_flag: bool,
    /// Cabac init present flag
    pub cabac_init_present_flag: bool,
    /// Num ref idx L0 default active minus 1
    pub num_ref_idx_l0_default_active_minus1: u8,
    /// Num ref idx L1 default active minus 1
    pub num_ref_idx_l1_default_active_minus1: u8,
    /// Init QP minus 26
    pub init_qp_minus26: i8,
    /// Constrained intra pred flag
    pub constrained_intra_pred_flag: bool,
    /// Transform skip enabled flag
    pub transform_skip_enabled_flag: bool,
    /// CU QP delta enabled flag
    pub cu_qp_delta_enabled_flag: bool,
    /// Diff CU QP delta depth
    pub diff_cu_qp_delta_depth: u8,
    /// Cb QP offset
    pub pps_cb_qp_offset: i8,
    /// Cr QP offset
    pub pps_cr_qp_offset: i8,
    /// Slice chroma QP offsets present flag
    pub pps_slice_chroma_qp_offsets_present_flag: bool,
    /// Weighted pred flag
    pub weighted_pred_flag: bool,
    /// Weighted bipred flag
    pub weighted_bipred_flag: bool,
    /// Transquant bypass enabled flag
    pub transquant_bypass_enabled_flag: bool,
    /// Tiles enabled flag
    pub tiles_enabled_flag: bool,
    /// Entropy coding sync enabled flag
    pub entropy_coding_sync_enabled_flag: bool,
    /// Tile info (if tiles enabled)
    pub tile_info: Option<TileInfo>,
    /// Loop filter across slices enabled flag
    pub pps_loop_filter_across_slices_enabled_flag: bool,
    /// Deblocking filter control present flag
    pub deblocking_filter_control_present_flag: bool,
    /// Deblocking filter override enabled flag
    pub deblocking_filter_override_enabled_flag: bool,
    /// Deblocking filter disabled flag
    pub pps_deblocking_filter_disabled_flag: bool,
    /// Beta offset div2
    pub pps_beta_offset_div2: i8,
    /// Tc offset div2
    pub pps_tc_offset_div2: i8,
    /// Scaling list data present flag
    pub pps_scaling_list_data_present_flag: bool,
    /// PPS scaling list data (if present, overrides SPS scaling list)
    pub pps_scaling_list: Option<ScalingListData>,
    /// Lists modification present flag
    pub lists_modification_present_flag: bool,
    /// Log2 parallel merge level minus 2
    pub log2_parallel_merge_level_minus2: u8,
    /// Slice segment header extension present flag
    pub slice_segment_header_extension_present_flag: bool,
}

/// Tile configuration
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct TileInfo {
    /// Number of tile columns minus 1
    pub num_tile_columns_minus1: u16,
    /// Number of tile rows minus 1
    pub num_tile_rows_minus1: u16,
    /// Uniform spacing flag
    pub uniform_spacing_flag: bool,
    /// Column widths (if not uniform)
    pub column_widths: Vec<u16>,
    /// Row heights (if not uniform)
    pub row_heights: Vec<u16>,
    /// Loop filter across tiles enabled flag
    pub loop_filter_across_tiles_enabled_flag: bool,
}

/// Profile tier level information
#[allow(dead_code)]
#[derive(Debug, Clone, Default)]
pub struct ProfileTierLevel {
    /// General profile space
    pub general_profile_space: u8,
    /// General tier flag
    pub general_tier_flag: bool,
    /// General profile IDC
    pub general_profile_idc: u8,
    /// General profile compatibility flags
    pub general_profile_compatibility_flag: [bool; 32],
    /// General progressive source flag
    pub general_progressive_source_flag: bool,
    /// General interlaced source flag
    pub general_interlaced_source_flag: bool,
    /// General non-packed constraint flag
    pub general_non_packed_constraint_flag: bool,
    /// General frame only constraint flag
    pub general_frame_only_constraint_flag: bool,
    /// General level IDC
    pub general_level_idc: u8,
}

/// Parse Video Parameter Set
pub fn parse_vps(data: &[u8]) -> Result<Vps> {
    let mut reader = BitstreamReader::new(data);

    let vps_id = reader.read_bits(4)? as u8;
    let base_layer_internal_flag = reader.read_bit()? != 0;
    let base_layer_available_flag = reader.read_bit()? != 0;
    let max_layers_minus1 = reader.read_bits(6)? as u8;
    let max_sub_layers_minus1 = reader.read_bits(3)? as u8;
    let temporal_id_nesting_flag = reader.read_bit()? != 0;

    // vps_reserved_0xffff_16bits
    let reserved = reader.read_bits(16)?;
    if reserved != 0xFFFF {
        return Err(HevcError::InvalidParameterSet {
            kind: "VPS",
            msg: "invalid reserved bits".to_string(),
        });
    }

    let ptl = parse_profile_tier_level(&mut reader, true, max_sub_layers_minus1)?;

    Ok(Vps {
        vps_id,
        base_layer_internal_flag,
        base_layer_available_flag,
        max_layers_minus1,
        max_sub_layers_minus1,
        temporal_id_nesting_flag,
        ptl,
    })
}

/// Parse Sequence Parameter Set
pub fn parse_sps(data: &[u8]) -> Result<Sps> {
    let mut reader = BitstreamReader::new(data);

    let vps_id = reader.read_bits(4)? as u8;
    let max_sub_layers_minus1 = reader.read_bits(3)? as u8;
    let temporal_id_nesting_flag = reader.read_bit()? != 0;

    let ptl = parse_profile_tier_level(&mut reader, true, max_sub_layers_minus1)?;

    let sps_id = reader.read_ue()? as u8;
    let chroma_format_idc = reader.read_ue()? as u8;

    let separate_colour_plane_flag = if chroma_format_idc == 3 {
        reader.read_bit()? != 0
    } else {
        false
    };

    let pic_width_in_luma_samples = reader.read_ue()?;
    let pic_height_in_luma_samples = reader.read_ue()?;

    let conformance_window_flag = reader.read_bit()? != 0;
    let conf_win_offset = if conformance_window_flag {
        let left = reader.read_ue()?;
        let right = reader.read_ue()?;
        let top = reader.read_ue()?;
        let bottom = reader.read_ue()?;
        (left, right, top, bottom)
    } else {
        (0, 0, 0, 0)
    };

    let bit_depth_luma_minus8 = reader.read_ue()? as u8;
    let bit_depth_chroma_minus8 = reader.read_ue()? as u8;
    let log2_max_pic_order_cnt_lsb_minus4 = reader.read_ue()? as u8;

    let sub_layer_ordering_info_present_flag = reader.read_bit()? != 0;

    // Skip sub-layer ordering info
    let start = if sub_layer_ordering_info_present_flag {
        0
    } else {
        max_sub_layers_minus1
    };
    for _ in start..=max_sub_layers_minus1 {
        let _max_dec_pic_buffering_minus1 = reader.read_ue()?;
        let _max_num_reorder_pics = reader.read_ue()?;
        let _max_latency_increase_plus1 = reader.read_ue()?;
    }

    let log2_min_luma_coding_block_size_minus3 = reader.read_ue()? as u8;
    let log2_diff_max_min_luma_coding_block_size = reader.read_ue()? as u8;
    let log2_min_luma_transform_block_size_minus2 = reader.read_ue()? as u8;
    let log2_diff_max_min_luma_transform_block_size = reader.read_ue()? as u8;
    let max_transform_hierarchy_depth_inter = reader.read_ue()? as u8;
    let max_transform_hierarchy_depth_intra = reader.read_ue()? as u8;

    let scaling_list_enabled_flag = reader.read_bit()? != 0;
    let scaling_list = if scaling_list_enabled_flag {
        let scaling_list_data_present = reader.read_bit()? != 0;
        if scaling_list_data_present {
            Some(parse_scaling_list_data(&mut reader)?)
        } else {
            // Use H.265 default scaling matrices
            Some(ScalingListData::new_default())
        }
    } else {
        None
    };

    let amp_enabled_flag = reader.read_bit()? != 0;
    let sample_adaptive_offset_enabled_flag = reader.read_bit()? != 0;

    let pcm_enabled_flag = reader.read_bit()? != 0;
    let pcm_params = if pcm_enabled_flag {
        let pcm_sample_bit_depth_luma_minus1 = reader.read_bits(4)? as u8;
        let pcm_sample_bit_depth_chroma_minus1 = reader.read_bits(4)? as u8;
        let log2_min_pcm_luma_coding_block_size_minus3 = reader.read_ue()? as u8;
        let log2_diff_max_min_pcm_luma_coding_block_size = reader.read_ue()? as u8;
        let pcm_loop_filter_disabled_flag = reader.read_bit()? != 0;
        Some(PcmParams {
            pcm_sample_bit_depth_luma_minus1,
            pcm_sample_bit_depth_chroma_minus1,
            log2_min_pcm_luma_coding_block_size_minus3,
            log2_diff_max_min_pcm_luma_coding_block_size,
            pcm_loop_filter_disabled_flag,
        })
    } else {
        None
    };

    let num_short_term_ref_pic_sets = reader.read_ue()? as u8;
    // Skip short term ref pic sets (not needed for still images)
    for i in 0..num_short_term_ref_pic_sets {
        skip_short_term_ref_pic_set(&mut reader, i, num_short_term_ref_pic_sets)?;
    }

    let long_term_ref_pics_present_flag = reader.read_bit()? != 0;
    if long_term_ref_pics_present_flag {
        let num_long_term_ref_pics_sps = reader.read_ue()?;
        for _ in 0..num_long_term_ref_pics_sps {
            let _lt_ref_pic_poc_lsb_sps =
                reader.read_bits(log2_max_pic_order_cnt_lsb_minus4 + 4)?;
            let _used_by_curr_pic_lt_sps_flag = reader.read_bit()?;
        }
    }

    let sps_temporal_mvp_enabled_flag = reader.read_bit()? != 0;
    let strong_intra_smoothing_enabled_flag = reader.read_bit()? != 0;

    let vui_parameters_present_flag = reader.read_bit()? != 0;

    // Parse VUI color parameters if present
    let mut video_full_range_flag = false; // default: limited range
    let mut matrix_coeffs = 2u8; // default: unspecified
    if vui_parameters_present_flag {
        let aspect_ratio_info_present = reader.read_bit()? != 0;
        if aspect_ratio_info_present {
            let aspect_ratio_idc = reader.read_bits(8)?;
            if aspect_ratio_idc == 255 {
                // Extended_SAR
                let _sar_width = reader.read_bits(16)?;
                let _sar_height = reader.read_bits(16)?;
            }
        }
        let overscan_info_present = reader.read_bit()? != 0;
        if overscan_info_present {
            let _overscan_appropriate = reader.read_bit()?;
        }
        let video_signal_type_present = reader.read_bit()? != 0;
        if video_signal_type_present {
            let _video_format = reader.read_bits(3)?;
            video_full_range_flag = reader.read_bit()? != 0;
            let colour_description_present = reader.read_bit()? != 0;
            if colour_description_present {
                let _colour_primaries = reader.read_bits(8)?;
                let _transfer_characteristics = reader.read_bits(8)?;
                matrix_coeffs = reader.read_bits(8)? as u8;
            }
        }
        // Don't parse the rest of VUI — we only need color info
    }

    Ok(Sps {
        sps_id,
        vps_id,
        max_sub_layers_minus1,
        temporal_id_nesting_flag,
        ptl,
        chroma_format_idc,
        separate_colour_plane_flag,
        pic_width_in_luma_samples,
        pic_height_in_luma_samples,
        conformance_window_flag,
        conf_win_offset,
        bit_depth_luma_minus8,
        bit_depth_chroma_minus8,
        log2_max_pic_order_cnt_lsb_minus4,
        sub_layer_ordering_info_present_flag,
        log2_min_luma_coding_block_size_minus3,
        log2_diff_max_min_luma_coding_block_size,
        log2_min_luma_transform_block_size_minus2,
        log2_diff_max_min_luma_transform_block_size,
        max_transform_hierarchy_depth_inter,
        max_transform_hierarchy_depth_intra,
        scaling_list_enabled_flag,
        scaling_list,
        amp_enabled_flag,
        sample_adaptive_offset_enabled_flag,
        pcm_enabled_flag,
        pcm_params,
        num_short_term_ref_pic_sets,
        long_term_ref_pics_present_flag,
        sps_temporal_mvp_enabled_flag,
        strong_intra_smoothing_enabled_flag,
        vui_parameters_present_flag,
        video_full_range_flag,
        matrix_coeffs,
    })
}

/// Parse Picture Parameter Set
pub fn parse_pps(data: &[u8]) -> Result<Pps> {
    let mut reader = BitstreamReader::new(data);

    let pps_id = reader.read_ue()? as u8;
    let sps_id = reader.read_ue()? as u8;
    let dependent_slice_segments_enabled_flag = reader.read_bit()? != 0;
    let output_flag_present_flag = reader.read_bit()? != 0;
    let num_extra_slice_header_bits = reader.read_bits(3)? as u8;
    let sign_data_hiding_enabled_flag = reader.read_bit()? != 0;
    let cabac_init_present_flag = reader.read_bit()? != 0;
    let num_ref_idx_l0_default_active_minus1 = reader.read_ue()? as u8;
    let num_ref_idx_l1_default_active_minus1 = reader.read_ue()? as u8;
    let init_qp_minus26 = reader.read_se()? as i8;
    let constrained_intra_pred_flag = reader.read_bit()? != 0;
    let transform_skip_enabled_flag = reader.read_bit()? != 0;

    let cu_qp_delta_enabled_flag = reader.read_bit()? != 0;
    let diff_cu_qp_delta_depth = if cu_qp_delta_enabled_flag {
        reader.read_ue()? as u8
    } else {
        0
    };

    let pps_cb_qp_offset = reader.read_se()? as i8;
    let pps_cr_qp_offset = reader.read_se()? as i8;
    let pps_slice_chroma_qp_offsets_present_flag = reader.read_bit()? != 0;
    let weighted_pred_flag = reader.read_bit()? != 0;
    let weighted_bipred_flag = reader.read_bit()? != 0;
    let transquant_bypass_enabled_flag = reader.read_bit()? != 0;
    let tiles_enabled_flag = reader.read_bit()? != 0;
    let entropy_coding_sync_enabled_flag = reader.read_bit()? != 0;

    let tile_info = if tiles_enabled_flag {
        let num_tile_columns_minus1 = reader.read_ue()? as u16;
        let num_tile_rows_minus1 = reader.read_ue()? as u16;
        let uniform_spacing_flag = reader.read_bit()? != 0;

        let (column_widths, row_heights) = if !uniform_spacing_flag {
            let mut cols = Vec::with_capacity(num_tile_columns_minus1 as usize);
            let mut rows = Vec::with_capacity(num_tile_rows_minus1 as usize);
            for _ in 0..num_tile_columns_minus1 {
                cols.push(reader.read_ue()? as u16);
            }
            for _ in 0..num_tile_rows_minus1 {
                rows.push(reader.read_ue()? as u16);
            }
            (cols, rows)
        } else {
            (Vec::new(), Vec::new())
        };

        let loop_filter_across_tiles_enabled_flag = reader.read_bit()? != 0;

        Some(TileInfo {
            num_tile_columns_minus1,
            num_tile_rows_minus1,
            uniform_spacing_flag,
            column_widths,
            row_heights,
            loop_filter_across_tiles_enabled_flag,
        })
    } else {
        None
    };

    let pps_loop_filter_across_slices_enabled_flag = reader.read_bit()? != 0;
    let deblocking_filter_control_present_flag = reader.read_bit()? != 0;

    let (
        deblocking_filter_override_enabled_flag,
        pps_deblocking_filter_disabled_flag,
        pps_beta_offset_div2,
        pps_tc_offset_div2,
    ) = if deblocking_filter_control_present_flag {
        let override_enabled = reader.read_bit()? != 0;
        let disabled = reader.read_bit()? != 0;
        let (beta, tc) = if !disabled {
            (reader.read_se()? as i8, reader.read_se()? as i8)
        } else {
            (0, 0)
        };
        (override_enabled, disabled, beta, tc)
    } else {
        (false, false, 0, 0)
    };

    let pps_scaling_list_data_present_flag = reader.read_bit()? != 0;
    let pps_scaling_list = if pps_scaling_list_data_present_flag {
        Some(parse_scaling_list_data(&mut reader)?)
    } else {
        None
    };

    let lists_modification_present_flag = reader.read_bit()? != 0;
    let log2_parallel_merge_level_minus2 = reader.read_ue()? as u8;
    let slice_segment_header_extension_present_flag = reader.read_bit()? != 0;

    Ok(Pps {
        pps_id,
        sps_id,
        dependent_slice_segments_enabled_flag,
        output_flag_present_flag,
        num_extra_slice_header_bits,
        sign_data_hiding_enabled_flag,
        cabac_init_present_flag,
        num_ref_idx_l0_default_active_minus1,
        num_ref_idx_l1_default_active_minus1,
        init_qp_minus26,
        constrained_intra_pred_flag,
        transform_skip_enabled_flag,
        cu_qp_delta_enabled_flag,
        diff_cu_qp_delta_depth,
        pps_cb_qp_offset,
        pps_cr_qp_offset,
        pps_slice_chroma_qp_offsets_present_flag,
        weighted_pred_flag,
        weighted_bipred_flag,
        transquant_bypass_enabled_flag,
        tiles_enabled_flag,
        entropy_coding_sync_enabled_flag,
        tile_info,
        pps_loop_filter_across_slices_enabled_flag,
        deblocking_filter_control_present_flag,
        deblocking_filter_override_enabled_flag,
        pps_deblocking_filter_disabled_flag,
        pps_beta_offset_div2,
        pps_tc_offset_div2,
        pps_scaling_list_data_present_flag,
        pps_scaling_list,
        lists_modification_present_flag,
        log2_parallel_merge_level_minus2,
        slice_segment_header_extension_present_flag,
    })
}

fn parse_profile_tier_level(
    reader: &mut BitstreamReader<'_>,
    profile_present: bool,
    max_sub_layers_minus1: u8,
) -> Result<ProfileTierLevel> {
    let mut ptl = ProfileTierLevel::default();

    if profile_present {
        ptl.general_profile_space = reader.read_bits(2)? as u8;
        ptl.general_tier_flag = reader.read_bit()? != 0;
        ptl.general_profile_idc = reader.read_bits(5)? as u8;

        for i in 0..32 {
            ptl.general_profile_compatibility_flag[i] = reader.read_bit()? != 0;
        }

        ptl.general_progressive_source_flag = reader.read_bit()? != 0;
        ptl.general_interlaced_source_flag = reader.read_bit()? != 0;
        ptl.general_non_packed_constraint_flag = reader.read_bit()? != 0;
        ptl.general_frame_only_constraint_flag = reader.read_bit()? != 0;

        // Skip 44 reserved bits
        reader.read_bits(32)?;
        reader.read_bits(12)?;
    }

    ptl.general_level_idc = reader.read_bits(8)? as u8;

    // Skip sub-layer profile/level info
    let mut sub_layer_profile_present = [false; 8];
    let mut sub_layer_level_present = [false; 8];

    for i in 0..max_sub_layers_minus1 as usize {
        sub_layer_profile_present[i] = reader.read_bit()? != 0;
        sub_layer_level_present[i] = reader.read_bit()? != 0;
    }

    if max_sub_layers_minus1 > 0 {
        for _ in max_sub_layers_minus1..8 {
            reader.read_bits(2)?; // reserved_zero_2bits
        }
    }

    for i in 0..max_sub_layers_minus1 as usize {
        if sub_layer_profile_present[i] {
            // Skip sub-layer profile info (88 bits)
            reader.read_bits(32)?;
            reader.read_bits(32)?;
            reader.read_bits(24)?;
        }
        if sub_layer_level_present[i] {
            reader.read_bits(8)?;
        }
    }

    Ok(ptl)
}

fn parse_scaling_list_data(reader: &mut BitstreamReader<'_>) -> Result<ScalingListData> {
    let mut data = ScalingListData::new_default();

    for size_id in 0..4usize {
        let matrix_step = if size_id == 3 { 3 } else { 1 };
        let mut matrix_id = 0usize;
        while matrix_id < 6 {
            let pred_mode_flag = reader.read_bit()? != 0;
            if !pred_mode_flag {
                // Copy from a reference matrix
                let pred_matrix_id_delta = reader.read_ue()? as usize;
                if pred_matrix_id_delta == 0 {
                    // Use default scaling list (already initialized)
                } else if let Some(ref_id) =
                    matrix_id.checked_sub(pred_matrix_id_delta * matrix_step)
                    && ref_id < 6
                {
                    data.lists[size_id][matrix_id] = data.lists[size_id][ref_id];
                    if size_id >= 2 {
                        data.dc_coef[size_id - 2][matrix_id] = data.dc_coef[size_id - 2][ref_id];
                    }
                }
            } else {
                // Parse explicit scaling list
                let coef_num = core::cmp::min(64, 1usize << (4 + (size_id << 1)));
                let mut next_coef: i32 = 8;
                if size_id > 1 {
                    let dc_coef_minus8 = reader.read_se()?;
                    next_coef = dc_coef_minus8 + 8;
                    data.dc_coef[size_id - 2][matrix_id] = ((next_coef + 256) % 256) as u8;
                }
                for i in 0..coef_num {
                    let delta = reader.read_se()?;
                    next_coef = (next_coef + delta + 256) % 256;
                    data.lists[size_id][matrix_id][i] = next_coef as u8;
                }
            }
            matrix_id += matrix_step;
        }
    }
    Ok(data)
}

fn skip_short_term_ref_pic_set(
    reader: &mut BitstreamReader<'_>,
    idx: u8,
    _num_sets: u8,
) -> Result<()> {
    let inter_ref_pic_set_prediction_flag = if idx != 0 {
        reader.read_bit()? != 0
    } else {
        false
    };

    if inter_ref_pic_set_prediction_flag {
        // Simplified - skip inter prediction
        if idx == _num_sets {
            let _delta_idx_minus1 = reader.read_ue()?;
        }
        let _delta_rps_sign = reader.read_bit()?;
        let _abs_delta_rps_minus1 = reader.read_ue()?;
        // Would need previous set info to properly parse
    } else {
        let num_negative_pics = reader.read_ue()?;
        let num_positive_pics = reader.read_ue()?;
        for _ in 0..num_negative_pics {
            let _delta_poc_s0_minus1 = reader.read_ue()?;
            let _used_by_curr_pic_s0_flag = reader.read_bit()?;
        }
        for _ in 0..num_positive_pics {
            let _delta_poc_s1_minus1 = reader.read_ue()?;
            let _used_by_curr_pic_s1_flag = reader.read_bit()?;
        }
    }

    Ok(())
}
