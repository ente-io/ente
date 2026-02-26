//! XChaCha20-Poly1305 secretstream implementation.
//!
//! Uses the `crypto_secretstream` crate which provides a pure Rust implementation
//! of libsodium's crypto_secretstream_xchacha20poly1305 API.
//!
//! # Wire Format
//! - Header: 24 bytes
//! - Each message: ciphertext (len + 17 bytes with tag embedded)

use crypto_secretstream::{Header, Key, PullStream, PushStream, Stream, Tag};
use md5::{Digest, Md5};
use rand_core::OsRng;
use std::convert::TryFrom;
use std::io::{Read, Write};

use crate::crypto::{CryptoError, Result};

/// Size of the stream header in bytes (from upstream crypto_secretstream).
pub const HEADER_BYTES: usize = Header::BYTES;

/// Size of the encryption key in bytes (from upstream crypto_secretstream).
pub const KEY_BYTES: usize = Key::BYTES;

/// Size of additional authenticated data bytes (tag + MAC, from upstream crypto_secretstream).
pub const ABYTES: usize = Stream::ABYTES;

/// Plaintext chunk size for streaming file encryption (4 MB).
pub const ENCRYPTION_CHUNK_SIZE: usize = 4 * 1024 * 1024;

/// Ciphertext chunk size for streaming file decryption (4 MB + overhead).
pub const DECRYPTION_CHUNK_SIZE: usize = ENCRYPTION_CHUNK_SIZE + ABYTES;

/// Tag for a regular message.
pub const TAG_MESSAGE: u8 = 0x00;

/// Tag for end of a set of messages (but not end of stream).
pub const TAG_PUSH: u8 = 0x01;

/// Tag to trigger rekeying for forward secrecy.
pub const TAG_REKEY: u8 = 0x02;

/// Tag indicating end of stream.
pub const TAG_FINAL: u8 = 0x03;

/// Stream message tag enum for type-safe tag handling.
///
/// This enum provides a more ergonomic interface than raw tag bytes,
/// and exposes all four libsodium secretstream tags.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StreamTag {
    /// Normal message, no state change.
    Message,
    /// Marks end of a set of messages, but not end of stream.
    Push,
    /// Triggers key rotation for forward secrecy.
    Rekey,
    /// Marks end of stream.
    Final,
}

impl StreamTag {
    /// Convert to raw byte representation.
    #[inline]
    pub const fn as_byte(self) -> u8 {
        match self {
            StreamTag::Message => TAG_MESSAGE,
            StreamTag::Push => TAG_PUSH,
            StreamTag::Rekey => TAG_REKEY,
            StreamTag::Final => TAG_FINAL,
        }
    }

    /// Check if this is the final tag.
    #[inline]
    pub const fn is_final(self) -> bool {
        matches!(self, StreamTag::Final)
    }
}

impl From<StreamTag> for u8 {
    fn from(tag: StreamTag) -> u8 {
        tag.as_byte()
    }
}

impl TryFrom<u8> for StreamTag {
    type Error = CryptoError;

    fn try_from(byte: u8) -> std::result::Result<Self, Self::Error> {
        match byte {
            TAG_MESSAGE => Ok(StreamTag::Message),
            TAG_PUSH => Ok(StreamTag::Push),
            TAG_REKEY => Ok(StreamTag::Rekey),
            TAG_FINAL => Ok(StreamTag::Final),
            _ => Err(CryptoError::StreamPullFailed),
        }
    }
}

impl From<Tag> for StreamTag {
    fn from(tag: Tag) -> Self {
        match tag {
            Tag::Message => StreamTag::Message,
            Tag::Push => StreamTag::Push,
            Tag::Rekey => StreamTag::Rekey,
            Tag::Final => StreamTag::Final,
        }
    }
}

impl From<StreamTag> for Tag {
    fn from(tag: StreamTag) -> Self {
        match tag {
            StreamTag::Message => Tag::Message,
            StreamTag::Push => Tag::Push,
            StreamTag::Rekey => Tag::Rekey,
            StreamTag::Final => Tag::Final,
        }
    }
}

/// Result of stream encryption.
#[derive(Debug, Clone)]
pub struct EncryptedStream {
    /// The encrypted data.
    pub encrypted_data: Vec<u8>,
    /// The decryption header.
    pub decryption_header: Vec<u8>,
}

/// Streaming encryptor for XChaCha20-Poly1305.
pub struct StreamEncryptor {
    stream: PushStream,
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

        let key = Key::try_from(key).map_err(|_| CryptoError::StreamPushFailed)?;
        let (header, stream) = PushStream::init(OsRng, &key);

        Ok(Self {
            stream,
            header: header.as_ref().to_vec(),
        })
    }

    /// Encrypt a message.
    #[inline]
    pub fn push(&mut self, plaintext: &[u8], is_final: bool) -> Result<Vec<u8>> {
        self.push_with_ad(plaintext, &[], is_final)
    }

    /// Encrypt a message with additional authenticated data.
    ///
    /// This allocates a new buffer. For zero-copy encryption, use [`push_in_place`].
    pub fn push_with_ad(&mut self, plaintext: &[u8], ad: &[u8], is_final: bool) -> Result<Vec<u8>> {
        let mut buffer = Vec::with_capacity(plaintext.len() + ABYTES);
        buffer.extend_from_slice(plaintext);
        self.push_in_place(&mut buffer, ad, is_final)?;
        Ok(buffer)
    }

    /// Encrypt a message in-place.
    ///
    /// The buffer should contain the plaintext. After this call, it will contain
    /// the ciphertext (plaintext.len() + ABYTES bytes).
    #[inline]
    pub fn push_in_place(&mut self, buffer: &mut Vec<u8>, ad: &[u8], is_final: bool) -> Result<()> {
        let tag = if is_final { Tag::Final } else { Tag::Message };
        self.stream
            .push(buffer, ad, tag)
            .map_err(|_| CryptoError::StreamPushFailed)?;
        Ok(())
    }
}

/// Streaming decryptor for XChaCha20-Poly1305.
pub struct StreamDecryptor {
    stream: PullStream,
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

        let key = Key::try_from(key).map_err(|_| CryptoError::StreamPullFailed)?;
        let header = Header::try_from(header).map_err(|_| CryptoError::StreamPullFailed)?;
        let stream = PullStream::init(header, &key);

        Ok(Self { stream })
    }

    /// Decrypt a message.
    #[inline]
    pub fn pull(&mut self, ciphertext: &[u8]) -> Result<(Vec<u8>, u8)> {
        self.pull_with_ad(ciphertext, &[])
    }

    /// Decrypt a message with additional authenticated data.
    ///
    /// This allocates a new buffer. For zero-copy decryption, use [`pull_in_place`].
    pub fn pull_with_ad(&mut self, ciphertext: &[u8], ad: &[u8]) -> Result<(Vec<u8>, u8)> {
        let mut buffer = ciphertext.to_vec();
        let tag = self.pull_in_place(&mut buffer, ad)?;
        Ok((buffer, tag))
    }

    /// Decrypt a message in-place.
    ///
    /// The buffer should contain the ciphertext. After this call, it will contain
    /// the plaintext (ciphertext.len() - ABYTES bytes).
    ///
    /// Returns the tag byte (TAG_MESSAGE or TAG_FINAL).
    pub fn pull_in_place(&mut self, buffer: &mut Vec<u8>, ad: &[u8]) -> Result<u8> {
        if buffer.len() < ABYTES {
            return Err(CryptoError::StreamPullFailed);
        }

        let tag = self
            .stream
            .pull(buffer, ad)
            .map_err(|_| CryptoError::StreamPullFailed)?;

        let tag_byte = match tag {
            Tag::Message => TAG_MESSAGE,
            Tag::Push => TAG_PUSH,
            Tag::Rekey => TAG_REKEY,
            Tag::Final => TAG_FINAL,
        };

        Ok(tag_byte)
    }

    /// Decrypt a message, returning a typed [`StreamTag`].
    #[inline]
    pub fn pull_typed(&mut self, ciphertext: &[u8]) -> Result<(Vec<u8>, StreamTag)> {
        self.pull_typed_with_ad(ciphertext, &[])
    }

    /// Decrypt a message with additional authenticated data, returning a typed [`StreamTag`].
    pub fn pull_typed_with_ad(
        &mut self,
        ciphertext: &[u8],
        ad: &[u8],
    ) -> Result<(Vec<u8>, StreamTag)> {
        let mut buffer = ciphertext.to_vec();
        let tag = self.pull_in_place_typed(&mut buffer, ad)?;
        Ok((buffer, tag))
    }

    /// Decrypt a message in-place, returning a typed [`StreamTag`].
    pub fn pull_in_place_typed(&mut self, buffer: &mut Vec<u8>, ad: &[u8]) -> Result<StreamTag> {
        if buffer.len() < ABYTES {
            return Err(CryptoError::StreamPullFailed);
        }

        let tag = self
            .stream
            .pull(buffer, ad)
            .map_err(|_| CryptoError::StreamPullFailed)?;

        Ok(tag.into())
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
///
/// # Errors
/// Returns `CryptoError::StreamTruncated` if the ciphertext does not have TAG_FINAL.
/// This ensures the one-shot helper only accepts complete single-chunk streams.
pub fn decrypt(ciphertext: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    let mut decryptor = StreamDecryptor::new(header, key)?;
    let (plaintext, tag) = decryptor.pull(ciphertext)?;
    if tag != TAG_FINAL {
        return Err(CryptoError::StreamTruncated);
    }
    Ok(plaintext)
}

/// Decrypt data encrypted with [`encrypt`] using a stream wrapper.
pub fn decrypt_stream(encrypted: &EncryptedStream, key: &[u8]) -> Result<Vec<u8>> {
    decrypt(&encrypted.encrypted_data, &encrypted.decryption_header, key)
}

/// Estimate encrypted size for chunked secretstream encryption.
///
/// Estimate ciphertext size (excluding header) for chunked secretstream encryption.
///
/// The stream is split into `ENCRYPTION_CHUNK_SIZE` chunks. The last chunk is
/// tagged FINAL; if the plaintext is empty, a single empty FINAL chunk is
/// emitted.
///
/// If the calculation overflows `usize`, this returns `usize::MAX`.
#[inline]
pub fn estimate_encrypted_size(plaintext_len: usize) -> usize {
    if plaintext_len == 0 {
        return ABYTES;
    }

    let full_chunks = plaintext_len / ENCRYPTION_CHUNK_SIZE;
    let last_chunk_size = plaintext_len % ENCRYPTION_CHUNK_SIZE;

    let full_bytes = match full_chunks.checked_mul(DECRYPTION_CHUNK_SIZE) {
        Some(value) => value,
        None => return usize::MAX,
    };

    if last_chunk_size == 0 {
        return full_bytes;
    }

    let with_last = match full_bytes.checked_add(last_chunk_size) {
        Some(value) => value,
        None => return usize::MAX,
    };
    match with_last.checked_add(ABYTES) {
        Some(value) => value,
        None => usize::MAX,
    }
}

/// Validate that plaintext and ciphertext sizes match chunked secretstream encryption.
///
/// Returns `true` if the ciphertext size matches what [`estimate_encrypted_size`]
/// would produce for the given plaintext size.
///
/// **Note**: This validates ciphertext size only, NOT including the header.
#[inline]
pub fn validate_sizes(plaintext_len: usize, ciphertext_len: usize) -> bool {
    let estimated = estimate_encrypted_size(plaintext_len);
    if estimated == usize::MAX {
        return false;
    }
    estimated == ciphertext_len
}

/// Streaming file encryptor that writes encrypted chunks to a writer.
///
/// Keeps the last full plaintext chunk in memory so it can be tagged FINAL
/// without emitting an extra empty FINAL chunk on exact chunk boundaries.
pub struct StreamingEncryptor<W: Write> {
    encryptor: StreamEncryptor,
    writer: W,
    /// Remainder bytes (< chunk size).
    buffer: Vec<u8>,
    /// Pending full chunk (exactly `ENCRYPTION_CHUNK_SIZE` bytes) that is not
    /// written until we know whether it's the final chunk.
    pending: Vec<u8>,
}

impl<W: Write> StreamingEncryptor<W> {
    /// Create a new streaming encryptor.
    pub fn new(key: &[u8], mut writer: W) -> Result<Self> {
        let encryptor = StreamEncryptor::new(key)?;
        writer.write_all(&encryptor.header)?;
        Ok(Self {
            encryptor,
            writer,
            buffer: Vec::with_capacity(ENCRYPTION_CHUNK_SIZE + ABYTES),
            pending: Vec::with_capacity(ENCRYPTION_CHUNK_SIZE + ABYTES),
        })
    }

    fn flush_pending(&mut self, is_final: bool) -> Result<()> {
        if self.pending.is_empty() {
            return Ok(());
        }

        self.encryptor
            .push_in_place(&mut self.pending, &[], is_final)?;
        self.writer.write_all(&self.pending)?;
        self.pending.clear();
        Ok(())
    }

    fn push_full_chunk(&mut self) -> Result<()> {
        if !self.pending.is_empty() {
            self.flush_pending(false)?;
        }

        std::mem::swap(&mut self.pending, &mut self.buffer);
        self.buffer.clear();
        Ok(())
    }

    /// Write plaintext data to the stream.
    pub fn write(&mut self, data: &[u8]) -> Result<()> {
        let mut input_pos = 0;

        if !self.buffer.is_empty() {
            let space_in_buffer = ENCRYPTION_CHUNK_SIZE - self.buffer.len();
            let bytes_to_add = std::cmp::min(space_in_buffer, data.len());
            self.buffer.extend_from_slice(&data[..bytes_to_add]);
            input_pos = bytes_to_add;

            if self.buffer.len() == ENCRYPTION_CHUNK_SIZE {
                self.push_full_chunk()?;
            } else {
                return Ok(());
            }
        }

        while input_pos + ENCRYPTION_CHUNK_SIZE <= data.len() {
            self.buffer.clear();
            self.buffer
                .extend_from_slice(&data[input_pos..input_pos + ENCRYPTION_CHUNK_SIZE]);
            input_pos += ENCRYPTION_CHUNK_SIZE;
            self.push_full_chunk()?;
        }

        if input_pos < data.len() {
            self.buffer.extend_from_slice(&data[input_pos..]);
        }

        Ok(())
    }

    /// Finish encryption, writing the final chunk.
    pub fn finish(mut self) -> Result<W> {
        if !self.pending.is_empty() {
            if !self.buffer.is_empty() {
                self.flush_pending(false)?;
            } else {
                self.flush_pending(true)?;
                return Ok(self.writer);
            }
        }

        self.encryptor.push_in_place(&mut self.buffer, &[], true)?;
        self.writer.write_all(&self.buffer)?;
        Ok(self.writer)
    }
}

/// Streaming file decryptor that reads encrypted chunks from a reader.
///
/// Uses a single-buffer strategy to minimize memory copies:
/// - Ciphertext is read directly into the buffer
/// - Decryption happens in-place (buffer shrinks by ABYTES)
/// - Plaintext is served via indices into the same buffer
///
/// This eliminates the extra copies that would occur with separate read/decrypt/output buffers.
pub struct StreamingDecryptor<R: Read> {
    decryptor: StreamDecryptor,
    reader: R,
    /// Single buffer: holds ciphertext during read, then plaintext after decryption.
    /// Unconsumed plaintext is at indices `data_start..buffer.len()`.
    buffer: Vec<u8>,
    /// Start index of unconsumed plaintext in buffer.
    data_start: usize,
    finished: bool,
    seen_final: bool,
}

impl<R: Read> StreamingDecryptor<R> {
    /// Create a new streaming decryptor.
    ///
    /// Uses a single-buffer strategy: ciphertext is read into the buffer,
    /// decrypted in-place, and plaintext is served via indices. This minimizes
    /// memory copies compared to using separate read/decrypt/output buffers.
    pub fn new(key: &[u8], mut reader: R) -> Result<Self> {
        let mut header = [0u8; HEADER_BYTES];
        reader.read_exact(&mut header)?;
        let decryptor = StreamDecryptor::new(&header, key)?;
        Ok(Self {
            decryptor,
            reader,
            buffer: Vec::with_capacity(DECRYPTION_CHUNK_SIZE),
            data_start: 0,
            finished: false,
            seen_final: false,
        })
    }

    /// Read and decrypt data into the provided buffer.
    /// Returns the number of bytes read, or 0 if EOF.
    ///
    /// Uses a single-buffer strategy with index-based tracking to avoid
    /// O(n) front-drain operations and eliminate extra memory copies:
    /// - Ciphertext is read directly into `buffer`
    /// - Decryption happens in-place (buffer shrinks by ABYTES)
    /// - Plaintext is served via `data_start` index into the same buffer
    pub fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        // If we have buffered plaintext, return it first (O(1) via index)
        // This must be checked BEFORE the finished flag, since we may have
        // buffered data remaining after seeing TAG_FINAL.
        let buffered_remaining = self.buffer.len() - self.data_start;
        if buffered_remaining > 0 {
            let to_copy = std::cmp::min(buf.len(), buffered_remaining);
            buf[..to_copy]
                .copy_from_slice(&self.buffer[self.data_start..self.data_start + to_copy]);
            self.data_start += to_copy;

            // Reset buffer when fully consumed to reclaim memory
            if self.data_start == self.buffer.len() {
                self.buffer.clear();
                self.data_start = 0;
            }
            return Ok(to_copy);
        }

        // No more buffered data - check if we're done
        if self.finished {
            return Ok(0);
        }

        // Read next encrypted chunk directly into buffer (single-buffer strategy)
        self.buffer.clear();
        self.buffer.resize(DECRYPTION_CHUNK_SIZE, 0);
        let mut total_read = 0;

        loop {
            match self.reader.read(&mut self.buffer[total_read..]) {
                Ok(0) => break,
                Ok(n) => {
                    total_read += n;
                    if total_read >= DECRYPTION_CHUNK_SIZE {
                        break;
                    }
                }
                Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
                Err(e) => return Err(e.into()),
            }
        }

        if total_read == 0 {
            // EOF reached - verify we saw the final tag (truncation detection)
            self.buffer.clear();
            if !self.seen_final {
                return Err(CryptoError::StreamTruncated);
            }
            self.finished = true;
            return Ok(0);
        }

        // Truncate buffer to actual bytes read, then decrypt in-place
        self.buffer.truncate(total_read);
        let tag = self.decryptor.pull_in_place(&mut self.buffer, &[])?;

        if tag == TAG_FINAL {
            self.seen_final = true;
            self.finished = true;
        }

        // Serve plaintext via indices (buffer now contains plaintext)
        self.data_start = 0;
        let plaintext_len = self.buffer.len();
        let to_copy = std::cmp::min(buf.len(), plaintext_len);
        buf[..to_copy].copy_from_slice(&self.buffer[..to_copy]);
        self.data_start = to_copy;

        // Reset buffer if fully consumed
        if self.data_start == self.buffer.len() {
            self.buffer.clear();
            self.data_start = 0;
        }

        Ok(to_copy)
    }

    /// Read all remaining data into a Vec.
    pub fn read_to_end(&mut self) -> Result<Vec<u8>> {
        let mut result = Vec::new();
        let mut buf = [0u8; 8192];

        loop {
            match self.read(&mut buf)? {
                0 => break,
                n => result.extend_from_slice(&buf[..n]),
            }
        }

        Ok(result)
    }
}

type EncryptFileResult = Result<(Vec<u8>, Vec<u8>, Option<Vec<u8>>)>;

fn encrypt_file_internal<R: Read, W: Write>(
    reader: &mut R,
    writer: &mut W,
    key: Option<&[u8]>,
    mut md5_state: Option<Md5>,
) -> EncryptFileResult {
    use crate::crypto::keys::generate_stream_key;

    let key = match key {
        Some(k) => k.to_vec(),
        None => generate_stream_key(),
    };

    let mut encryptor = StreamEncryptor::new(&key)?;
    let header = encryptor.header.clone();

    let mut read_chunk = |buf: &mut [u8]| -> Result<usize> {
        let mut total_read = 0;
        while total_read < ENCRYPTION_CHUNK_SIZE {
            match reader.read(&mut buf[total_read..]) {
                Ok(0) => break,
                Ok(n) => total_read += n,
                Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
                Err(e) => return Err(e.into()),
            }
        }
        Ok(total_read)
    };

    // Reusable buffers for plaintext chunks
    let mut curr = vec![0u8; ENCRYPTION_CHUNK_SIZE];
    let mut next = vec![0u8; ENCRYPTION_CHUNK_SIZE];

    // Reusable buffer for in-place encryption (avoids per-chunk allocation)
    let mut encrypt_buffer = Vec::with_capacity(ENCRYPTION_CHUNK_SIZE + ABYTES);

    let mut curr_len = read_chunk(&mut curr)?;

    if curr_len == 0 {
        // Empty file: single empty FINAL chunk
        encrypt_buffer.clear();
        encryptor.push_in_place(&mut encrypt_buffer, &[], true)?;
        if let Some(state) = md5_state.as_mut() {
            state.update(&encrypt_buffer);
        }
        writer.write_all(&encrypt_buffer)?;

        let md5 = md5_state.map(|state| state.finalize().as_slice().to_vec());
        return Ok((key, header, md5));
    }

    loop {
        if curr_len < ENCRYPTION_CHUNK_SIZE {
            // Last chunk is partial
            encrypt_buffer.clear();
            encrypt_buffer.extend_from_slice(&curr[..curr_len]);
            encryptor.push_in_place(&mut encrypt_buffer, &[], true)?;
            if let Some(state) = md5_state.as_mut() {
                state.update(&encrypt_buffer);
            }
            writer.write_all(&encrypt_buffer)?;
            break;
        }

        let next_len = read_chunk(&mut next)?;
        let is_final = next_len == 0;

        encrypt_buffer.clear();
        encrypt_buffer.extend_from_slice(&curr[..curr_len]);
        encryptor.push_in_place(&mut encrypt_buffer, &[], is_final)?;
        if let Some(state) = md5_state.as_mut() {
            state.update(&encrypt_buffer);
        }
        writer.write_all(&encrypt_buffer)?;

        if is_final {
            break;
        }

        std::mem::swap(&mut curr, &mut next);
        curr_len = next_len;
    }

    let md5 = md5_state.map(|state| state.finalize().as_slice().to_vec());

    Ok((key, header, md5))
}

/// Encrypt a file from a reader to a writer.
///
/// If `key` is `None`, a random key is generated.
/// Returns `(key, header)` for use in decryption.
///
/// # Output Format
///
/// This function produces output consistent with [`StreamingEncryptor`]:
/// - Full chunks are encrypted with MESSAGE tags
/// - The last chunk is tagged FINAL (empty FINAL chunk only for empty plaintext)
///
/// Use [`estimate_encrypted_size`] to predict the ciphertext size (excluding header).
///
/// This function uses reusable buffers and in-place encryption to avoid
/// allocating fresh memory per chunk. Memory usage is bounded to ~2x chunk size.
pub fn encrypt_file<R: Read, W: Write>(
    reader: &mut R,
    writer: &mut W,
    key: Option<&[u8]>,
) -> Result<(Vec<u8>, Vec<u8>)> {
    let (key, header, _md5) = encrypt_file_internal(reader, writer, key, None)?;
    Ok((key, header))
}

/// Encrypt a file from a reader to a writer and compute MD5 of the ciphertext.
///
/// This is a convenience wrapper around [`encrypt_file`], returning the MD5
/// digest of the encrypted output (excluding the header).
pub fn encrypt_file_with_md5<R: Read, W: Write>(
    reader: &mut R,
    writer: &mut W,
    key: Option<&[u8]>,
) -> Result<(Vec<u8>, Vec<u8>, Vec<u8>)> {
    let (key, header, md5) = encrypt_file_internal(reader, writer, key, Some(Md5::new()))?;
    let md5 = md5.ok_or(CryptoError::HashFailed)?;
    Ok((key, header, md5))
}

/// Decrypt a file from a reader to a writer.
///
/// The reader should contain encrypted data (without the header).
/// The header and key should be provided separately.
///
/// This function uses reusable buffers and in-place decryption to avoid
/// allocating fresh memory per chunk. Memory usage is bounded to ~2x chunk size.
///
/// # Errors
/// Returns `CryptoError::StreamTruncated` if EOF is reached without seeing TAG_FINAL.
/// This prevents silent truncation attacks at chunk boundaries.
pub fn decrypt_file<R: Read, W: Write>(
    reader: &mut R,
    writer: &mut W,
    header: &[u8],
    key: &[u8],
) -> Result<()> {
    let mut decryptor = StreamDecryptor::new(header, key)?;
    // Reusable read buffer - sized for ciphertext chunks
    let mut read_buffer = vec![0u8; DECRYPTION_CHUNK_SIZE];
    // Reusable decrypt buffer for in-place decryption (avoids per-chunk allocation)
    let mut decrypt_buffer = Vec::with_capacity(DECRYPTION_CHUNK_SIZE);

    loop {
        let mut total_read = 0;
        // Read up to DECRYPTION_CHUNK_SIZE bytes
        while total_read < DECRYPTION_CHUNK_SIZE {
            match reader.read(&mut read_buffer[total_read..]) {
                Ok(0) => break, // EOF
                Ok(n) => total_read += n,
                Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
                Err(e) => return Err(e.into()),
            }
        }

        if total_read == 0 {
            // EOF reached without seeing TAG_FINAL - stream was truncated
            // (if we had seen TAG_FINAL, we would have exited the loop via break below)
            return Err(CryptoError::StreamTruncated);
        }

        // Copy to decrypt buffer and decrypt in-place (reuses buffer each iteration)
        decrypt_buffer.clear();
        decrypt_buffer.extend_from_slice(&read_buffer[..total_read]);
        let tag = decryptor.pull_in_place(&mut decrypt_buffer, &[])?;
        writer.write_all(&decrypt_buffer)?;

        if tag == TAG_FINAL {
            // Successfully decrypted the final chunk - stream is complete
            return Ok(());
        }
    }
}

/// Decrypt file data that's already in memory.
///
/// This is a convenience function for when you have the entire encrypted file in a buffer.
/// The header (decryption nonce) and key must be provided separately.
pub fn decrypt_file_data(encrypted_data: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    use std::io::Cursor;

    let mut reader = Cursor::new(encrypted_data);
    let mut output = Vec::new();
    decrypt_file(&mut reader, &mut output, header, key)?;
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;
    use md5::{Digest, Md5};
    use std::io::Cursor;

    fn generate_test_key() -> [u8; KEY_BYTES] {
        [0x42u8; KEY_BYTES]
    }

    #[test]
    fn test_streaming_roundtrip() {
        let key = generate_test_key();
        let plaintext = b"Hello, world! This is a test message.";

        // Encrypt
        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            encryptor.write(plaintext).expect("write failed");
            encryptor.finish().expect("finish failed");
        }

        // Decrypt
        let reader = Cursor::new(&encrypted);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let decrypted = decryptor.read_to_end().expect("read_to_end failed");

        assert_eq!(plaintext.as_slice(), decrypted.as_slice());
    }

    #[test]
    fn test_truncation_detection_empty_stream() {
        let key = generate_test_key();

        // Create a stream with just the header, no encrypted data
        let encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();

        // Don't write any encrypted chunks - just the header
        let truncated_data = header.clone();

        let reader = Cursor::new(&truncated_data);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let result = decryptor.read_to_end();

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated error, got {:?}",
            result
        );
    }

    #[test]
    fn test_truncation_detection_missing_final() {
        let key = generate_test_key();
        let plaintext = b"Hello, world!";

        // Encrypt with non-final tag only
        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let encrypted_chunk = encryptor.push(plaintext, false).expect("push failed"); // Note: is_final = false

        // Create truncated stream: header + non-final chunk
        let mut truncated_data = header;
        truncated_data.extend_from_slice(&encrypted_chunk);

        let reader = Cursor::new(&truncated_data);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let result = decryptor.read_to_end();

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated error, got {:?}",
            result
        );
    }

    #[test]
    fn test_valid_stream_with_final_tag() {
        let key = generate_test_key();
        let plaintext = b"Hello, world!";

        // Encrypt properly with final tag
        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let encrypted_chunk = encryptor.push(plaintext, true).expect("push failed");

        // Create proper stream: header + final chunk
        let mut data = header;
        data.extend_from_slice(&encrypted_chunk);

        let reader = Cursor::new(&data);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let decrypted = decryptor.read_to_end().expect("read_to_end failed");

        assert_eq!(plaintext.as_slice(), decrypted.as_slice());
    }

    #[test]
    fn test_small_buffer_reads_no_quadratic() {
        // Regression test: ensure small-buffer reads don't cause O(n²) behavior.
        // Uses index-based buffering instead of Vec::drain() to achieve O(n) total.
        let key = generate_test_key();
        // Use a larger plaintext to make the test meaningful
        let plaintext: Vec<u8> = (0..10000).map(|i| (i % 256) as u8).collect();

        // Encrypt
        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            encryptor.write(&plaintext).expect("write failed");
            encryptor.finish().expect("finish failed");
        }

        // Decrypt using very small buffer (1 byte at a time - worst case for old impl)
        let reader = Cursor::new(&encrypted);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");

        let mut decrypted = Vec::new();
        let mut tiny_buf = [0u8; 1];
        loop {
            match decryptor.read(&mut tiny_buf).expect("read failed") {
                0 => break,
                n => decrypted.extend_from_slice(&tiny_buf[..n]),
            }
        }

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_varied_buffer_sizes() {
        // Test with various buffer sizes to ensure correctness
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..5000).map(|i| (i % 256) as u8).collect();

        // Encrypt
        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            encryptor.write(&plaintext).expect("write failed");
            encryptor.finish().expect("finish failed");
        }

        // Test with various buffer sizes
        for buf_size in [1, 7, 13, 64, 100, 1000, 8192] {
            let reader = Cursor::new(&encrypted);
            let mut decryptor =
                StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");

            let mut decrypted = Vec::new();
            let mut buf = vec![0u8; buf_size];
            loop {
                match decryptor.read(&mut buf).expect("read failed") {
                    0 => break,
                    n => decrypted.extend_from_slice(&buf[..n]),
                }
            }

            assert_eq!(
                plaintext, decrypted,
                "Mismatch with buffer size {}",
                buf_size
            );
        }
    }

    #[test]
    fn test_large_slice_write_no_quadratic() {
        // Regression test: verify StreamingEncryptor::write() is O(n) for large slices.
        // The optimization processes full chunks directly from input slice without
        // buffering them first, and buffers only the remainder (< chunk size).
        // This avoids O(n²) behavior that would occur with copy_within compaction.
        let key = generate_test_key();

        // Create data spanning multiple chunks to exercise the optimization
        // 3 full chunks + partial = tests the direct slice processing path
        let size = ENCRYPTION_CHUNK_SIZE * 3 + 1234;
        let plaintext: Vec<u8> = (0..size).map(|i| (i % 256) as u8).collect();

        // Write in a single large call (worst case for old O(n²) implementation)
        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            // Single large write should be O(n) not O(n²)
            encryptor.write(&plaintext).expect("write failed");
            encryptor.finish().expect("finish failed");
        }

        // Verify correctness
        let reader = Cursor::new(&encrypted);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let decrypted = decryptor.read_to_end().expect("read_to_end failed");

        assert_eq!(plaintext.len(), decrypted.len());
        assert_eq!(plaintext, decrypted);

        // Verify size matches estimate (confirms proper chunk structure)
        let ciphertext_len = encrypted.len() - HEADER_BYTES;
        assert_eq!(ciphertext_len, estimate_encrypted_size(plaintext.len()));
    }

    #[test]
    fn test_write_with_partial_buffer_then_large_slice() {
        // Regression test: verify optimization handles partial buffer correctly.
        // Write small data (partial buffer), then large data that spans chunks.
        let key = generate_test_key();

        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");

            // Write small data first (creates partial buffer)
            let small_data: Vec<u8> = (0..1000).map(|i| (i % 256) as u8).collect();
            encryptor.write(&small_data).expect("write small failed");

            // Write large data that will complete the partial buffer then process full chunks
            let large_size = ENCRYPTION_CHUNK_SIZE * 2 + 500;
            let large_data: Vec<u8> = (0..large_size).map(|i| ((i + 1000) % 256) as u8).collect();
            encryptor.write(&large_data).expect("write large failed");

            encryptor.finish().expect("finish failed");
        }

        // Decrypt and verify
        let total_plaintext_size = 1000 + ENCRYPTION_CHUNK_SIZE * 2 + 500;
        let reader = Cursor::new(&encrypted);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let decrypted = decryptor.read_to_end().expect("read_to_end failed");

        assert_eq!(decrypted.len(), total_plaintext_size);

        // Verify content: first 1000 bytes, then large_data
        for (i, byte) in decrypted.iter().take(1000).enumerate() {
            assert_eq!(*byte, (i % 256) as u8, "Mismatch at small_data[{}]", i);
        }
        for (i, byte) in decrypted[1000..]
            .iter()
            .take(ENCRYPTION_CHUNK_SIZE * 2 + 500)
            .enumerate()
        {
            assert_eq!(
                *byte,
                ((i + 1000) % 256) as u8,
                "Mismatch at large_data[{}]",
                i
            );
        }
    }

    // ============ P2: Expanded unit tests ============

    #[test]
    fn test_empty_input() {
        // Test encryption/decryption of empty data
        let key = generate_test_key();
        let plaintext = b"";

        let encrypted = encrypt(plaintext, &key).expect("encrypt failed");
        let decrypted = decrypt_stream(&encrypted, &key).expect("decrypt failed");

        assert_eq!(plaintext.as_slice(), decrypted.as_slice());
        assert_eq!(encrypted.encrypted_data.len(), ABYTES); // Just the tag overhead
    }

    #[test]
    fn test_empty_streaming() {
        // Test streaming encryption/decryption of empty data
        let key = generate_test_key();

        // Encrypt empty data
        let mut encrypted = Vec::new();
        {
            let encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            // Don't write anything - just finish with empty final chunk
            encryptor.finish().expect("finish failed");
        }

        // Should have header + empty final chunk
        assert_eq!(encrypted.len(), HEADER_BYTES + ABYTES);

        // Decrypt
        let reader = Cursor::new(&encrypted);
        let mut decryptor =
            StreamingDecryptor::new(&key, reader).expect("decryptor creation failed");
        let decrypted = decryptor.read_to_end().expect("read_to_end failed");

        assert!(decrypted.is_empty());
    }

    #[test]
    fn test_multi_chunk_roundtrip() {
        // Test with data larger than ENCRYPTION_CHUNK_SIZE
        let key = generate_test_key();
        // Create data that spans multiple chunks (use smaller chunks for test speed)
        let chunk_size = 1024; // Smaller for test
        let num_chunks = 3;
        let plaintext: Vec<u8> = (0..(chunk_size * num_chunks + 500))
            .map(|i| (i % 256) as u8)
            .collect();

        // Use low-level encryptor to test multi-chunk
        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();

        let mut ciphertext = Vec::new();
        let mut offset = 0;
        while offset < plaintext.len() {
            let end = std::cmp::min(offset + chunk_size, plaintext.len());
            let is_final = end == plaintext.len();
            let chunk_ct = encryptor
                .push(&plaintext[offset..end], is_final)
                .expect("push failed");
            ciphertext.extend_from_slice(&chunk_ct);
            offset = end;
        }

        // Decrypt chunk by chunk
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let mut decrypted = Vec::new();
        let mut ct_offset = 0;

        while ct_offset < ciphertext.len() {
            let chunk_end = std::cmp::min(ct_offset + chunk_size + ABYTES, ciphertext.len());
            let (chunk_pt, tag) = decryptor
                .pull(&ciphertext[ct_offset..chunk_end])
                .expect("pull failed");
            decrypted.extend_from_slice(&chunk_pt);
            ct_offset = chunk_end;

            if tag == TAG_FINAL {
                break;
            }
        }

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_tamper_detection_ciphertext() {
        // Test that tampering with ciphertext is detected
        let key = generate_test_key();
        let plaintext = b"Secret message that should not be tampered with";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let mut ciphertext = encryptor.push(plaintext, true).expect("push failed");

        // Tamper with the ciphertext (flip a bit in the middle)
        let mid = ciphertext.len() / 2;
        ciphertext[mid] ^= 0x01;

        // Decryption should fail
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let result = decryptor.pull(&ciphertext);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed error on tampered ciphertext, got {:?}",
            result
        );
    }

    #[test]
    fn test_tamper_detection_header() {
        // Test that tampering with header causes decryption failure
        let key = generate_test_key();
        let plaintext = b"Secret message";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let mut header = encryptor.header.clone();
        let ciphertext = encryptor.push(plaintext, true).expect("push failed");

        // Tamper with header
        header[0] ^= 0x01;

        // Decryption should fail
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let result = decryptor.pull(&ciphertext);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed error on tampered header, got {:?}",
            result
        );
    }

    #[test]
    fn test_tamper_detection_mac() {
        // Test that tampering with MAC (last 16 bytes) is detected
        let key = generate_test_key();
        let plaintext = b"Secret message";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let mut ciphertext = encryptor.push(plaintext, true).expect("push failed");

        // Tamper with MAC (last byte)
        let last = ciphertext.len() - 1;
        ciphertext[last] ^= 0x01;

        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let result = decryptor.pull(&ciphertext);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed error on tampered MAC, got {:?}",
            result
        );
    }

    #[test]
    fn test_wrong_key() {
        // Test that wrong key fails decryption
        let key = generate_test_key();
        let wrong_key = [0x43u8; KEY_BYTES];
        let plaintext = b"Secret message";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor.push(plaintext, true).expect("push failed");

        let mut decryptor =
            StreamDecryptor::new(&header, &wrong_key).expect("decryptor creation failed");
        let result = decryptor.pull(&ciphertext);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed error with wrong key, got {:?}",
            result
        );
    }

    #[test]
    fn test_stream_tag_enum() {
        // Test StreamTag conversions
        assert_eq!(StreamTag::Message.as_byte(), TAG_MESSAGE);
        assert_eq!(StreamTag::Push.as_byte(), TAG_PUSH);
        assert_eq!(StreamTag::Rekey.as_byte(), TAG_REKEY);
        assert_eq!(StreamTag::Final.as_byte(), TAG_FINAL);

        assert!(!StreamTag::Message.is_final());
        assert!(!StreamTag::Push.is_final());
        assert!(!StreamTag::Rekey.is_final());
        assert!(StreamTag::Final.is_final());

        // Test TryFrom<u8>
        assert_eq!(StreamTag::try_from(0x00).unwrap(), StreamTag::Message);
        assert_eq!(StreamTag::try_from(0x01).unwrap(), StreamTag::Push);
        assert_eq!(StreamTag::try_from(0x02).unwrap(), StreamTag::Rekey);
        assert_eq!(StreamTag::try_from(0x03).unwrap(), StreamTag::Final);
        assert!(StreamTag::try_from(0x04).is_err());
    }

    #[test]
    fn test_pull_typed() {
        // Test the typed pull methods
        let key = generate_test_key();
        let plaintext = b"Test message";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor.push(plaintext, true).expect("push failed");

        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let (decrypted, tag) = decryptor
            .pull_typed(&ciphertext)
            .expect("pull_typed failed");

        assert_eq!(decrypted, plaintext);
        assert_eq!(tag, StreamTag::Final);
        assert!(tag.is_final());
    }

    #[test]
    fn test_constants_match_upstream() {
        // Verify our constants match the upstream crate
        assert_eq!(HEADER_BYTES, 24);
        assert_eq!(KEY_BYTES, 32);
        assert_eq!(ABYTES, 17);

        // Verify tag values match libsodium spec
        assert_eq!(TAG_MESSAGE, 0x00);
        assert_eq!(TAG_PUSH, 0x01);
        assert_eq!(TAG_REKEY, 0x02);
        assert_eq!(TAG_FINAL, 0x03);
    }

    #[test]
    fn test_estimate_encrypted_size() {
        // Empty: just ABYTES for the FINAL tag
        assert_eq!(estimate_encrypted_size(0), ABYTES);

        // Small data: data + ABYTES
        assert_eq!(estimate_encrypted_size(100), 100 + ABYTES);

        // Exact chunk size: one FINAL chunk
        assert_eq!(
            estimate_encrypted_size(ENCRYPTION_CHUNK_SIZE),
            DECRYPTION_CHUNK_SIZE
        );

        // Multiple chunks
        let two_chunks_plus = ENCRYPTION_CHUNK_SIZE * 2 + 500;
        let expected = 2 * DECRYPTION_CHUNK_SIZE + 500 + ABYTES;
        assert_eq!(estimate_encrypted_size(two_chunks_plus), expected);
    }

    #[test]
    fn test_validate_sizes() {
        assert!(validate_sizes(0, ABYTES));
        assert!(validate_sizes(100, 100 + ABYTES));
        assert!(validate_sizes(ENCRYPTION_CHUNK_SIZE, DECRYPTION_CHUNK_SIZE));
        assert!(!validate_sizes(100, 100)); // Missing ABYTES
        assert!(!validate_sizes(100, 200)); // Wrong size
    }

    #[test]
    fn test_in_place_encryption() {
        // Test the in-place encryption API
        let key = generate_test_key();
        let plaintext = b"Test in-place encryption";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();

        let mut buffer = plaintext.to_vec();
        encryptor
            .push_in_place(&mut buffer, &[], true)
            .expect("push_in_place failed");

        assert_eq!(buffer.len(), plaintext.len() + ABYTES);

        // Decrypt in-place
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let tag = decryptor
            .pull_in_place(&mut buffer, &[])
            .expect("pull_in_place failed");

        assert_eq!(tag, TAG_FINAL);
        assert_eq!(buffer, plaintext);
    }

    #[test]
    fn test_in_place_typed() {
        // Test the typed in-place decryption API
        let key = generate_test_key();
        let plaintext = b"Test typed in-place";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();

        let mut buffer = plaintext.to_vec();
        encryptor
            .push_in_place(&mut buffer, &[], true)
            .expect("push_in_place failed");

        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let tag = decryptor
            .pull_in_place_typed(&mut buffer, &[])
            .expect("pull_in_place_typed failed");

        assert_eq!(tag, StreamTag::Final);
        assert!(tag.is_final());
        assert_eq!(buffer, plaintext);
    }

    #[test]
    fn test_libsodium_interop_vector() {
        // Test vector derived from libsodium's crypto_secretstream_xchacha20poly1305
        // Key: 32 bytes of 0x00
        // Header: 24 bytes of 0x00 (for deterministic testing)
        // This tests that our implementation produces compatible output format

        // Since we use random headers, we test format compatibility by:
        // 1. Encrypting with a known key
        // 2. Verifying the output structure (header size, ciphertext overhead)
        let key = [0u8; KEY_BYTES];
        let plaintext = b"libsodium interop test";

        let encrypted = encrypt(plaintext, &key).expect("encrypt failed");

        // Verify structure
        assert_eq!(encrypted.decryption_header.len(), HEADER_BYTES);
        assert_eq!(encrypted.encrypted_data.len(), plaintext.len() + ABYTES);

        // Verify roundtrip
        let decrypted = decrypt_stream(&encrypted, &key).expect("decrypt failed");
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_file_encrypt_decrypt_roundtrip() {
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..10000).map(|i| (i % 256) as u8).collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        let (returned_key, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        assert_eq!(returned_key, key);
        assert_eq!(header.len(), HEADER_BYTES);

        let mut decrypted = Vec::new();
        let mut enc_reader = Cursor::new(&encrypted);
        decrypt_file(&mut enc_reader, &mut decrypted, &header, &key).expect("decrypt_file failed");

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_file_encrypt_decrypt_multi_chunk() {
        // Regression test: exercises multiple chunks to ensure the refactored
        // encrypt_file/decrypt_file functions with in-place APIs work correctly.
        // We use 2x ENCRYPTION_CHUNK_SIZE + extra bytes to test:
        // - Multiple full chunks with MESSAGE tag
        // - Final partial chunk with FINAL tag
        // - Lookahead logic for determining is_final flag
        let key = generate_test_key();

        // 2 full chunks + 1000 bytes (total: ~8MB + 1000)
        let size = ENCRYPTION_CHUNK_SIZE * 2 + 1000;
        let plaintext: Vec<u8> = (0..size).map(|i| (i % 256) as u8).collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        let (returned_key, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        assert_eq!(returned_key, key);
        assert_eq!(header.len(), HEADER_BYTES);

        // Verify ciphertext size: 2 full chunks + 1 partial chunk
        // Each chunk adds ABYTES overhead
        let expected_ct_size = 2 * DECRYPTION_CHUNK_SIZE + (1000 + ABYTES);
        assert_eq!(
            encrypted.len(),
            expected_ct_size,
            "Ciphertext size mismatch"
        );

        let mut decrypted = Vec::new();
        let mut enc_reader = Cursor::new(&encrypted);
        decrypt_file(&mut enc_reader, &mut decrypted, &header, &key).expect("decrypt_file failed");

        assert_eq!(plaintext.len(), decrypted.len());
        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_file_encrypt_decrypt_exact_chunk_boundary() {
        // Edge case: plaintext exactly at chunk boundary.
        // The last full chunk must be tagged FINAL (no extra empty FINAL chunk).
        let key = generate_test_key();

        let plaintext: Vec<u8> = (0..ENCRYPTION_CHUNK_SIZE)
            .map(|i| (i % 256) as u8)
            .collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        let (_, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        assert_eq!(encrypted.len(), DECRYPTION_CHUNK_SIZE);
        // Should match estimate
        assert_eq!(encrypted.len(), estimate_encrypted_size(plaintext.len()));

        let mut decrypted = Vec::new();
        let mut enc_reader = Cursor::new(&encrypted);
        decrypt_file(&mut enc_reader, &mut decrypted, &header, &key).expect("decrypt_file failed");

        assert_eq!(plaintext, decrypted);
    }

    #[test]
    fn test_file_encrypt_decrypt_empty() {
        // Edge case: empty file
        let key = generate_test_key();
        let plaintext: Vec<u8> = Vec::new();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        let (_, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        // Should be exactly one empty FINAL chunk
        assert_eq!(encrypted.len(), ABYTES);

        let mut decrypted = Vec::new();
        let mut enc_reader = Cursor::new(&encrypted);
        decrypt_file(&mut enc_reader, &mut decrypted, &header, &key).expect("decrypt_file failed");

        assert!(decrypted.is_empty());
    }

    #[test]
    fn test_decrypt_file_data() {
        let key = generate_test_key();
        let plaintext = b"Test decrypt_file_data function";

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(plaintext.as_slice());
        let (_, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        let decrypted =
            decrypt_file_data(&encrypted, &header, &key).expect("decrypt_file_data failed");
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_additional_data() {
        // Test that additional authenticated data works correctly
        let key = generate_test_key();
        let plaintext = b"Message with AAD";
        let aad = b"additional authenticated data";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor
            .push_with_ad(plaintext, aad, true)
            .expect("push_with_ad failed");

        // Decrypt with correct AAD
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let (decrypted, tag) = decryptor
            .pull_with_ad(&ciphertext, aad)
            .expect("pull_with_ad failed");

        assert_eq!(decrypted, plaintext);
        assert_eq!(tag, TAG_FINAL);
    }

    #[test]
    fn test_additional_data_mismatch() {
        // Test that mismatched AAD causes decryption failure
        let key = generate_test_key();
        let plaintext = b"Message with AAD";
        let aad = b"correct aad";
        let wrong_aad = b"wrong aad";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor
            .push_with_ad(plaintext, aad, true)
            .expect("push_with_ad failed");

        // Decrypt with wrong AAD should fail
        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let result = decryptor.pull_with_ad(&ciphertext, wrong_aad);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed with wrong AAD, got {:?}",
            result
        );
    }

    #[test]
    fn test_ciphertext_too_short() {
        // Test that ciphertext shorter than ABYTES is rejected
        let key = generate_test_key();
        let header = [0u8; HEADER_BYTES];
        let short_ciphertext = [0u8; ABYTES - 1];

        let mut decryptor = StreamDecryptor::new(&header, &key).expect("decryptor creation failed");
        let result = decryptor.pull(&short_ciphertext);

        assert!(
            matches!(result, Err(CryptoError::StreamPullFailed)),
            "Expected StreamPullFailed for short ciphertext, got {:?}",
            result
        );
    }

    #[test]
    fn test_invalid_key_length() {
        let short_key = [0u8; KEY_BYTES - 1];
        let result = StreamEncryptor::new(&short_key);

        assert!(matches!(
            result,
            Err(CryptoError::InvalidKeyLength {
                expected: 32,
                actual: 31
            })
        ));
    }

    #[test]
    fn test_invalid_header_length() {
        let key = generate_test_key();
        let short_header = [0u8; HEADER_BYTES - 1];
        let result = StreamDecryptor::new(&short_header, &key);

        assert!(matches!(
            result,
            Err(CryptoError::InvalidHeaderLength {
                expected: 24,
                actual: 23
            })
        ));
    }

    // ============ Truncation detection tests for decrypt_file / decrypt ============

    #[test]
    fn test_decrypt_file_truncation_empty_ciphertext() {
        // Test that decrypt_file detects truncation when there's no ciphertext at all
        let key = generate_test_key();
        let header = [0u8; HEADER_BYTES];
        let empty_ciphertext: &[u8] = &[];

        let mut reader = Cursor::new(empty_ciphertext);
        let mut output = Vec::new();
        let result = decrypt_file(&mut reader, &mut output, &header, &key);

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated for empty ciphertext, got {:?}",
            result
        );
    }

    #[test]
    fn test_decrypt_file_truncation_at_chunk_boundary() {
        // SECURITY TEST: Verify decrypt_file detects truncation at chunk boundary
        // This tests the case where we have a valid MESSAGE chunk but no FINAL chunk
        let key = generate_test_key();
        let plaintext = b"Test message for truncation detection";

        // Create a valid encrypted chunk with MESSAGE tag (not FINAL)
        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let encrypted_chunk = encryptor.push(plaintext, false).expect("push failed"); // is_final = false

        // Decrypt should fail because there's no FINAL tag
        let mut reader = Cursor::new(&encrypted_chunk);
        let mut output = Vec::new();
        let result = decrypt_file(&mut reader, &mut output, &header, &key);

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated at chunk boundary, got {:?}",
            result
        );
    }

    #[test]
    fn test_decrypt_file_truncation_via_encrypt_file() {
        // Test truncation detection when truncating output from encrypt_file
        // encrypt_file uses lookahead to mark the last chunk as FINAL
        // So we simulate truncation by only keeping part of the ciphertext
        let key = generate_test_key();
        let plaintext = b"Test data that will be truncated";

        // Encrypt using encrypt_file to get proper format
        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(plaintext.as_slice());
        let (_, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        // Truncate the ciphertext (remove the last few bytes which contain MAC/tag info)
        let truncated_len = encrypted.len() - 5;
        let truncated = &encrypted[..truncated_len];

        // Decrypt should fail with authentication error (truncated ciphertext)
        let mut reader = Cursor::new(truncated);
        let mut output = Vec::new();
        let result = decrypt_file(&mut reader, &mut output, &header, &key);

        // The truncated ciphertext will fail MAC verification
        assert!(
            result.is_err(),
            "Expected error from truncated ciphertext, got {:?}",
            result
        );
    }

    #[test]
    fn test_decrypt_file_valid_single_chunk() {
        // Verify that a valid single FINAL chunk works
        let key = generate_test_key();
        let plaintext = b"Valid single chunk";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor.push(plaintext, true).expect("push failed");

        let mut reader = Cursor::new(&ciphertext);
        let mut output = Vec::new();
        decrypt_file(&mut reader, &mut output, &header, &key).expect("decrypt_file failed");

        assert_eq!(output, plaintext);
    }

    #[test]
    fn test_decrypt_file_via_encrypt_file_roundtrip() {
        // Verify that encrypt_file + decrypt_file work together properly
        // encrypt_file creates properly formatted chunks with FINAL tag
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..5000).map(|i| (i % 256) as u8).collect();

        // Encrypt using encrypt_file
        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        let (_, header) =
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        // Decrypt using decrypt_file
        let mut reader = Cursor::new(&encrypted);
        let mut output = Vec::new();
        decrypt_file(&mut reader, &mut output, &header, &key).expect("decrypt_file failed");

        assert_eq!(plaintext, output);
    }

    #[test]
    fn test_decrypt_file_data_truncation() {
        // Test that decrypt_file_data also detects truncation (it calls decrypt_file)
        let key = generate_test_key();
        let plaintext = b"Test decrypt_file_data truncation";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let encrypted_chunk = encryptor.push(plaintext, false).expect("push failed"); // is_final = false

        let result = decrypt_file_data(&encrypted_chunk, &header, &key);

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated from decrypt_file_data, got {:?}",
            result
        );
    }

    #[test]
    fn test_decrypt_oneshot_requires_final_tag() {
        // Test that the one-shot decrypt() helper requires TAG_FINAL
        let key = generate_test_key();
        let plaintext = b"Test one-shot decrypt";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();

        // Encrypt with MESSAGE tag (not FINAL)
        let ciphertext = encryptor.push(plaintext, false).expect("push failed");

        let result = decrypt(&ciphertext, &header, &key);

        assert!(
            matches!(result, Err(CryptoError::StreamTruncated)),
            "Expected StreamTruncated for non-FINAL tag in decrypt(), got {:?}",
            result
        );
    }

    #[test]
    fn test_decrypt_oneshot_valid_final_tag() {
        // Verify that decrypt() works with proper FINAL tag
        let key = generate_test_key();
        let plaintext = b"Test one-shot decrypt with FINAL";

        let mut encryptor = StreamEncryptor::new(&key).expect("encryptor creation failed");
        let header = encryptor.header.clone();
        let ciphertext = encryptor.push(plaintext, true).expect("push failed");

        let decrypted = decrypt(&ciphertext, &header, &key).expect("decrypt failed");
        assert_eq!(decrypted, plaintext);
    }

    // ============ Size estimation consistency tests ============

    #[test]
    fn test_encrypt_file_size_matches_estimate_empty() {
        // Empty file: encrypt_file output should match estimate_encrypted_size
        let key = generate_test_key();
        let plaintext: Vec<u8> = Vec::new();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        let expected = estimate_encrypted_size(plaintext.len());
        assert_eq!(
            encrypted.len(),
            expected,
            "Empty file: encrypt_file output {} != estimate {}",
            encrypted.len(),
            expected
        );
        assert_eq!(encrypted.len(), ABYTES);
    }

    #[test]
    fn test_encrypt_file_size_matches_estimate_small() {
        // Small file (< chunk size): encrypt_file output should match estimate
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..1000).map(|i| (i % 256) as u8).collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        let expected = estimate_encrypted_size(plaintext.len());
        assert_eq!(
            encrypted.len(),
            expected,
            "Small file: encrypt_file output {} != estimate {}",
            encrypted.len(),
            expected
        );
        assert_eq!(encrypted.len(), plaintext.len() + ABYTES);
    }

    #[test]
    fn test_encrypt_file_size_matches_estimate_exact_chunk() {
        // Exact chunk size: encrypt_file output should match estimate.
        // The last full chunk should be tagged FINAL.
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..ENCRYPTION_CHUNK_SIZE)
            .map(|i| (i % 256) as u8)
            .collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        let expected = estimate_encrypted_size(plaintext.len());
        assert_eq!(
            encrypted.len(),
            expected,
            "Exact chunk: encrypt_file output {} != estimate {}",
            encrypted.len(),
            expected
        );
        assert_eq!(encrypted.len(), DECRYPTION_CHUNK_SIZE);
    }

    #[test]
    fn test_encrypt_file_size_matches_estimate_exact_two_chunks() {
        // Exact two chunks: encrypt_file output should match estimate
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..ENCRYPTION_CHUNK_SIZE * 2)
            .map(|i| (i % 256) as u8)
            .collect();

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(&plaintext);
        encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

        let expected = estimate_encrypted_size(plaintext.len());
        assert_eq!(
            encrypted.len(),
            expected,
            "Two chunks: encrypt_file output {} != estimate {}",
            encrypted.len(),
            expected
        );
        assert_eq!(encrypted.len(), 2 * DECRYPTION_CHUNK_SIZE);
    }

    #[test]
    fn test_encrypt_file_with_md5() {
        let key = generate_test_key();
        let plaintext = b"Encrypt with md5";

        let mut encrypted = Vec::new();
        let mut reader = Cursor::new(plaintext);
        let (returned_key, header, md5_bytes) =
            encrypt_file_with_md5(&mut reader, &mut encrypted, Some(&key))
                .expect("encrypt_file_with_md5 failed");

        assert_eq!(returned_key, key.to_vec());
        assert_eq!(header.len(), HEADER_BYTES);

        let mut hasher = Md5::new();
        hasher.update(&encrypted);
        let expected = hasher.finalize();
        assert_eq!(md5_bytes.as_slice(), expected.as_slice());
    }

    #[test]
    fn test_streaming_encryptor_size_matches_estimate_exact_chunk() {
        // Verify StreamingEncryptor also matches estimate for exact chunk size
        let key = generate_test_key();
        let plaintext: Vec<u8> = (0..ENCRYPTION_CHUNK_SIZE)
            .map(|i| (i % 256) as u8)
            .collect();

        let mut encrypted = Vec::new();
        {
            let mut encryptor =
                StreamingEncryptor::new(&key, &mut encrypted).expect("encryptor creation failed");
            encryptor.write(&plaintext).expect("write failed");
            encryptor.finish().expect("finish failed");
        }

        // Remove header to compare ciphertext size
        let ciphertext_len = encrypted.len() - HEADER_BYTES;
        let expected = estimate_encrypted_size(plaintext.len());
        assert_eq!(
            ciphertext_len, expected,
            "StreamingEncryptor: ciphertext {} != estimate {}",
            ciphertext_len, expected
        );
    }

    #[test]
    fn test_encrypt_file_and_streaming_encryptor_same_size() {
        // Verify encrypt_file and StreamingEncryptor produce same ciphertext sizes
        // for the edge case of exact chunk multiple
        let key = generate_test_key();

        for multiplier in [0, 1, 2, 3] {
            let extra = [0, 1, 100, ENCRYPTION_CHUNK_SIZE / 2];
            for &e in &extra {
                let size = ENCRYPTION_CHUNK_SIZE * multiplier + e;
                if size > ENCRYPTION_CHUNK_SIZE * 3 {
                    continue; // Skip very large sizes for test speed
                }
                let plaintext: Vec<u8> = (0..size).map(|i| (i % 256) as u8).collect();

                // encrypt_file
                let mut enc_file = Vec::new();
                let mut reader = Cursor::new(&plaintext);
                encrypt_file(&mut reader, &mut enc_file, Some(&key)).expect("encrypt_file failed");

                // StreamingEncryptor
                let mut enc_stream = Vec::new();
                {
                    let mut encryptor =
                        StreamingEncryptor::new(&key, &mut enc_stream).expect("encryptor failed");
                    encryptor.write(&plaintext).expect("write failed");
                    encryptor.finish().expect("finish failed");
                }
                let stream_ciphertext_len = enc_stream.len() - HEADER_BYTES;

                let expected = estimate_encrypted_size(size);

                assert_eq!(
                    enc_file.len(),
                    expected,
                    "encrypt_file: size={}, output {} != estimate {}",
                    size,
                    enc_file.len(),
                    expected
                );

                assert_eq!(
                    stream_ciphertext_len, expected,
                    "StreamingEncryptor: size={}, output {} != estimate {}",
                    size, stream_ciphertext_len, expected
                );
            }
        }
    }

    #[test]
    fn test_validate_sizes_with_encrypt_file() {
        // Verify validate_sizes works correctly with encrypt_file output
        let key = generate_test_key();

        for size in [0, 100, ENCRYPTION_CHUNK_SIZE, ENCRYPTION_CHUNK_SIZE + 500] {
            let plaintext: Vec<u8> = (0..size).map(|i| (i % 256) as u8).collect();

            let mut encrypted = Vec::new();
            let mut reader = Cursor::new(&plaintext);
            encrypt_file(&mut reader, &mut encrypted, Some(&key)).expect("encrypt_file failed");

            assert!(
                validate_sizes(plaintext.len(), encrypted.len()),
                "validate_sizes failed for size {}",
                size
            );
        }
    }
}
