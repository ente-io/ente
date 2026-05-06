//! HEVC bitstream and NAL unit parsing

use crate::heic_decoder::error::HevcError;
use alloc::vec::Vec;

type Result<T> = core::result::Result<T, HevcError>;

/// NAL unit types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum NalType {
    /// Trailing picture, non-reference
    TrailN = 0,
    /// Trailing picture, reference
    TrailR = 1,
    /// Temporal sub-layer access, non-reference
    TsaN = 2,
    /// Temporal sub-layer access, reference
    TsaR = 3,
    /// Step-wise temporal sub-layer access, non-reference
    StsaN = 4,
    /// Step-wise temporal sub-layer access, reference
    StsaR = 5,
    /// Random access decodable leading, non-reference
    RadlN = 6,
    /// Random access decodable leading, reference
    RadlR = 7,
    /// Random access skipped leading, non-reference
    RaslN = 8,
    /// Random access skipped leading, reference
    RaslR = 9,
    /// Reserved VCL non-reference (10)
    RsvVclN10 = 10,
    /// Reserved VCL reference (11)
    RsvVclR11 = 11,
    /// Reserved VCL non-reference (12)
    RsvVclN12 = 12,
    /// Reserved VCL reference (13)
    RsvVclR13 = 13,
    /// Reserved VCL non-reference (14)
    RsvVclN14 = 14,
    /// Reserved VCL reference (15)
    RsvVclR15 = 15,
    /// Broken link access, no leading pictures
    BlaNLp = 16,
    /// Broken link access, with leading pictures
    BlaWLp = 17,
    /// Broken link access, with RADL
    BlaWRadl = 18,
    /// Instantaneous decoding refresh, with RADL
    IdrWRadl = 19,
    /// Instantaneous decoding refresh, no leading pictures
    IdrNLp = 20,
    /// Clean random access
    CraNut = 21,
    /// Reserved IRAP (22)
    RsvIrap22 = 22,
    /// Reserved IRAP (23)
    RsvIrap23 = 23,
    // Reserved 24-31
    /// Video parameter set
    VpsNut = 32,
    /// Sequence parameter set
    SpsNut = 33,
    /// Picture parameter set
    PpsNut = 34,
    /// Access unit delimiter
    AudNut = 35,
    /// End of sequence
    EosNut = 36,
    /// End of bitstream
    EobNut = 37,
    /// Filler data
    FdNut = 38,
    /// SEI (prefix)
    PrefixSeiNut = 39,
    /// SEI (suffix)
    SuffixSeiNut = 40,
    // Reserved 41-47
    // Unspecified 48-63
    /// Unknown or unrecognized NAL unit type
    Unknown = 255,
}

impl NalType {
    /// Create from raw NAL unit type value
    pub fn from_u8(val: u8) -> Self {
        match val {
            0 => Self::TrailN,
            1 => Self::TrailR,
            2 => Self::TsaN,
            3 => Self::TsaR,
            4 => Self::StsaN,
            5 => Self::StsaR,
            6 => Self::RadlN,
            7 => Self::RadlR,
            8 => Self::RaslN,
            9 => Self::RaslR,
            10 => Self::RsvVclN10,
            11 => Self::RsvVclR11,
            12 => Self::RsvVclN12,
            13 => Self::RsvVclR13,
            14 => Self::RsvVclN14,
            15 => Self::RsvVclR15,
            16 => Self::BlaNLp,
            17 => Self::BlaWLp,
            18 => Self::BlaWRadl,
            19 => Self::IdrWRadl,
            20 => Self::IdrNLp,
            21 => Self::CraNut,
            22 => Self::RsvIrap22,
            23 => Self::RsvIrap23,
            32 => Self::VpsNut,
            33 => Self::SpsNut,
            34 => Self::PpsNut,
            35 => Self::AudNut,
            36 => Self::EosNut,
            37 => Self::EobNut,
            38 => Self::FdNut,
            39 => Self::PrefixSeiNut,
            40 => Self::SuffixSeiNut,
            _ => Self::Unknown,
        }
    }

    /// Check if this is a VCL (slice) NAL unit
    pub fn is_slice(self) -> bool {
        matches!(
            self,
            Self::TrailN
                | Self::TrailR
                | Self::TsaN
                | Self::TsaR
                | Self::StsaN
                | Self::StsaR
                | Self::RadlN
                | Self::RadlR
                | Self::RaslN
                | Self::RaslR
                | Self::BlaNLp
                | Self::BlaWLp
                | Self::BlaWRadl
                | Self::IdrWRadl
                | Self::IdrNLp
                | Self::CraNut
        )
    }

    /// Check if this is an IDR or BLA picture
    pub fn is_idr(self) -> bool {
        matches!(
            self,
            Self::IdrWRadl | Self::IdrNLp | Self::BlaNLp | Self::BlaWLp | Self::BlaWRadl
        )
    }

    /// Check if this is a RASL picture
    #[allow(dead_code)]
    pub fn is_rasl(self) -> bool {
        matches!(self, Self::RaslN | Self::RaslR)
    }

    /// Check if this is a RADL picture
    #[allow(dead_code)]
    pub fn is_radl(self) -> bool {
        matches!(self, Self::RadlN | Self::RadlR)
    }

    /// Check if this is an IRAP picture
    pub fn is_irap(self) -> bool {
        matches!(
            self,
            Self::BlaNLp
                | Self::BlaWLp
                | Self::BlaWRadl
                | Self::IdrWRadl
                | Self::IdrNLp
                | Self::CraNut
                | Self::RsvIrap22
                | Self::RsvIrap23
        )
    }
}

/// Parsed NAL unit
#[allow(dead_code)]
#[derive(Debug)]
pub struct NalUnit<'a> {
    /// NAL unit type
    pub nal_type: NalType,
    /// Layer ID
    pub nuh_layer_id: u8,
    /// Temporal ID plus 1
    pub nuh_temporal_id_plus1: u8,
    /// NAL unit payload (after header, emulation bytes removed)
    pub payload: Vec<u8>,
    /// Raw data reference
    pub raw_data: &'a [u8],
}

/// Parse NAL units from HEVC bitstream
///
/// Handles both Annex B (start codes) and length-prefixed formats.
pub fn parse_nal_units(data: &[u8]) -> Result<Vec<NalUnit<'_>>> {
    if data.is_empty() {
        return Err(HevcError::InvalidBitstream("empty data"));
    }

    // Detect format: Annex B or length-prefixed
    let is_annexb = data.len() >= 4
        && ((data[0] == 0 && data[1] == 0 && data[2] == 1)
            || (data[0] == 0 && data[1] == 0 && data[2] == 0 && data[3] == 1));

    if is_annexb {
        parse_annexb(data)
    } else {
        // Assume 4-byte length prefix (most common for HEIC)
        parse_length_prefixed(data, 4)
    }
}

/// Parse Annex B format (start codes)
fn parse_annexb(data: &[u8]) -> Result<Vec<NalUnit<'_>>> {
    let mut nals = Vec::new();
    let mut i = 0;

    while i < data.len() {
        // Find start code
        if i + 3 <= data.len() && data[i] == 0 && data[i + 1] == 0 {
            let start_code_len = if i + 4 <= data.len() && data[i + 2] == 0 && data[i + 3] == 1 {
                4
            } else if data[i + 2] == 1 {
                3
            } else {
                i += 1;
                continue;
            };

            let nal_start = i + start_code_len;

            // Find next start code or end
            let mut nal_end = data.len();
            for j in nal_start..data.len().saturating_sub(2) {
                if data[j] == 0
                    && data[j + 1] == 0
                    && (data[j + 2] == 1
                        || (j + 3 < data.len() && data[j + 2] == 0 && data[j + 3] == 1))
                {
                    nal_end = j;
                    break;
                }
            }

            if nal_end > nal_start + 2 {
                let raw_data = &data[nal_start..nal_end];
                if let Ok(nal) = parse_nal_header(raw_data) {
                    nals.push(nal);
                }
            }

            i = nal_end;
        } else {
            i += 1;
        }
    }

    Ok(nals)
}

/// Parse length-prefixed format
fn parse_length_prefixed(data: &[u8], length_size: usize) -> Result<Vec<NalUnit<'_>>> {
    parse_length_prefixed_ext(data, length_size)
}

/// Parse length-prefixed format (public version)
pub fn parse_length_prefixed_ext(data: &[u8], length_size: usize) -> Result<Vec<NalUnit<'_>>> {
    let mut nals = Vec::new();
    let mut i = 0;

    while i + length_size <= data.len() {
        let nal_len = match length_size {
            1 => data[i] as usize,
            2 => u16::from_be_bytes([data[i], data[i + 1]]) as usize,
            3 => {
                ((data[i] as usize) << 16) | ((data[i + 1] as usize) << 8) | (data[i + 2] as usize)
            }
            4 => u32::from_be_bytes([data[i], data[i + 1], data[i + 2], data[i + 3]]) as usize,
            _ => return Err(HevcError::InvalidBitstream("unsupported length size")),
        };

        i += length_size;

        if i + nal_len > data.len() {
            return Err(HevcError::InvalidBitstream("NAL length exceeds data"));
        }

        let raw_data = &data[i..i + nal_len];
        if nal_len >= 2
            && let Ok(nal) = parse_nal_header(raw_data)
        {
            nals.push(nal);
        }

        i += nal_len;
    }

    Ok(nals)
}

/// Parse a single NAL unit (for hvcC parameter sets)
pub fn parse_single_nal(data: &[u8]) -> Result<NalUnit<'_>> {
    parse_nal_header(data)
}

/// Parse NAL unit header and remove emulation prevention bytes
fn parse_nal_header(raw_data: &[u8]) -> Result<NalUnit<'_>> {
    if raw_data.len() < 2 {
        return Err(HevcError::InvalidNalUnit("too short"));
    }

    // NAL unit header (2 bytes):
    // forbidden_zero_bit (1 bit) - must be 0
    // nal_unit_type (6 bits)
    // nuh_layer_id (6 bits)
    // nuh_temporal_id_plus1 (3 bits)

    if (raw_data[0] & 0x80) != 0 {
        return Err(HevcError::InvalidNalUnit("forbidden_zero_bit is set"));
    }

    let nal_type = NalType::from_u8((raw_data[0] >> 1) & 0x3F);
    let nuh_layer_id = ((raw_data[0] & 0x01) << 5) | ((raw_data[1] >> 3) & 0x1F);
    let nuh_temporal_id_plus1 = raw_data[1] & 0x07;

    if nuh_temporal_id_plus1 == 0 {
        return Err(HevcError::InvalidNalUnit("temporal_id_plus1 is zero"));
    }

    // Remove emulation prevention bytes (0x00 0x00 0x03 -> 0x00 0x00)
    let payload = remove_emulation_prevention(&raw_data[2..]);

    Ok(NalUnit {
        nal_type,
        nuh_layer_id,
        nuh_temporal_id_plus1,
        payload,
        raw_data,
    })
}

/// Remove emulation prevention bytes (0x03) from RBSP
fn remove_emulation_prevention(data: &[u8]) -> Vec<u8> {
    let mut result = Vec::with_capacity(data.len());
    let mut i = 0;

    while i < data.len() {
        if i + 2 < data.len() && data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 3 {
            // Emulation prevention byte found
            result.push(0);
            result.push(0);
            i += 3; // Skip the 0x03
        } else {
            result.push(data[i]);
            i += 1;
        }
    }

    result
}

/// Bitstream reader for parsing RBSP data
#[allow(dead_code)]
pub struct BitstreamReader<'a> {
    data: &'a [u8],
    byte_offset: usize,
    bit_offset: u8,
}

impl<'a> BitstreamReader<'a> {
    /// Create a new bitstream reader
    pub fn new(data: &'a [u8]) -> Self {
        Self {
            data,
            byte_offset: 0,
            bit_offset: 0,
        }
    }

    /// Check if at byte boundary
    #[allow(dead_code)]
    pub fn is_byte_aligned(&self) -> bool {
        self.bit_offset == 0
    }

    /// Skip to next byte boundary
    pub fn byte_align(&mut self) {
        if self.bit_offset != 0 {
            self.bit_offset = 0;
            self.byte_offset += 1;
        }
    }

    /// Read a single bit
    pub fn read_bit(&mut self) -> Result<u8> {
        if self.byte_offset >= self.data.len() {
            return Err(HevcError::InvalidBitstream("unexpected end of data"));
        }

        let bit = (self.data[self.byte_offset] >> (7 - self.bit_offset)) & 1;
        self.bit_offset += 1;
        if self.bit_offset == 8 {
            self.bit_offset = 0;
            self.byte_offset += 1;
        }

        Ok(bit)
    }

    /// Read up to 32 bits
    pub fn read_bits(&mut self, n: u8) -> Result<u32> {
        if n > 32 {
            return Err(HevcError::InvalidBitstream("too many bits requested"));
        }

        let mut value = 0u32;
        for _ in 0..n {
            value = (value << 1) | self.read_bit()? as u32;
        }
        Ok(value)
    }

    /// Read unsigned Exp-Golomb code
    pub fn read_ue(&mut self) -> Result<u32> {
        let mut leading_zeros = 0u32;
        while self.read_bit()? == 0 {
            leading_zeros += 1;
            if leading_zeros > 31 {
                return Err(HevcError::InvalidBitstream("exp-golomb overflow"));
            }
        }

        if leading_zeros == 0 {
            return Ok(0);
        }

        let suffix = self.read_bits(leading_zeros as u8)?;
        Ok((1 << leading_zeros) - 1 + suffix)
    }

    /// Read signed Exp-Golomb code
    pub fn read_se(&mut self) -> Result<i32> {
        let ue = self.read_ue()?;
        let value = ue.div_ceil(2) as i32;
        if ue & 1 == 0 { Ok(-value) } else { Ok(value) }
    }

    /// Check if more RBSP data is available
    #[allow(dead_code)]
    pub fn more_rbsp_data(&self) -> bool {
        if self.byte_offset >= self.data.len() {
            return false;
        }

        // Check for RBSP trailing bits (1 followed by zeros)
        let remaining_bits = (self.data.len() - self.byte_offset) * 8 - self.bit_offset as usize;
        if remaining_bits == 0 {
            return false;
        }

        // Look for rbsp_stop_one_bit followed by alignment zeros
        // This is a simplified check
        remaining_bits > 8
    }

    /// Remaining bytes
    #[allow(dead_code)]
    pub fn remaining(&self) -> usize {
        if self.byte_offset >= self.data.len() {
            0
        } else {
            self.data.len() - self.byte_offset
        }
    }

    /// Get current byte position (only valid if byte-aligned)
    pub fn byte_position(&self) -> usize {
        self.byte_offset
    }
}
