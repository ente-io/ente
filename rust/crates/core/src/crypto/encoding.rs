//! Base64 and hex encoding helpers.

use base64::{
    Engine,
    engine::general_purpose::{STANDARD as BASE64, URL_SAFE as BASE64_URL_SAFE},
};

use crate::crypto::Result;

/// Decode a base64 string to bytes.
///
/// # Arguments
/// * `input` - Base64 encoded string.
///
/// # Returns
/// The decoded bytes.
pub fn decode_b64(input: &str) -> Result<Vec<u8>> {
    Ok(BASE64.decode(input)?)
}

/// Encode bytes to a base64 string.
///
/// This is standard base64 (RFC 4648 §4), matching libsodium's
/// `sodium_base64_VARIANT_ORIGINAL`.
///
/// # Arguments
/// * `input` - Bytes to encode.
///
/// # Returns
/// Base64 encoded string.
pub fn encode_b64(input: &[u8]) -> String {
    BASE64.encode(input)
}

/// Decode a base64 string to bytes.
///
/// Alias for [`decode_b64`], matching libsodium's `base642bin()` naming.
pub fn base642bin(input: &str) -> Result<Vec<u8>> {
    decode_b64(input)
}

/// Encode bytes to a base64 string.
///
/// Matches libsodium's `bin2base64()` naming.
///
/// When `url_safe` is true, this uses the URL-safe alphabet (RFC 4648 §5),
/// matching libsodium's `sodium_base64_VARIANT_URLSAFE` and Go's
/// `base64.URLEncoding`.
pub fn bin2base64(input: &[u8], url_safe: bool) -> String {
    if url_safe {
        BASE64_URL_SAFE.encode(input)
    } else {
        BASE64.encode(input)
    }
}

/// Convert a UTF-8 string to bytes.
///
/// # Arguments
/// * `input` - UTF-8 string.
///
/// # Returns
/// UTF-8 bytes.
pub fn str_to_bin(input: &str) -> Vec<u8> {
    input.as_bytes().to_vec()
}

/// Decode a hex string to bytes.
///
/// # Arguments
/// * `input` - Hex encoded string.
///
/// # Returns
/// The decoded bytes.
pub fn decode_hex(input: &str) -> Result<Vec<u8>> {
    Ok(hex::decode(input)?)
}

/// Encode bytes to a hex string.
///
/// # Arguments
/// * `input` - Bytes to encode.
///
/// # Returns
/// Hex encoded string (lowercase).
pub fn encode_hex(input: &[u8]) -> String {
    hex::encode(input)
}

/// Convert a base64 string to hex.
///
/// # Arguments
/// * `b64` - Base64 encoded string.
///
/// # Returns
/// Hex encoded string.
pub fn b64_to_hex(b64: &str) -> Result<String> {
    let bytes = decode_b64(b64)?;
    Ok(encode_hex(&bytes))
}

/// Convert a hex string to base64.
///
/// # Arguments
/// * `hex_str` - Hex encoded string.
///
/// # Returns
/// Base64 encoded string.
pub fn hex_to_b64(hex_str: &str) -> Result<String> {
    let bytes = decode_hex(hex_str)?;
    Ok(encode_b64(&bytes))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base64_roundtrip() {
        let original = b"Hello, World!";
        let encoded = encode_b64(original);
        let decoded = decode_b64(&encoded).unwrap();
        assert_eq!(decoded, original);
    }

    #[test]
    fn test_hex_roundtrip() {
        let original = b"Hello, World!";
        let encoded = encode_hex(original);
        let decoded = decode_hex(&encoded).unwrap();
        assert_eq!(decoded, original);
    }

    #[test]
    fn test_b64_to_hex() {
        let original = b"Test";
        let b64 = encode_b64(original);
        let hex = b64_to_hex(&b64).unwrap();
        assert_eq!(hex, "54657374"); // "Test" in hex
    }

    #[test]
    fn test_hex_to_b64() {
        let hex = "54657374"; // "Test" in hex
        let b64 = hex_to_b64(hex).unwrap();
        let decoded = decode_b64(&b64).unwrap();
        assert_eq!(decoded, b"Test");
    }

    #[test]
    fn test_str_to_bin_ascii() {
        let bytes = str_to_bin("Hello");
        assert_eq!(bytes, b"Hello");
    }

    #[test]
    fn test_str_to_bin_unicode() {
        let bytes = str_to_bin("✓");
        assert_eq!(bytes, vec![0xE2, 0x9C, 0x93]);
    }

    #[test]
    fn test_invalid_base64() {
        let result = decode_b64("not valid base64!!!");
        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_hex() {
        let result = decode_hex("not valid hex!!!");
        assert!(result.is_err());
    }
}
