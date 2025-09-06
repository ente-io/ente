use crate::{Error, Result};
use libsodium_sys as sodium;

/// Tag indicating this is the final message in the stream
#[allow(dead_code)]
pub const TAG_FINAL: u8 = 0x03;
/// Tag for regular messages
#[allow(dead_code)]
pub const TAG_MESSAGE: u8 = 0x00;

/// XChaCha20-Poly1305 streaming decryptor
pub struct StreamDecryptor {
    state: Box<[u8]>,
}

impl StreamDecryptor {
    fn state_bytes() -> usize {
        unsafe { sodium::crypto_secretstream_xchacha20poly1305_statebytes() }
    }

    /// Create a new stream decryptor from key and header
    pub fn new(key: &[u8], header: &[u8]) -> Result<Self> {
        if key.len() != sodium::crypto_secretstream_xchacha20poly1305_KEYBYTES as usize {
            return Err(Error::Crypto(format!(
                "Invalid key length: expected {}, got {}",
                sodium::crypto_secretstream_xchacha20poly1305_KEYBYTES,
                key.len()
            )));
        }

        if header.len() != sodium::crypto_secretstream_xchacha20poly1305_HEADERBYTES as usize {
            return Err(Error::Crypto(format!(
                "Invalid header length: expected {}, got {}",
                sodium::crypto_secretstream_xchacha20poly1305_HEADERBYTES,
                header.len()
            )));
        }

        let mut state = vec![0u8; Self::state_bytes()].into_boxed_slice();

        unsafe {
            let ret = sodium::crypto_secretstream_xchacha20poly1305_init_pull(
                state.as_mut_ptr() as *mut sodium::crypto_secretstream_xchacha20poly1305_state,
                header.as_ptr(),
                key.as_ptr(),
            );

            if ret != 0 {
                return Err(Error::Crypto(
                    "Failed to initialize stream decryptor".into(),
                ));
            }
        }

        Ok(StreamDecryptor { state })
    }

    /// Pull (decrypt) a message from the stream
    pub fn pull(&mut self, ciphertext: &[u8]) -> Result<(Vec<u8>, u8)> {
        if ciphertext.len() < sodium::crypto_secretstream_xchacha20poly1305_ABYTES as usize {
            return Err(Error::Crypto("Ciphertext too short".into()));
        }

        let mut plaintext = vec![
            0u8;
            ciphertext.len()
                - sodium::crypto_secretstream_xchacha20poly1305_ABYTES as usize
        ];
        let mut plaintext_len: u64 = 0;
        let mut tag: u8 = 0;

        unsafe {
            let ret = sodium::crypto_secretstream_xchacha20poly1305_pull(
                self.state.as_mut_ptr() as *mut sodium::crypto_secretstream_xchacha20poly1305_state,
                plaintext.as_mut_ptr(),
                &mut plaintext_len,
                &mut tag,
                ciphertext.as_ptr(),
                ciphertext.len() as u64,
                std::ptr::null(),
                0,
            );

            if ret != 0 {
                return Err(Error::Crypto("Failed to decrypt stream chunk".into()));
            }
        }

        plaintext.truncate(plaintext_len as usize);
        Ok((plaintext, tag))
    }

    /// Decrypt an entire message at once (non-streaming)
    pub fn decrypt_all(key: &[u8], header: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>> {
        let mut decryptor = Self::new(key, header)?;
        let (plaintext, _tag) = decryptor.pull(ciphertext)?;
        Ok(plaintext)
    }
}

/// Decrypt data using streaming XChaCha20-Poly1305
/// This is for single-chunk decryption (most common case for files)
pub fn decrypt_stream(ciphertext: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    StreamDecryptor::decrypt_all(key, header, ciphertext)
}

/// Decrypt file data from memory using streaming cipher with chunking for large files
pub fn decrypt_file_data(encrypted_data: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    // Buffer size matching Go implementation: 4MB + overhead
    const CHUNK_SIZE: usize =
        4 * 1024 * 1024 + sodium::crypto_secretstream_xchacha20poly1305_ABYTES as usize;

    let mut decryptor = StreamDecryptor::new(key, header)?;
    let mut result = Vec::with_capacity(encrypted_data.len());

    let mut offset = 0;
    while offset < encrypted_data.len() {
        let chunk_end = std::cmp::min(offset + CHUNK_SIZE, encrypted_data.len());
        let chunk = &encrypted_data[offset..chunk_end];

        let (plaintext, tag) = decryptor.pull(chunk)?;
        result.extend_from_slice(&plaintext);

        offset = chunk_end;

        // Check if this was the final chunk
        if tag == TAG_FINAL {
            break;
        }
    }

    Ok(result)
}
