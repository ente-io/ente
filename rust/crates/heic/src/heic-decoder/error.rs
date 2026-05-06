//! Error types for HEVC decoding.

use alloc::string::String;
use core::fmt;

/// Errors specific to HEVC decoding.
#[derive(Debug)]
#[non_exhaustive]
pub enum HevcError {
    /// Invalid NAL unit.
    InvalidNalUnit(&'static str),
    /// Invalid bitstream.
    InvalidBitstream(&'static str),
    /// Missing required parameter set.
    MissingParameterSet(&'static str),
    /// Invalid parameter set.
    InvalidParameterSet {
        /// Parameter set type, for example "SPS" or "PPS".
        kind: &'static str,
        /// Description of the issue.
        msg: String,
    },
    /// CABAC decoding error.
    CabacError(&'static str),
    /// Unsupported profile/level.
    UnsupportedProfile {
        /// HEVC profile IDC.
        profile: u8,
        /// HEVC level IDC.
        level: u8,
    },
    /// Unsupported feature.
    Unsupported(&'static str),
    /// Decoding error.
    DecodingError(&'static str),
}

impl fmt::Display for HevcError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidNalUnit(msg) => write!(f, "invalid NAL unit: {msg}"),
            Self::InvalidBitstream(msg) => write!(f, "invalid bitstream: {msg}"),
            Self::MissingParameterSet(kind) => write!(f, "missing {kind}"),
            Self::InvalidParameterSet { kind, msg } => {
                write!(f, "invalid {kind}: {msg}")
            }
            Self::CabacError(msg) => write!(f, "CABAC error: {msg}"),
            Self::UnsupportedProfile { profile, level } => {
                write!(f, "unsupported profile {profile} level {level}")
            }
            Self::Unsupported(msg) => write!(f, "unsupported: {msg}"),
            Self::DecodingError(msg) => write!(f, "decoding error: {msg}"),
        }
    }
}

impl core::error::Error for HevcError {}
