use ente_core::crypto::hpke;

#[expect(
    unsafe_code,
    reason = "C callers provide buffers according to this FFI contract"
)]
#[unsafe(no_mangle)]
unsafe extern "C" fn ente_notification_decrypt(
    private_key: *const u8,
    ciphertext: *const u8,
    ciphertext_len: usize,
    plaintext: *mut u8,
    plaintext_capacity: usize,
) -> isize {
    if private_key.is_null()
        || ciphertext.is_null()
        || plaintext.is_null()
        || ciphertext_len <= hpke::OVERHEAD
        || ciphertext_len > 4096
        || plaintext_capacity < ciphertext_len - hpke::OVERHEAD
    {
        return -1;
    }
    let (private_key, ciphertext) = unsafe {
        (
            std::slice::from_raw_parts(private_key, hpke::SecretKey::BYTES),
            std::slice::from_raw_parts(ciphertext, ciphertext_len),
        )
    };
    let Ok(decrypted) = hpke::SecretKey::try_from_slice(private_key)
        .and_then(|key| hpke::open(ciphertext, &key, b"ente-push"))
    else {
        return -1;
    };
    unsafe { std::ptr::copy_nonoverlapping(decrypted.as_ptr(), plaintext, decrypted.len()) };
    decrypted.len() as isize
}
