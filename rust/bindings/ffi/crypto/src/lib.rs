use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::panic::{self, AssertUnwindSafe};
use std::ptr;

use ente_core::crypto;

const STATUS_OK: c_int = 0;
const STATUS_ERROR: c_int = 1;

fn clear_error(out_error: *mut *mut c_char) {
    if !out_error.is_null() {
        unsafe {
            *out_error = ptr::null_mut();
        }
    }
}

fn write_error(out_error: *mut *mut c_char, message: impl Into<String>) {
    if out_error.is_null() {
        return;
    }

    let c_message = CString::new(message.into().replace('\0', " ")).unwrap();

    unsafe {
        *out_error = c_message.into_raw();
    }
}

fn run_ffi(out_error: *mut *mut c_char, f: impl FnOnce() -> Result<(), String>) -> c_int {
    clear_error(out_error);

    match panic::catch_unwind(AssertUnwindSafe(f)) {
        Ok(Ok(())) => STATUS_OK,
        Ok(Err(message)) => {
            write_error(out_error, message);
            STATUS_ERROR
        }
        Err(_) => {
            write_error(out_error, "panic in Rust crypto FFI");
            STATUS_ERROR
        }
    }
}

unsafe fn c_input(input: *const c_char, field_name: &str) -> Result<String, String> {
    if input.is_null() {
        return Err(format!("{field_name} is null"));
    }

    unsafe { CStr::from_ptr(input) }
        .to_str()
        .map(|v| v.to_owned())
        .map_err(|_| format!("{field_name} is not valid UTF-8"))
}

unsafe fn c_output(
    output: *mut *mut c_char,
    value: String,
    field_name: &str,
) -> Result<(), String> {
    if output.is_null() {
        return Err(format!("{field_name} is null"));
    }

    let c_value = CString::new(value).map_err(|_| format!("{field_name} contains NUL"))?;
    unsafe {
        *output = c_value.into_raw();
    }
    Ok(())
}

fn decode_b64(input: &str, field_name: &str) -> Result<Vec<u8>, String> {
    crypto::decode_b64(input).map_err(|e| format!("{field_name}: {e}"))
}

/// Frees a string returned by this library.
///
/// # Safety
///
/// `ptr` must be null or a pointer returned by an `ente_crypto_*` function.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ente_crypto_string_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}

/// Generates a public/secret keypair and returns both keys as base64 strings.
///
/// # Safety
///
/// Output pointers must be valid writable string slots. Returned strings must
/// be freed with `ente_crypto_string_free`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ente_crypto_generate_keypair_b64(
    out_public_key_b64: *mut *mut c_char,
    out_secret_key_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let secret_key = crypto::SecretKey::generate();
        let public_key = secret_key.public_key();
        unsafe {
            c_output(
                out_public_key_b64,
                crypto::encode_b64(public_key.as_bytes()),
                "out_public_key_b64",
            )?;
            c_output(
                out_secret_key_b64,
                crypto::encode_b64(secret_key.as_bytes()),
                "out_secret_key_b64",
            )?;
        }
        Ok(())
    })
}

/// Decrypts a SecretBox payload and returns the plaintext as a base64 string.
///
/// # Safety
///
/// Input pointers must be non-null, valid UTF-8 C strings. Output pointers must
/// be valid writable string slots. Returned strings must be freed with
/// `ente_crypto_string_free`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ente_crypto_secretbox_open_b64(
    ciphertext_b64: *const c_char,
    nonce_b64: *const c_char,
    key_b64: *const c_char,
    out_plaintext_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let (ciphertext_b64, nonce_b64, key_b64) = unsafe {
            (
                c_input(ciphertext_b64, "ciphertext_b64")?,
                c_input(nonce_b64, "nonce_b64")?,
                c_input(key_b64, "key_b64")?,
            )
        };
        let ciphertext = decode_b64(&ciphertext_b64, "ciphertext_b64")?;
        let nonce = decode_b64(&nonce_b64, "nonce_b64")?;
        let key = decode_b64(&key_b64, "key_b64")?;
        let nonce = crypto::Nonce::try_from_slice(&nonce).map_err(|e| e.to_string())?;
        let key = crypto::Key::try_from_slice(&key).map_err(|e| e.to_string())?;
        let plaintext =
            crypto::secretbox::decrypt(&ciphertext, &nonce, &key).map_err(|e| e.to_string())?;

        unsafe {
            c_output(
                out_plaintext_b64,
                crypto::encode_b64(&plaintext),
                "out_plaintext_b64",
            )?;
        }
        Ok(())
    })
}

/// Decrypts a SealedBox payload and returns the plaintext as a base64 string.
///
/// # Safety
///
/// Input pointers must be non-null, valid UTF-8 C strings. Output pointers must
/// be valid writable string slots. Returned strings must be freed with
/// `ente_crypto_string_free`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ente_crypto_sealed_box_open_b64(
    ciphertext_b64: *const c_char,
    public_key_b64: *const c_char,
    secret_key_b64: *const c_char,
    out_plaintext_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let (ciphertext_b64, public_key_b64, secret_key_b64) = unsafe {
            (
                c_input(ciphertext_b64, "ciphertext_b64")?,
                c_input(public_key_b64, "public_key_b64")?,
                c_input(secret_key_b64, "secret_key_b64")?,
            )
        };
        let ciphertext = decode_b64(&ciphertext_b64, "ciphertext_b64")?;
        let public_key = decode_b64(&public_key_b64, "public_key_b64")?;
        let secret_key = decode_b64(&secret_key_b64, "secret_key_b64")?;
        let public_key =
            crypto::PublicKey::try_from_slice(&public_key).map_err(|e| e.to_string())?;
        let secret_key =
            crypto::SecretKey::try_from_slice(&secret_key).map_err(|e| e.to_string())?;
        let plaintext = crypto::sealed::open(&ciphertext, &public_key, &secret_key)
            .map_err(|e| e.to_string())?;

        unsafe {
            c_output(
                out_plaintext_b64,
                crypto::encode_b64(&plaintext),
                "out_plaintext_b64",
            )?;
        }
        Ok(())
    })
}

/// Decrypts a secretstream payload and returns the plaintext as a base64 string.
///
/// # Safety
///
/// Input pointers must be non-null, valid UTF-8 C strings. Output pointers must
/// be valid writable string slots. Returned strings must be freed with
/// `ente_crypto_string_free`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn ente_crypto_secretstream_decrypt_b64(
    encrypted_data_b64: *const c_char,
    decryption_header_b64: *const c_char,
    key_b64: *const c_char,
    out_plaintext_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let (encrypted_data_b64, decryption_header_b64, key_b64) = unsafe {
            (
                c_input(encrypted_data_b64, "encrypted_data_b64")?,
                c_input(decryption_header_b64, "decryption_header_b64")?,
                c_input(key_b64, "key_b64")?,
            )
        };
        let encrypted_data = decode_b64(&encrypted_data_b64, "encrypted_data_b64")?;
        let decryption_header = decode_b64(&decryption_header_b64, "decryption_header_b64")?;
        let key = decode_b64(&key_b64, "key_b64")?;
        let plaintext = crypto::stream::decrypt_file_data(
            &encrypted_data,
            &crypto::Header::try_from_slice(&decryption_header).map_err(|e| e.to_string())?,
            &crypto::Key::try_from_slice(&key).map_err(|e| e.to_string())?,
        )
        .map_err(|e| e.to_string())?;

        unsafe {
            c_output(
                out_plaintext_b64,
                crypto::encode_b64(&plaintext),
                "out_plaintext_b64",
            )?;
        }
        Ok(())
    })
}
