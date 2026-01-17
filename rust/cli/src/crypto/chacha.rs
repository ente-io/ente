use crate::{Error, Result};
use libsodium_sys as sodium;

/// Decrypt data encrypted with ChaCha20-Poly1305
pub fn decrypt_chacha(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if nonce.len() != sodium::crypto_aead_xchacha20poly1305_ietf_NPUBBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid nonce length: expected {}, got {}",
            sodium::crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
            nonce.len()
        )));
    }

    if key.len() != sodium::crypto_aead_xchacha20poly1305_ietf_KEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid key length: expected {}, got {}",
            sodium::crypto_aead_xchacha20poly1305_ietf_KEYBYTES,
            key.len()
        )));
    }

    let mut plaintext =
        vec![0u8; ciphertext.len() - sodium::crypto_aead_xchacha20poly1305_ietf_ABYTES as usize];
    let mut plaintext_len: u64 = 0;

    let result = unsafe {
        sodium::crypto_aead_xchacha20poly1305_ietf_decrypt(
            plaintext.as_mut_ptr(),
            &mut plaintext_len,
            std::ptr::null_mut(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            std::ptr::null(),
            0,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto(
            "Failed to decrypt with ChaCha20-Poly1305".into(),
        ));
    }

    plaintext.truncate(plaintext_len as usize);
    Ok(plaintext)
}

/// Encrypt data with ChaCha20-Poly1305
pub fn encrypt_chacha(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if nonce.len() != sodium::crypto_aead_xchacha20poly1305_ietf_NPUBBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid nonce length: expected {}, got {}",
            sodium::crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
            nonce.len()
        )));
    }

    if key.len() != sodium::crypto_aead_xchacha20poly1305_ietf_KEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid key length: expected {}, got {}",
            sodium::crypto_aead_xchacha20poly1305_ietf_KEYBYTES,
            key.len()
        )));
    }

    let mut ciphertext =
        vec![0u8; plaintext.len() + sodium::crypto_aead_xchacha20poly1305_ietf_ABYTES as usize];
    let mut ciphertext_len: u64 = 0;

    let result = unsafe {
        sodium::crypto_aead_xchacha20poly1305_ietf_encrypt(
            ciphertext.as_mut_ptr(),
            &mut ciphertext_len,
            plaintext.as_ptr(),
            plaintext.len() as u64,
            std::ptr::null(),
            0,
            std::ptr::null(),
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto(
            "Failed to encrypt with ChaCha20-Poly1305".into(),
        ));
    }

    ciphertext.truncate(ciphertext_len as usize);
    Ok(ciphertext)
}

/// Open a sealed box (decrypt with public key crypto)
pub fn sealed_box_open(ciphertext: &[u8], public_key: &[u8], secret_key: &[u8]) -> Result<Vec<u8>> {
    if public_key.len() != sodium::crypto_box_PUBLICKEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid public key length: expected {}, got {}",
            sodium::crypto_box_PUBLICKEYBYTES,
            public_key.len()
        )));
    }

    if secret_key.len() != sodium::crypto_box_SECRETKEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid secret key length: expected {}, got {}",
            sodium::crypto_box_SECRETKEYBYTES,
            secret_key.len()
        )));
    }

    if ciphertext.len() < sodium::crypto_box_SEALBYTES as usize {
        return Err(Error::Crypto("Ciphertext too short".into()));
    }

    let mut plaintext = vec![0u8; ciphertext.len() - sodium::crypto_box_SEALBYTES as usize];

    let result = unsafe {
        sodium::crypto_box_seal_open(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            public_key.as_ptr(),
            secret_key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to open sealed box".into()));
    }

    Ok(plaintext)
}

/// Open a secret box (decrypt with XSalsa20-Poly1305)
pub fn secret_box_open(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if nonce.len() != sodium::crypto_secretbox_NONCEBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid nonce length: expected {}, got {}",
            sodium::crypto_secretbox_NONCEBYTES,
            nonce.len()
        )));
    }

    if key.len() != sodium::crypto_secretbox_KEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid key length: expected {}, got {}",
            sodium::crypto_secretbox_KEYBYTES,
            key.len()
        )));
    }

    let mut plaintext = vec![0u8; ciphertext.len() - sodium::crypto_secretbox_MACBYTES as usize];

    let result = unsafe {
        sodium::crypto_secretbox_open_easy(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to open secret box".into()));
    }

    Ok(plaintext)
}

/// Seal a secret box (encrypt with XSalsa20-Poly1305)
pub fn secret_box_seal(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if nonce.len() != sodium::crypto_secretbox_NONCEBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid nonce length: expected {}, got {}",
            sodium::crypto_secretbox_NONCEBYTES,
            nonce.len()
        )));
    }

    if key.len() != sodium::crypto_secretbox_KEYBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid key length: expected {}, got {}",
            sodium::crypto_secretbox_KEYBYTES,
            key.len()
        )));
    }

    let mut ciphertext = vec![0u8; plaintext.len() + sodium::crypto_secretbox_MACBYTES as usize];

    let result = unsafe {
        sodium::crypto_secretbox_easy(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to seal secret box".into()));
    }

    Ok(ciphertext)
}
