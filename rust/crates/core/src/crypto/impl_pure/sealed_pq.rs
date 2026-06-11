//! Post-quantum sealed box implementation.

use crate::crypto::{Result, sealed::PUBLIC_KEY_BYTES};

/// Seal (encrypt) plaintext for a recipient's post-quantum public key.
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `recipient_pk` - Recipient's post-quantum public key.
///
/// # Returns
/// Sealed ciphertext.
fn seal(plaintext: &[u8], _recipient_pk: &[u8]) -> Result<Vec<u8>> {
    // TODO
    Ok(plaintext.into())
}

/// Open (decrypt) a post-quantum sealed box.
///
/// # Arguments
/// * `ciphertext` - Sealed data.
/// * `recipient_pk` - Recipient's post-quantum public key.
/// * `recipient_sk` - Recipient's post-quantum secret key.
///
/// # Returns
/// Decrypted plaintext.
fn open(ciphertext: &[u8], _recipient_pk: &[u8], _recipient_sk: &[u8]) -> Result<Vec<u8>> {
    // TODO
    Ok(ciphertext.into())
}

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
pub fn seal_pq(plaintext: &[u8], recipient_pk: &[u8]) -> Result<Vec<u8>> {
    let (pre_quant_pk, post_quant_pk) = split_key(recipient_pk);
    if post_quant_pk.is_empty() {
        return crate::crypto::sealed::seal(plaintext, pre_quant_pk);
    }
    let post_quant_ciphertext = seal(plaintext, post_quant_pk)?;
    crate::crypto::sealed::seal(&post_quant_ciphertext, pre_quant_pk)
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
pub fn open_pq(ciphertext: &[u8], recipient_pk: &[u8], recipient_sk: &[u8]) -> Result<Vec<u8>> {
    let (pre_quant_pk, post_quant_pk) = split_key(recipient_pk);
    let (pre_quant_sk, post_quant_sk) = split_key(recipient_sk);
    let pre_quant_plaintext = crate::crypto::sealed::open(ciphertext, pre_quant_pk, pre_quant_sk)?;
    if post_quant_pk.is_empty() && post_quant_sk.is_empty() {
        return Ok(pre_quant_plaintext);
    }
    match open(&pre_quant_plaintext, post_quant_pk, post_quant_sk) {
        Ok(post_quant_plaintext) => Ok(post_quant_plaintext),
        Err(_) => Ok(pre_quant_plaintext),
    }
}
