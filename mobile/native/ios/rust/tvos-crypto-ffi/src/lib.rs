use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::panic::{self, UnwindSafe};
use std::ptr;

use ente_core::crypto;

const STATUS_OK: c_int = 0;
const STATUS_ERROR: c_int = 1;

fn sanitize_c_string(input: String) -> String {
    let mut output = input.replace('\0', " ");
    if output.is_empty() {
        output = "unknown error".to_owned();
    }
    output
}

fn clear_error(out_error: *mut *mut c_char) {
    if out_error.is_null() {
        return;
    }
    unsafe {
        *out_error = ptr::null_mut();
    }
}

fn write_error(out_error: *mut *mut c_char, message: impl Into<String>) {
    if out_error.is_null() {
        return;
    }

    let message = sanitize_c_string(message.into());
    let c_message = CString::new(message)
        .unwrap_or_else(|_| CString::new("failed to construct error message").unwrap());

    unsafe {
        *out_error = c_message.into_raw();
    }
}

fn run_ffi(out_error: *mut *mut c_char, f: impl FnOnce() -> Result<(), String> + UnwindSafe) -> c_int {
    clear_error(out_error);

    match panic::catch_unwind(f) {
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

unsafe fn c_output(output: *mut *mut c_char, value: String, field_name: &str) -> Result<(), String> {
    if output.is_null() {
        return Err(format!("{field_name} is null"));
    }

    let value = sanitize_c_string(value);
    let c_value = CString::new(value).map_err(|_| format!("{field_name} contains interior NUL"))?;
    unsafe {
        *output = c_value.into_raw();
    }
    Ok(())
}

fn decode_b64(input: &str, field_name: &str) -> Result<Vec<u8>, String> {
    crypto::decode_b64(input).map_err(|e| format!("{field_name}: {e}"))
}

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_string_free(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }

    unsafe {
        drop(CString::from_raw(ptr));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_generate_keypair_b64(
    out_public_key_b64: *mut *mut c_char,
    out_secret_key_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let (public_key, secret_key) = crypto::keys::generate_keypair().map_err(|e| e.to_string())?;
        unsafe {
            c_output(
                out_public_key_b64,
                crypto::encode_b64(&public_key),
                "out_public_key_b64",
            )?;
            c_output(
                out_secret_key_b64,
                crypto::encode_b64(&secret_key),
                "out_secret_key_b64",
            )?;
        }
        Ok(())
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_derive_argon_key_b64(
    password_utf8: *const c_char,
    salt_b64: *const c_char,
    mem_limit: u32,
    ops_limit: u32,
    out_key_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let (password, salt_b64) = unsafe {
            (
                c_input(password_utf8, "password_utf8")?,
                c_input(salt_b64, "salt_b64")?,
            )
        };

        let salt = decode_b64(&salt_b64, "salt_b64")?;
        let key = crypto::argon::derive_key(&password, &salt, mem_limit, ops_limit)
            .map_err(|e| e.to_string())?;

        unsafe {
            c_output(out_key_b64, crypto::encode_b64(&key), "out_key_b64")?;
        }

        Ok(())
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_derive_login_key_b64(
    key_enc_key_b64: *const c_char,
    out_login_key_b64: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        let key_enc_key_b64 = unsafe { c_input(key_enc_key_b64, "key_enc_key_b64")? };
        let key_enc_key = decode_b64(&key_enc_key_b64, "key_enc_key_b64")?;

        let login_key = crypto::kdf::derive_login_key(&key_enc_key).map_err(|e| e.to_string())?;

        unsafe {
            c_output(
                out_login_key_b64,
                crypto::encode_b64(&login_key),
                "out_login_key_b64",
            )?;
        }

        Ok(())
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_secretbox_open_b64(
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

        let plaintext = crypto::secretbox::decrypt(&ciphertext, &nonce, &key)
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

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_sealed_box_open_b64(
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

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_secretstream_decrypt_b64(
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

        let plaintext = crypto::stream::decrypt_file_data(&encrypted_data, &decryption_header, &key)
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

#[unsafe(no_mangle)]
pub extern "C" fn ente_tvos_crypto_blake2b_hash_hex(
    data_ptr: *const u8,
    data_len: usize,
    out_hash_hex: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> c_int {
    run_ffi(out_error, || {
        if data_ptr.is_null() {
            return Err("data_ptr is null".to_owned());
        }

        let data = unsafe { std::slice::from_raw_parts(data_ptr, data_len) };
        let hash = crypto::hash::hash(data, Some(64), None).map_err(|e| e.to_string())?;
        let hash_hex = crypto::encode_hex(&hash);

        unsafe {
            c_output(out_hash_hex, hash_hex, "out_hash_hex")?;
        }

        Ok(())
    })
}
