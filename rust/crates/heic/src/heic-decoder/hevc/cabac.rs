//! CABAC (Context-Adaptive Binary Arithmetic Coding) decoder
//!
//! CABAC is the entropy coding method used in HEVC. It uses arithmetic coding
//! with context models that adapt based on previously coded symbols.

use crate::heic_decoder::error::HevcError;

type Result<T> = core::result::Result<T, HevcError>;

/// CABAC state tables from H.265 spec Table 9-43
static LPS_TABLE: [[u8; 4]; 64] = [
    [128, 176, 208, 240],
    [128, 167, 197, 227],
    [128, 158, 187, 216],
    [123, 150, 178, 205],
    [116, 142, 169, 195],
    [111, 135, 160, 185],
    [105, 128, 152, 175],
    [100, 122, 144, 166],
    [95, 116, 137, 158],
    [90, 110, 130, 150],
    [85, 104, 123, 142],
    [81, 99, 117, 135],
    [77, 94, 111, 128],
    [73, 89, 105, 122],
    [69, 85, 100, 116],
    [66, 80, 95, 110],
    [62, 76, 90, 104],
    [59, 72, 86, 99],
    [56, 69, 81, 94],
    [53, 65, 77, 89],
    [51, 62, 73, 85],
    [48, 59, 69, 80],
    [46, 56, 66, 76],
    [43, 53, 63, 72],
    [41, 50, 59, 69],
    [39, 48, 56, 65],
    [37, 45, 54, 62],
    [35, 43, 51, 59],
    [33, 41, 48, 56],
    [32, 39, 46, 53],
    [30, 37, 43, 50],
    [29, 35, 41, 48],
    [27, 33, 39, 45],
    [26, 31, 37, 43],
    [24, 30, 35, 41],
    [23, 28, 33, 39],
    [22, 27, 32, 37],
    [21, 26, 30, 35],
    [20, 24, 29, 33],
    [19, 23, 27, 31],
    [18, 22, 26, 30],
    [17, 21, 25, 28],
    [16, 20, 23, 27],
    [15, 19, 22, 25],
    [14, 18, 21, 24],
    [14, 17, 20, 23],
    [13, 16, 19, 22],
    [12, 15, 18, 21],
    [12, 14, 17, 20],
    [11, 14, 16, 19],
    [11, 13, 15, 18],
    [10, 12, 15, 17],
    [10, 12, 14, 16],
    [9, 11, 13, 15],
    [9, 11, 12, 14],
    [8, 10, 12, 14],
    [8, 9, 11, 13],
    [7, 9, 11, 12],
    [7, 9, 10, 12],
    [7, 8, 10, 11],
    [6, 8, 9, 11],
    [6, 7, 9, 10],
    [6, 7, 8, 9],
    [2, 2, 2, 2],
];

/// Renormalization table
#[allow(dead_code)]
static RENORM_TABLE: [u8; 32] = [
    6, 5, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
];

/// State transition for MPS
static STATE_TRANS_MPS: [u8; 64] = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
    27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
    51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 62, 63,
];

/// State transition for LPS
static STATE_TRANS_LPS: [u8; 64] = [
    0, 0, 1, 2, 2, 4, 4, 5, 6, 7, 8, 9, 9, 11, 11, 12, 13, 13, 15, 15, 16, 16, 18, 18, 19, 19, 21,
    21, 22, 22, 23, 24, 24, 25, 26, 26, 27, 27, 28, 29, 29, 30, 30, 30, 31, 32, 32, 33, 33, 33, 34,
    34, 35, 35, 35, 36, 36, 36, 37, 37, 37, 38, 38, 63,
];

/// CABAC context model
#[derive(Clone, Copy)]
pub struct ContextModel {
    /// State index (0-63)
    state: u8,
    /// Most probable symbol (0 or 1)
    mps: u8,
}

#[allow(dead_code)]
impl ContextModel {
    /// Create a new context model with initial values
    pub fn new(init_value: u8) -> Self {
        // Convert init_value to state and mps
        let slope = (init_value >> 4) as i32 * 5 - 45;
        let offset = ((init_value & 15) << 3) as i32 - 16;
        let qp = 26; // Default QP for initialization

        let init_state = ((slope * (qp - 16)) >> 4) + offset;
        let init_state = init_state.clamp(1, 126);

        let (state, mps) = if init_state >= 64 {
            ((init_state - 64) as u8, 1)
        } else {
            ((63 - init_state) as u8, 0)
        };

        Self { state, mps }
    }

    /// Get the current context state and MPS
    pub fn get_state(&self) -> (u8, u8) {
        (self.state, self.mps)
    }

    /// Initialize context for a given slice QP
    /// Per H.265 Table 9-5: preCtxState = Clip3(1,126, ((m * Clip3(0,51,SliceQPY))>>4) + n)
    pub fn init(&mut self, init_value: u8, slice_qp: i32) {
        let m = (init_value >> 4) as i32 * 5 - 45;
        let n = ((init_value & 15) << 3) as i32 - 16;

        let init_state = ((m * slice_qp.clamp(0, 51)) >> 4) + n;
        let init_state = init_state.clamp(1, 126);

        if init_state >= 64 {
            self.state = (init_state - 64) as u8;
            self.mps = 1;
        } else {
            self.state = (63 - init_state) as u8;
            self.mps = 0;
        }
    }
}

/// CABAC decoder (libde265-compatible implementation)
///
/// This uses the same byte-at-a-time approach as libde265, with a 32-bit value
/// register and scaled comparisons for bypass decoding.
pub struct CabacDecoder<'a> {
    /// Input data
    data: &'a [u8],
    /// Current byte position
    byte_pos: usize,
    /// Range register (9 bits, 256-510)
    range: u32,
    /// Value register (holds ~16 bits of precision)
    value: u32,
    /// Bits needed before next byte read (negative means bits available)
    bits_needed: i32,
    /// Bin counter for debug tracing
    bin_counter: u32,
}

#[allow(dead_code)]
impl<'a> CabacDecoder<'a> {
    /// Get current CABAC state (range, offset) for debugging
    /// Note: returns (range, value >> 7) for compatibility with old debugging
    pub fn get_state(&self) -> (u16, u16) {
        (self.range as u16, (self.value >> 7) as u16)
    }

    /// Get extended CABAC state including bits_needed
    pub fn get_state_extended(&self) -> (u32, u32, i32) {
        (self.range, self.value, self.bits_needed)
    }

    /// Get current bitstream position for debugging
    pub fn get_position(&self) -> (usize, usize, u32) {
        (self.byte_pos, self.data.len(), self.byte_pos as u32 * 8)
    }

    /// Create a new CABAC decoder
    pub fn new(data: &'a [u8]) -> Result<Self> {
        if data.len() < 2 {
            return Err(HevcError::CabacError("data too short"));
        }

        let mut decoder = Self {
            data,
            byte_pos: 0,
            range: 510,
            value: 0,
            bits_needed: 8,
            bin_counter: 0,
        };

        // Initialize value (matching libde265 exactly)
        decoder.bits_needed = -8;
        if decoder.byte_pos < decoder.data.len() {
            decoder.value = decoder.data[decoder.byte_pos] as u32;
            decoder.byte_pos += 1;
        }
        decoder.value <<= 8;
        decoder.bits_needed = 0;
        if decoder.byte_pos < decoder.data.len() {
            decoder.value |= decoder.data[decoder.byte_pos] as u32;
            decoder.byte_pos += 1;
            decoder.bits_needed = -8;
        }

        Ok(decoder)
    }

    /// Reinitialize CABAC decoder at current bitstream position (byte alignment).
    /// Used for WPP substream boundaries and tile boundaries.
    /// Equivalent to libde265's init_CABAC_decoder_2().
    pub fn reinit(&mut self) {
        self.range = 510;
        self.bits_needed = 8;
        self.value = 0;

        let remaining = self.data.len() - self.byte_pos;
        if remaining > 0 {
            self.value = (self.data[self.byte_pos] as u32) << 8;
            self.byte_pos += 1;
            self.bits_needed -= 8;
        }
        if remaining > 1 {
            self.value |= self.data[self.byte_pos] as u32;
            self.byte_pos += 1;
            self.bits_needed -= 8;
        }
    }

    /// Read a single bit from the bitstream (for regular context decoding)
    fn read_bit(&mut self) -> Result<u32> {
        self.value <<= 1;
        self.bits_needed += 1;

        if self.bits_needed >= 0 {
            if self.byte_pos < self.data.len() {
                self.bits_needed = -8;
                self.value |= self.data[self.byte_pos] as u32;
                self.byte_pos += 1;
            } else {
                self.bits_needed = -8;
            }
        }

        Ok(0) // Return value not used, just for error handling
    }

    /// Decode a single bin using context model
    pub fn decode_bin(&mut self, ctx: &mut ContextModel) -> Result<u8> {
        self.bin_counter += 1;
        let q_range_idx = (self.range >> 6) & 3;
        let lps_range = LPS_TABLE[ctx.state as usize][q_range_idx as usize] as u32;

        self.range -= lps_range;

        // Scale for comparison
        let scaled_range = self.range << 7;

        let bin_val;
        if self.value < scaled_range {
            // MPS path
            bin_val = ctx.mps;
            ctx.state = STATE_TRANS_MPS[ctx.state as usize];
        } else {
            // LPS path
            bin_val = 1 - ctx.mps;
            self.value -= scaled_range;
            self.range = lps_range;

            if ctx.state == 0 {
                ctx.mps = 1 - ctx.mps;
            }
            ctx.state = STATE_TRANS_LPS[ctx.state as usize];
        }

        // Renormalize
        self.renormalize()?;

        Ok(bin_val)
    }

    /// Decode a bypass bin (equal probability) - libde265 compatible
    pub fn decode_bypass(&mut self) -> Result<u8> {
        self.bin_counter += 1;
        self.value <<= 1;
        self.bits_needed += 1;

        if self.bits_needed >= 0 {
            if self.byte_pos < self.data.len() {
                self.bits_needed = -8;
                self.value |= self.data[self.byte_pos] as u32;
                self.byte_pos += 1;
            } else {
                self.bits_needed = -8;
            }
        }

        let scaled_range = self.range << 7;
        if self.value >= scaled_range {
            self.value -= scaled_range;
            Ok(1)
        } else {
            Ok(0)
        }
    }

    /// Decode multiple bypass bins
    pub fn decode_bypass_bits(&mut self, n: u8) -> Result<u32> {
        let mut result = 0u32;
        for _ in 0..n {
            result = (result << 1) | self.decode_bypass()? as u32;
        }
        Ok(result)
    }

    /// Decode Exp-Golomb coded value (EGk) using bypass bins
    pub fn decode_egk_bypass(&mut self, k: u8) -> Result<u32> {
        let mut base = 0u32;
        let mut n = k;
        loop {
            let bit = self.decode_bypass()?;
            if bit == 0 {
                break;
            }
            base += 1 << n;
            n += 1;
            if n >= k + 32 {
                return Err(HevcError::InvalidBitstream("EGk prefix too long"));
            }
        }
        let suffix = self.decode_bypass_bits(n)?;
        Ok(base + suffix)
    }

    /// Decode a terminate bin (end of slice check)
    pub fn decode_terminate(&mut self) -> Result<u8> {
        self.range -= 2;

        let scaled_range = self.range << 7;
        if self.value >= scaled_range {
            Ok(1)
        } else {
            self.renormalize()?;
            Ok(0)
        }
    }

    /// Renormalize the decoder state
    fn renormalize(&mut self) -> Result<()> {
        while self.range < 256 {
            self.range <<= 1;
            // Shift value and read more bits
            self.read_bit()?;
        }
        // Invariant: after renormalization, range >= 256
        debug_assert!(self.range >= 256, "range {} < 256 after renorm", self.range);
        Ok(())
    }

    /// Decode unsigned Exp-Golomb code using bypass bins
    pub fn decode_eg(&mut self, k: u8) -> Result<u32> {
        // Count leading zeros
        let mut n = 0;
        while self.decode_bypass()? != 0 {
            n += 1;
            if n > 31 {
                return Err(HevcError::CabacError("exp-golomb overflow"));
            }
        }

        let mut value = 0u32;
        for _ in 0..(n + k) {
            value = (value << 1) | self.decode_bypass()? as u32;
        }

        Ok((1 << n) - 1 + value)
    }
}

/// Context indices for various syntax elements
#[allow(dead_code)]
pub mod context {
    /// Split CU flag contexts
    pub const SPLIT_CU_FLAG: usize = 0;
    /// CU transquant bypass flag
    pub const CU_TRANSQUANT_BYPASS_FLAG: usize = 3;
    /// CU skip flag
    pub const CU_SKIP_FLAG: usize = 4;
    /// Palette mode flag
    pub const PALETTE_MODE_FLAG: usize = 7;
    /// Pred mode flag
    pub const PRED_MODE_FLAG: usize = 8;
    /// Part mode contexts
    pub const PART_MODE: usize = 9;
    /// Prev intra luma pred flag
    pub const PREV_INTRA_LUMA_PRED_FLAG: usize = 13;
    /// Intra chroma pred mode
    pub const INTRA_CHROMA_PRED_MODE: usize = 14;
    /// Inter pred IDC
    pub const INTER_PRED_IDC: usize = 15;
    /// Merge flag
    pub const MERGE_FLAG: usize = 20;
    /// Merge IDX
    pub const MERGE_IDX: usize = 21;
    /// MVP L0/L1 flag
    pub const MVP_LX_FLAG: usize = 22;
    /// Ref IDX
    pub const REF_IDX: usize = 23;
    /// Abs MVD greater 0 flag
    pub const ABS_MVD_GREATER0_FLAG: usize = 25;
    /// Abs MVD greater 1 flag
    pub const ABS_MVD_GREATER1_FLAG: usize = 27;
    /// Split transform flag
    pub const SPLIT_TRANSFORM_FLAG: usize = 28;
    /// CBF luma
    pub const CBF_LUMA: usize = 31;
    /// CBF cb/cr
    pub const CBF_CBCR: usize = 33;
    /// Transform skip flag
    pub const TRANSFORM_SKIP_FLAG: usize = 38;
    /// Last sig coeff X prefix
    pub const LAST_SIG_COEFF_X_PREFIX: usize = 40;
    /// Last sig coeff Y prefix
    pub const LAST_SIG_COEFF_Y_PREFIX: usize = 58;
    /// Coded sub block flag
    pub const CODED_SUB_BLOCK_FLAG: usize = 76;
    /// Sig coeff flag
    pub const SIG_COEFF_FLAG: usize = 80;
    /// Coeff abs level greater 1 flag
    pub const COEFF_ABS_LEVEL_GREATER1_FLAG: usize = 124;
    /// Coeff abs level greater 2 flag
    pub const COEFF_ABS_LEVEL_GREATER2_FLAG: usize = 148;
    /// SAO merge flag
    pub const SAO_MERGE_FLAG: usize = 154;
    /// SAO type IDX
    pub const SAO_TYPE_IDX: usize = 155;
    /// CU QP delta abs
    pub const CU_QP_DELTA_ABS: usize = 156;
    /// CU chroma QP offset flag
    pub const CU_CHROMA_QP_OFFSET_FLAG: usize = 158;
    /// CU chroma QP offset IDX
    pub const CU_CHROMA_QP_OFFSET_IDX: usize = 159;
    /// Log2 res scale abs plus 1
    pub const LOG2_RES_SCALE_ABS_PLUS1: usize = 160;
    /// Res scale sign flag
    pub const RES_SCALE_SIGN_FLAG: usize = 168;
    /// Total number of contexts
    pub const NUM_CONTEXTS: usize = 170;
}

/// Initial context values from H.265 spec
pub static INIT_VALUES: [u8; context::NUM_CONTEXTS] = [
    // SPLIT_CU_FLAG (3)
    139, 141, 157, // CU_TRANSQUANT_BYPASS_FLAG (1)
    154, // CU_SKIP_FLAG (3)
    197, 185, 201, // PALETTE_MODE_FLAG (1)
    154, // PRED_MODE_FLAG (1)
    149, // PART_MODE (4)
    184, 154, 139, 154, // PREV_INTRA_LUMA_PRED_FLAG (1)
    184, // INTRA_CHROMA_PRED_MODE (1)
    63,  // INTER_PRED_IDC (5)
    95, 79, 63, 31, 31,  // MERGE_FLAG (1)
    110, // MERGE_IDX (1)
    122, // MVP_LX_FLAG (1)
    168, // REF_IDX (2)
    153, 153, // ABS_MVD_GREATER0_FLAG (2)
    140, 198, // ABS_MVD_GREATER1_FLAG (1)
    140, // SPLIT_TRANSFORM_FLAG (3)
    153, 138, 138, // CBF_LUMA (2)
    111, 141, // CBF_CBCR (5)
    94, 138, 182, 154, 154, // TRANSFORM_SKIP_FLAG (2)
    139, 139, // LAST_SIG_COEFF_X_PREFIX (18)
    110, 110, 124, 125, 140, 153, 125, 127, 140, 109, 111, 143, 127, 111, 79, 108, 123, 63,
    // LAST_SIG_COEFF_Y_PREFIX (18)
    110, 110, 124, 125, 140, 153, 125, 127, 140, 109, 111, 143, 127, 111, 79, 108, 123, 63,
    // CODED_SUB_BLOCK_FLAG (4)
    91, 171, 134, 141, // SIG_COEFF_FLAG (44)
    111, 111, 125, 110, 110, 94, 124, 108, 124, 107, 125, 141, 179, 153, 125, 107, 125, 141, 179,
    153, 125, 107, 125, 141, 179, 153, 125, 140, 139, 182, 182, 152, 136, 152, 136, 153, 136, 139,
    111, 136, 139, 111, 155, 154, // COEFF_ABS_LEVEL_GREATER1_FLAG (24)
    140, 92, 137, 138, 140, 152, 138, 139, 153, 74, 149, 92, 139, 107, 122, 152, 140, 179, 166,
    182, 140, 227, 122, 197, // COEFF_ABS_LEVEL_GREATER2_FLAG (6)
    138, 153, 136, 167, 152, 152, // SAO_MERGE_FLAG (1)
    153, // SAO_TYPE_IDX (1)
    200, // CU_QP_DELTA_ABS (2)
    154, 154, // CU_CHROMA_QP_OFFSET_FLAG (1)
    154, // CU_CHROMA_QP_OFFSET_IDX (1)
    154, // LOG2_RES_SCALE_ABS_PLUS1 (8)
    154, 154, 154, 154, 154, 154, 154, 154, // RES_SCALE_SIGN_FLAG (2)
    154, 154,
];
