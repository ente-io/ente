//! Sealed box (anonymous public-key encryption).
//!
//! Sealed boxes provide encryption to a recipient's public key without revealing
//! the sender's identity. This is achieved using an ephemeral key pair.

use crate::crypto::Result;

pub mod post_quant;
pub mod pre_quant;

pub use pre_quant::{PUBLIC_KEY_BYTES, SEAL_BYTES, SEAL_OVERHEAD, SECRET_KEY_BYTES};

fn split_key(key: &[u8]) -> (&[u8], &[u8]) {
    if key.len() <= PUBLIC_KEY_BYTES {
        return (key, &[]);
    }
    key.split_at(PUBLIC_KEY_BYTES)
}

/// Seal (encrypt) plaintext for a recipient's public key.
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `recipient_pk` - Recipient's pre-quant key, or pre and post-quant public keys concatenated.
///
/// # Returns
/// Sealed ciphertext.
pub fn seal(plaintext: &[u8], recipient_pk: &[u8]) -> Result<Vec<u8>> {
    let (pre_quant_pk, post_quant_pk) = split_key(recipient_pk);
    if post_quant_pk.is_empty() {
        return pre_quant::seal(plaintext, pre_quant_pk);
    }
    let post_quant_ciphertext = post_quant::seal(plaintext, post_quant_pk)?;
    pre_quant::seal(&post_quant_ciphertext, pre_quant_pk)
}

/// Open (decrypt) a sealed box.
///
/// # Arguments
/// * `ciphertext` - Sealed data.
/// * `recipient_pk` - Recipient's pre-quant key, or pre and post-quant public keys concatenated.
/// * `recipient_sk` - Recipient's pre-quant key, or pre and post-quant secret keys concatenated.
///
/// # Returns
/// Decrypted plaintext.
pub fn open(ciphertext: &[u8], recipient_pk: &[u8], recipient_sk: &[u8]) -> Result<Vec<u8>> {
    let (pre_quant_pk, post_quant_pk) = split_key(recipient_pk);
    let (pre_quant_sk, post_quant_sk) = split_key(recipient_sk);
    let pre_quant_plaintext = pre_quant::open(ciphertext, pre_quant_pk, pre_quant_sk)?;
    if post_quant_pk.is_empty() && post_quant_sk.is_empty() {
        return Ok(pre_quant_plaintext);
    }
    post_quant::open(&pre_quant_plaintext, post_quant_pk, post_quant_sk)
}
