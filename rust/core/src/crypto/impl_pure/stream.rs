//! XChaCha20-Poly1305 secretstream implementation.
//!
//! Implements libsodium's crypto_secretstream_xchacha20poly1305 API.
//!
//! # Wire Format
//! - Header: 24 bytes (16 bytes HChaCha20 input + 8 bytes initial nonce)
//! - Each message: encrypted_tag (1 byte) || ciphertext || MAC (16 bytes)

use chacha20::ChaCha20;
use chacha20::cipher::{KeyIvInit, StreamCipher, StreamCipherSeek};
use chacha20::hchacha;
use poly1305::Poly1305;
use poly1305::universal_hash::KeyInit;
use rand_core::{OsRng, RngCore};
use std::io::{Read, Write};
use zeroize::Zeroize;

use crate::crypto::{CryptoError, Result};

/// Size of the stream header in bytes.
pub const HEADER_BYTES: usize = 24;

/// Size of the encryption key in bytes.
pub const KEY_BYTES: usize = 32;

/// Size of additional authenticated data bytes (tag + MAC).
pub const ABYTES: usize = 17;

/// Plaintext chunk size for streaming file encryption (4 MB).
pub const ENCRYPTION_CHUNK_SIZE: usize = 4 * 1024 * 1024;

/// Ciphertext chunk size for streaming file decryption (4 MB + overhead).
pub const DECRYPTION_CHUNK_SIZE: usize = ENCRYPTION_CHUNK_SIZE + ABYTES;

/// Tag for a regular message.
pub const TAG_MESSAGE: u8 = 0x00;

/// Tag indicating end of stream.
pub const TAG_FINAL: u8 = 0x03;

/// Tag for rekey.
pub const TAG_REKEY: u8 = 0x04;

/// Result of stream encryption.
#[derive(Debug, Clone)]
pub struct EncryptedStream {
    /// The encrypted data.
    pub encrypted_data: Vec<u8>,
    /// The decryption header.
    pub decryption_header: Vec<u8>,
}

/// HChaCha20 key derivation.
fn hchacha20(key: &[u8; 32], input: &[u8; 16]) -> [u8; 32] {
    use chacha20::cipher::consts::U10;
    let result = hchacha::<U10>(key.into(), input.into());
    let mut output = [0u8; 32];
    output.copy_from_slice(result.as_slice());
    output
}

/// Streaming encryptor for XChaCha20-Poly1305.
pub struct StreamEncryptor {
    k: [u8; 32],
    nonce: [u8; 12],
    /// The encryption header (24 bytes).
    pub header: Vec<u8>,
}

impl StreamEncryptor {
    /// Create a new encryptor with a random header.
    pub fn new(key: &[u8]) -> Result<Self> {
        if key.len() != KEY_BYTES {
            return Err(CryptoError::InvalidKeyLength {
                expected: KEY_BYTES,
                actual: key.len(),
            });
        }

        let mut header = [0u8; HEADER_BYTES];
        OsRng.fill_bytes(&mut header);

        let key_arr: [u8; 32] = key.try_into()?;
        let hchacha_input: [u8; 16] = header[0..16].try_into()?;
        let k = hchacha20(&key_arr, &hchacha_input);

        let mut nonce = [0u8; 12];
        nonce[0..4].copy_from_slice(&1u32.to_le_bytes());
        nonce[4..12].copy_from_slice(&header[16..24]);

        Ok(Self {
            k,
            nonce,
            header: header.to_vec(),
        })
    }

    /// Encrypt a message.
    pub fn push(&mut self, plaintext: &[u8], is_final: bool) -> Result<Vec<u8>> {
        self.push_with_ad(plaintext, &[], is_final)
    }

    /// Encrypt a message with additional authenticated data.
    pub fn push_with_ad(&mut self, plaintext: &[u8], ad: &[u8], is_final: bool) -> Result<Vec<u8>> {
        let tag = if is_final { TAG_FINAL } else { TAG_MESSAGE };

        // Generate keystream block 0 for Poly1305 key
        let mut block0 = [0u8; 64];
        let mut cipher = ChaCha20::new((&self.k).into(), (&self.nonce).into());
        cipher.apply_keystream(&mut block0);

        let poly_key: [u8; 32] = block0[0..32].try_into()?;
        block0.zeroize();

        // Encrypt 64-byte tag block at IC=1
        let mut tag_block = [0u8; 64];
        tag_block[0] = tag;
        cipher.seek(64u64);
        cipher.apply_keystream(&mut tag_block);
        let encrypted_tag = tag_block[0];

        // Encrypt message at IC=2
        cipher.seek(128u64);
        let mut ciphertext = plaintext.to_vec();
        cipher.apply_keystream(&mut ciphertext);

        // Build MAC input according to libsodium's secretstream format:
        // PAD(AD) || tag_block || ciphertext || PAD || adlen || msglen
        let mut mac_input = Vec::new();

        // AD with padding to 16 bytes
        mac_input.extend_from_slice(ad);
        let ad_pad = (16 - (ad.len() & 0xf)) & 0xf;
        mac_input.extend_from_slice(&[0u8; 16][..ad_pad]);

        // 64-byte encrypted tag block
        mac_input.extend_from_slice(&tag_block);

        // Ciphertext
        mac_input.extend_from_slice(&ciphertext);

        // Padding: (16 - 64 + mlen) & 0xf bytes
        let msg_pad = ((16i32 - 64 + plaintext.len() as i32) & 0xf) as usize;
        mac_input.extend_from_slice(&[0u8; 16][..msg_pad]);

        // Lengths: adlen (8 bytes LE), msglen (8 bytes LE) where msglen = 64 + plaintext.len()
        mac_input.extend_from_slice(&(ad.len() as u64).to_le_bytes());
        mac_input.extend_from_slice(&((64 + plaintext.len()) as u64).to_le_bytes());

        // Compute MAC using compute_unpadded (handles partial blocks correctly)
        let mac = Poly1305::new((&poly_key).into()).compute_unpadded(&mac_input);

        // Update state: XOR MAC[0..8] into inonce
        for (i, &mac_byte) in mac.as_slice().iter().enumerate().take(8) {
            self.nonce[4 + i] ^= mac_byte;
        }

        // Increment counter
        let counter = u32::from_le_bytes(self.nonce[0..4].try_into()?);
        let new_counter = counter.wrapping_add(1);
        self.nonce[0..4].copy_from_slice(&new_counter.to_le_bytes());

        // Rekey if needed
        if (tag & TAG_REKEY) != 0 || new_counter == 0 {
            self.rekey();
        }

        // Build output: encrypted_tag || ciphertext || MAC
        let mut output = Vec::with_capacity(1 + ciphertext.len() + 16);
        output.push(encrypted_tag);
        output.extend_from_slice(&ciphertext);
        output.extend_from_slice(mac.as_slice());

        Ok(output)
    }

    fn rekey(&mut self) {
        let mut buf = [0u8; 40];
        buf[0..32].copy_from_slice(&self.k);
        buf[32..40].copy_from_slice(&self.nonce[4..12]);

        let mut cipher = ChaCha20::new((&self.k).into(), (&self.nonce).into());
        cipher.apply_keystream(&mut buf);

        self.k.copy_from_slice(&buf[0..32]);
        self.nonce[4..12].copy_from_slice(&buf[32..40]);
        buf.zeroize();

        self.nonce[0..4].copy_from_slice(&1u32.to_le_bytes());
    }
}

/// Streaming decryptor for XChaCha20-Poly1305.
pub struct StreamDecryptor {
    k: [u8; 32],
    nonce: [u8; 12],
}

impl StreamDecryptor {
    /// Create a new decryptor from a header.
    pub fn new(header: &[u8], key: &[u8]) -> Result<Self> {
        if header.len() != HEADER_BYTES {
            return Err(CryptoError::InvalidHeaderLength {
                expected: HEADER_BYTES,
                actual: header.len(),
            });
        }
        if key.len() != KEY_BYTES {
            return Err(CryptoError::InvalidKeyLength {
                expected: KEY_BYTES,
                actual: key.len(),
            });
        }

        let key_arr: [u8; 32] = key.try_into()?;
        let hchacha_input: [u8; 16] = header[0..16].try_into()?;
        let k = hchacha20(&key_arr, &hchacha_input);

        let mut nonce = [0u8; 12];
        nonce[0..4].copy_from_slice(&1u32.to_le_bytes());
        nonce[4..12].copy_from_slice(&header[16..24]);

        Ok(Self { k, nonce })
    }

    /// Decrypt a message.
    pub fn pull(&mut self, ciphertext: &[u8]) -> Result<(Vec<u8>, u8)> {
        self.pull_with_ad(ciphertext, &[])
    }

    /// Decrypt a message with additional authenticated data.
    pub fn pull_with_ad(&mut self, ciphertext: &[u8], ad: &[u8]) -> Result<(Vec<u8>, u8)> {
        if ciphertext.len() < ABYTES {
            return Err(CryptoError::StreamPullFailed);
        }

        let mlen = ciphertext.len() - ABYTES;
        let encrypted_tag = ciphertext[0];
        let c = &ciphertext[1..1 + mlen];
        let stored_mac = &ciphertext[1 + mlen..];

        // Generate keystream block 0 for Poly1305 key
        let mut block0 = [0u8; 64];
        let mut cipher = ChaCha20::new((&self.k).into(), (&self.nonce).into());
        cipher.apply_keystream(&mut block0);

        let poly_key: [u8; 32] = block0[0..32].try_into()?;
        block0.zeroize();

        // Reconstruct encrypted tag block for MAC verification
        // 1. Start with [encrypted_tag, 0, 0, ...]
        // 2. XOR with keystream at IC=1: [tag, ks[1], ks[2], ...]
        // 3. Extract tag
        // 4. Reset block[0] to encrypted_tag for MAC: [encrypted_tag, ks[1], ks[2], ...]
        let mut tag_block = [0u8; 64];
        tag_block[0] = encrypted_tag;
        cipher.seek(64u64);
        cipher.apply_keystream(&mut tag_block);
        let tag = tag_block[0];

        // Reset block[0] to encrypted tag (libsodium does this for MAC verification)
        tag_block[0] = encrypted_tag;

        // Build MAC input
        let mut mac_input = Vec::new();

        // AD with padding
        mac_input.extend_from_slice(ad);
        let ad_pad = (16 - (ad.len() & 0xf)) & 0xf;
        mac_input.extend_from_slice(&[0u8; 16][..ad_pad]);

        // Encrypted tag block
        mac_input.extend_from_slice(&tag_block);

        // Ciphertext
        mac_input.extend_from_slice(c);

        // Padding
        let msg_pad = ((16i32 - 64 + mlen as i32) & 0xf) as usize;
        mac_input.extend_from_slice(&[0u8; 16][..msg_pad]);

        // Lengths
        mac_input.extend_from_slice(&(ad.len() as u64).to_le_bytes());
        mac_input.extend_from_slice(&((64 + mlen) as u64).to_le_bytes());

        // Verify MAC
        let computed_mac = Poly1305::new((&poly_key).into()).compute_unpadded(&mac_input);

        if computed_mac.as_slice() != stored_mac {
            return Err(CryptoError::StreamPullFailed);
        }

        // Decrypt
        cipher.seek(128u64);
        let mut plaintext = c.to_vec();
        cipher.apply_keystream(&mut plaintext);

        // Update state
        for (i, &mac_byte) in stored_mac.iter().enumerate().take(8) {
            self.nonce[4 + i] ^= mac_byte;
        }

        let counter = u32::from_le_bytes(self.nonce[0..4].try_into()?);
        let new_counter = counter.wrapping_add(1);
        self.nonce[0..4].copy_from_slice(&new_counter.to_le_bytes());

        if (tag & TAG_REKEY) != 0 || new_counter == 0 {
            self.rekey();
        }

        Ok((plaintext, tag))
    }

    fn rekey(&mut self) {
        let mut buf = [0u8; 40];
        buf[0..32].copy_from_slice(&self.k);
        buf[32..40].copy_from_slice(&self.nonce[4..12]);

        let mut cipher = ChaCha20::new((&self.k).into(), (&self.nonce).into());
        cipher.apply_keystream(&mut buf);

        self.k.copy_from_slice(&buf[0..32]);
        self.nonce[4..12].copy_from_slice(&buf[32..40]);
        buf.zeroize();

        self.nonce[0..4].copy_from_slice(&1u32.to_le_bytes());
    }
}

/// Encrypt data in a single chunk (convenience function).
pub fn encrypt(plaintext: &[u8], key: &[u8]) -> Result<EncryptedStream> {
    let mut encryptor = StreamEncryptor::new(key)?;
    let header = encryptor.header.clone();
    let ciphertext = encryptor.push(plaintext, true)?;
    Ok(EncryptedStream {
        encrypted_data: ciphertext,
        decryption_header: header,
    })
}

/// Decrypt data encrypted with [`encrypt`].
pub fn decrypt(ciphertext: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    let mut decryptor = StreamDecryptor::new(header, key)?;
    let (plaintext, _tag) = decryptor.pull(ciphertext)?;
    Ok(plaintext)
}

/// Decrypt data encrypted with [`encrypt`] using a stream wrapper.
pub fn decrypt_stream(encrypted: &EncryptedStream, key: &[u8]) -> Result<Vec<u8>> {
    decrypt(&encrypted.encrypted_data, &encrypted.decryption_header, key)
}

/// Estimate encrypted size for chunked secretstream encryption.
pub fn estimate_encrypted_size(plaintext_len: usize) -> usize {
    if plaintext_len == 0 {
        return 0;
    }

    let full_chunks = plaintext_len / ENCRYPTION_CHUNK_SIZE;
    let last_chunk_size = plaintext_len % ENCRYPTION_CHUNK_SIZE;

    let mut estimated = full_chunks * DECRYPTION_CHUNK_SIZE;
    if last_chunk_size > 0 {
        estimated += last_chunk_size + ABYTES;
    }

    estimated
}

/// Validate that plaintext and ciphertext sizes match chunked secretstream encryption.
pub fn validate_sizes(plaintext_len: usize, ciphertext_len: usize) -> bool {
    if plaintext_len == 0 || ciphertext_len == 0 {
        return false;
    }

    estimate_encrypted_size(plaintext_len) == ciphertext_len
}

/// Encrypt data from a reader into a writer using chunked secretstream.
pub fn encrypt_file<R: Read, W: Write>(
    source: &mut R,
    dest: &mut W,
    key: Option<&[u8]>,
) -> Result<(Vec<u8>, Vec<u8>)> {
    let key_bytes = match key {
        Some(key) => {
            if key.len() != KEY_BYTES {
                return Err(CryptoError::InvalidKeyLength {
                    expected: KEY_BYTES,
                    actual: key.len(),
                });
            }
            key.to_vec()
        }
        None => super::keys::generate_stream_key(),
    };

    let mut encryptor = StreamEncryptor::new(&key_bytes)?;
    let header = encryptor.header.clone();

    let mut buf = vec![0u8; ENCRYPTION_CHUNK_SIZE];
    let mut wrote_any = false;

    loop {
        let read = source.read(&mut buf)?;
        if read == 0 {
            break;
        }

        wrote_any = true;
        let is_final = read < ENCRYPTION_CHUNK_SIZE;
        let chunk = encryptor.push(&buf[..read], is_final)?;
        dest.write_all(&chunk)?;

        if is_final {
            break;
        }
    }

    if !wrote_any {
        let chunk = encryptor.push(&[], true)?;
        dest.write_all(&chunk)?;
    }

    Ok((key_bytes, header))
}

/// Decrypt data from a reader into a writer using chunked secretstream.
pub fn decrypt_file<R: Read, W: Write>(
    source: &mut R,
    dest: &mut W,
    header: &[u8],
    key: &[u8],
) -> Result<()> {
    let mut decryptor = StreamDecryptor::new(header, key)?;
    let mut buf = vec![0u8; DECRYPTION_CHUNK_SIZE];

    loop {
        let read = source.read(&mut buf)?;
        if read == 0 {
            break;
        }

        let (plaintext, tag) = decryptor.pull(&buf[..read])?;
        dest.write_all(&plaintext)?;

        if tag == TAG_FINAL {
            break;
        }
    }

    Ok(())
}

/// Decrypt data encrypted in secretstream chunks (4MB + overhead).
pub fn decrypt_file_data(encrypted_data: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    let mut decryptor = StreamDecryptor::new(header, key)?;
    let mut result = Vec::with_capacity(encrypted_data.len());

    let mut offset = 0;
    while offset < encrypted_data.len() {
        let chunk_end = std::cmp::min(offset + DECRYPTION_CHUNK_SIZE, encrypted_data.len());
        let chunk = &encrypted_data[offset..chunk_end];

        let (plaintext, tag) = decryptor.pull(chunk)?;
        result.extend_from_slice(&plaintext);

        offset = chunk_end;

        if tag == TAG_FINAL {
            break;
        }
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_roundtrip_single() {
        let key = [0x42u8; 32];
        let plaintext = b"Hello, World!";

        let mut enc = StreamEncryptor::new(&key).unwrap();
        let ct = enc.push(plaintext, true).unwrap();

        let mut dec = StreamDecryptor::new(&enc.header, &key).unwrap();
        let (pt, tag) = dec.pull(&ct).unwrap();

        assert_eq!(pt, plaintext);
        assert_eq!(tag, TAG_FINAL);
    }

    #[test]
    fn test_roundtrip_multi() {
        let key = [0x42u8; 32];
        let chunks = [b"First".to_vec(), b"Second".to_vec(), b"Third".to_vec()];

        let mut enc = StreamEncryptor::new(&key).unwrap();
        let mut encrypted = Vec::new();
        for (i, chunk) in chunks.iter().enumerate() {
            let is_final = i == chunks.len() - 1;
            encrypted.push(enc.push(chunk, is_final).unwrap());
        }

        let mut dec = StreamDecryptor::new(&enc.header, &key).unwrap();
        for (i, (ct, original)) in encrypted.iter().zip(chunks.iter()).enumerate() {
            let (pt, tag) = dec.pull(ct).unwrap();
            assert_eq!(pt, *original);
            let expected_tag = if i == chunks.len() - 1 {
                TAG_FINAL
            } else {
                TAG_MESSAGE
            };
            assert_eq!(tag, expected_tag);
        }
    }

    #[test]
    fn test_empty_plaintext() {
        let key = [0x42u8; 32];
        let plaintext = b"";

        let mut enc = StreamEncryptor::new(&key).unwrap();
        let ct = enc.push(plaintext, true).unwrap();

        assert_eq!(ct.len(), ABYTES);

        let mut dec = StreamDecryptor::new(&enc.header, &key).unwrap();
        let (pt, tag) = dec.pull(&ct).unwrap();

        assert_eq!(pt, plaintext);
        assert_eq!(tag, TAG_FINAL);
    }

    #[test]
    fn test_tampered_ciphertext_fails() {
        let key = [0x42u8; 32];
        let plaintext = b"Secret message";

        let mut enc = StreamEncryptor::new(&key).unwrap();
        let mut ct = enc.push(plaintext, true).unwrap();

        ct[5] ^= 0xFF;

        let mut dec = StreamDecryptor::new(&enc.header, &key).unwrap();
        assert!(dec.pull(&ct).is_err());
    }
}
