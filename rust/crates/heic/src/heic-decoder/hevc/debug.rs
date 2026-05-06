#![allow(dead_code)]
//! Debug utilities for HEVC decoder
//!
//! This module provides invariant checking, logging, and comparison tools
//! for debugging the decoder.

extern crate alloc;

use alloc::format;
use alloc::vec::Vec;
use core::sync::atomic::{AtomicBool, AtomicU32, Ordering};

/// Enable verbose coefficient logging
pub static VERBOSE_COEFFS: AtomicBool = AtomicBool::new(false);

/// Enable CABAC state logging
pub static VERBOSE_CABAC: AtomicBool = AtomicBool::new(false);

/// Count of detected invariant violations
pub static INVARIANT_VIOLATIONS: AtomicU32 = AtomicU32::new(0);

/// Log an invariant violation and optionally panic
#[cold]
pub fn invariant_violation(msg: &str, should_panic: bool) {
    let count = INVARIANT_VIOLATIONS.fetch_add(1, Ordering::Relaxed);
    #[cfg(feature = "std")]
    eprintln!("INVARIANT VIOLATION #{}: {}", count + 1, msg);
    let _ = count;
    if should_panic {
        panic!("invariant violation: {}", msg);
    }
}

/// Check CABAC decoder invariants
pub fn check_cabac_invariants(range: u16, offset: u16, context: &str) {
    // After renormalization, range should be >= 256
    if range < 256 {
        invariant_violation(&format!("{}: CABAC range {} < 256", context, range), false);
    }

    // Offset should always be < range
    if offset >= range {
        invariant_violation(
            &format!("{}: CABAC offset {} >= range {}", context, offset, range),
            false,
        );
    }

    // Range should be <= 510 (initial value)
    if range > 510 {
        invariant_violation(&format!("{}: CABAC range {} > 510", context, range), true);
    }
}

/// Check coefficient value invariants
pub fn check_coeff_invariants(value: i16, max_coeff: i16, context: &str) {
    if value.abs() > max_coeff {
        invariant_violation(
            &format!(
                "{}: coefficient {} exceeds max {}",
                context, value, max_coeff
            ),
            false,
        );
    }
}

/// Coefficient decode event for logging
#[derive(Debug, Clone)]
#[allow(missing_docs)]
pub struct CoeffEvent {
    pub tu_x: u32,
    pub tu_y: u32,
    pub c_idx: u8,
    pub sb_idx: u32,
    pub pos: u8,
    pub base_level: i16,
    pub remaining: i16,
    pub sign: i8,
    pub final_value: i16,
    pub cabac_range: u16,
    pub cabac_offset: u16,
}

/// Event log for a single TU decode
#[allow(missing_docs)]
pub struct TuDecodeLog {
    pub events: Vec<CoeffEvent>,
    pub tu_x: u32,
    pub tu_y: u32,
    pub c_idx: u8,
    pub log2_size: u8,
    pub last_x: u32,
    pub last_y: u32,
}

impl TuDecodeLog {
    /// Create a new TU decode log
    pub fn new(tu_x: u32, tu_y: u32, c_idx: u8, log2_size: u8) -> Self {
        Self {
            events: Vec::new(),
            tu_x,
            tu_y,
            c_idx,
            log2_size,
            last_x: 0,
            last_y: 0,
        }
    }

    /// Log a coefficient decode event
    pub fn log_coeff(&mut self, event: CoeffEvent) {
        self.events.push(event);
    }

    /// Print summary of decoded coefficients
    #[cfg(feature = "std")]
    pub fn print_summary(&self) {
        eprintln!(
            "TU ({},{}) c_idx={} size={}x{} last=({},{}) coeffs={}",
            self.tu_x,
            self.tu_y,
            self.c_idx,
            1 << self.log2_size,
            1 << self.log2_size,
            self.last_x,
            self.last_y,
            self.events.len()
        );

        for (i, ev) in self.events.iter().enumerate() {
            eprintln!(
                "  [{}] sb={} pos={}: base={} rem={} sign={} final={} (range={} off={})",
                i,
                ev.sb_idx,
                ev.pos,
                ev.base_level,
                ev.remaining,
                ev.sign,
                ev.final_value,
                ev.cabac_range,
                ev.cabac_offset
            );
        }
    }
}

/// Compare two coefficient buffers and report differences
pub fn compare_coeffs(
    ours: &[i16],
    reference: &[i16],
    size: usize,
    context: &str,
) -> Vec<(usize, usize, i16, i16)> {
    let mut diffs = Vec::new();

    for y in 0..size {
        for x in 0..size {
            let idx = y * size + x;
            if idx < ours.len() && idx < reference.len() && ours[idx] != reference[idx] {
                diffs.push((x, y, ours[idx], reference[idx]));
            }
        }
    }

    #[cfg(feature = "std")]
    if !diffs.is_empty() {
        eprintln!("{}: {} differences found:", context, diffs.len());
        for (x, y, ours_val, ref_val) in &diffs[..diffs.len().min(10)] {
            eprintln!("  ({},{}) ours={} ref={}", x, y, ours_val, ref_val);
        }
        if diffs.len() > 10 {
            eprintln!("  ... and {} more", diffs.len() - 10);
        }
    }

    diffs
}

/// Calculate checksum of coefficient buffer for quick comparison
pub fn coeff_checksum(coeffs: &[i16], size: usize) -> u64 {
    let mut sum = 0u64;
    for y in 0..size {
        for x in 0..size {
            let idx = y * size + x;
            if idx < coeffs.len() {
                // Include position in checksum to catch ordering issues
                sum = sum.wrapping_add((coeffs[idx] as i64).wrapping_mul(idx as i64 + 1) as u64);
            }
        }
    }
    sum
}

/// CABAC state tracker for debugging
/// Tracks byte position progression to detect desync
#[derive(Default)]
pub struct CabacTracker {
    /// Byte positions at each CTU start
    ctu_positions: alloc::vec::Vec<(u32, usize)>,
    /// Number of large coefficients detected (indicates desync)
    large_coeff_count: u32,
    /// First byte position where large coefficients appeared
    first_large_coeff_byte: Option<usize>,
}

impl CabacTracker {
    /// Create a new tracker
    pub fn new() -> Self {
        Self::default()
    }

    /// Record CTU start position
    pub fn record_ctu_start(&mut self, ctu_idx: u32, byte_pos: usize) {
        self.ctu_positions.push((ctu_idx, byte_pos));
    }

    /// Record a large coefficient (indicates potential desync)
    pub fn record_large_coeff(&mut self, byte_pos: usize) {
        self.large_coeff_count += 1;
        if self.first_large_coeff_byte.is_none() {
            self.first_large_coeff_byte = Some(byte_pos);
        }
    }

    /// Print summary of tracking data
    #[cfg(feature = "std")]
    pub fn print_summary(&self) {
        if !self.ctu_positions.is_empty() {
            eprintln!("CABAC Tracker Summary:");
            eprintln!("  CTUs tracked: {}", self.ctu_positions.len());
            if let Some((last_ctu, last_pos)) = self.ctu_positions.last() {
                eprintln!("  Last CTU: {} at byte {}", last_ctu, last_pos);
            }
            eprintln!("  Large coeffs: {}", self.large_coeff_count);
            if let Some(pos) = self.first_large_coeff_byte {
                eprintln!("  First large coeff at byte: {}", pos);
                // Find which CTU this corresponds to
                for (ctu_idx, ctu_pos) in self.ctu_positions.iter().rev() {
                    if *ctu_pos <= pos {
                        eprintln!("  (in or after CTU {})", ctu_idx);
                        break;
                    }
                }
            }
        }
    }

    /// Check if desync is likely occurring
    pub fn is_likely_desynced(&self) -> bool {
        self.large_coeff_count > 5
    }
}

/// Global tracker instance
#[cfg(feature = "std")]
static TRACKER: std::sync::Mutex<Option<CabacTracker>> = std::sync::Mutex::new(None);

/// Initialize global tracker
#[cfg(feature = "std")]
pub fn init_tracker() {
    *TRACKER.lock().unwrap() = Some(CabacTracker::new());
}

/// Record CTU start in global tracker
#[cfg(feature = "std")]
pub fn track_ctu_start(ctu_idx: u32, byte_pos: usize) {
    if let Some(tracker) = TRACKER.lock().unwrap().as_mut() {
        tracker.record_ctu_start(ctu_idx, byte_pos);
    }
}

/// Record large coefficient in global tracker
#[cfg(feature = "std")]
pub fn track_large_coeff(byte_pos: usize) {
    if let Some(tracker) = TRACKER.lock().unwrap().as_mut() {
        tracker.record_large_coeff(byte_pos);
    }
}

/// Print tracker summary
#[cfg(feature = "std")]
pub fn print_tracker_summary() {
    if let Some(tracker) = TRACKER.lock().unwrap().as_ref() {
        tracker.print_summary();
    }
}

/// No-op stubs for no_std
#[cfg(not(feature = "std"))]
pub fn init_tracker() {}
/// No-op stub for no_std
#[cfg(not(feature = "std"))]
pub fn track_ctu_start(_ctu_idx: u32, _byte_pos: usize) {}
/// No-op stub for no_std
#[cfg(not(feature = "std"))]
pub fn track_large_coeff(_byte_pos: usize) {}
/// No-op stub for no_std
#[cfg(not(feature = "std"))]
pub fn print_tracker_summary() {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_checksum() {
        let coeffs1 = [1i16, 2, 3, 4];
        let coeffs2 = [1i16, 2, 3, 4];
        let coeffs3 = [1i16, 3, 2, 4]; // Swapped order

        assert_eq!(coeff_checksum(&coeffs1, 2), coeff_checksum(&coeffs2, 2));
        assert_ne!(coeff_checksum(&coeffs1, 2), coeff_checksum(&coeffs3, 2));
    }
}
