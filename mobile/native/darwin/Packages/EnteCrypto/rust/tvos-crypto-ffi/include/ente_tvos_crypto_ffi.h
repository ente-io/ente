#ifndef ENTE_TVOS_CRYPTO_FFI_H
#define ENTE_TVOS_CRYPTO_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void ente_tvos_crypto_string_free(char *ptr);

int32_t ente_tvos_crypto_generate_keypair_b64(
    char **out_public_key_b64,
    char **out_secret_key_b64,
    char **out_error
);

int32_t ente_tvos_crypto_derive_argon_key_b64(
    const char *password_utf8,
    const char *salt_b64,
    uint32_t mem_limit,
    uint32_t ops_limit,
    char **out_key_b64,
    char **out_error
);

int32_t ente_tvos_crypto_derive_login_key_b64(
    const char *key_enc_key_b64,
    char **out_login_key_b64,
    char **out_error
);

int32_t ente_tvos_crypto_secretbox_open_b64(
    const char *ciphertext_b64,
    const char *nonce_b64,
    const char *key_b64,
    char **out_plaintext_b64,
    char **out_error
);

int32_t ente_tvos_crypto_sealed_box_open_b64(
    const char *ciphertext_b64,
    const char *public_key_b64,
    const char *secret_key_b64,
    char **out_plaintext_b64,
    char **out_error
);

int32_t ente_tvos_crypto_secretstream_decrypt_b64(
    const char *encrypted_data_b64,
    const char *decryption_header_b64,
    const char *key_b64,
    char **out_plaintext_b64,
    char **out_error
);

int32_t ente_tvos_crypto_blake2b_hash_hex(
    const uint8_t *data_ptr,
    uintptr_t data_len,
    char **out_hash_hex,
    char **out_error
);

#ifdef __cplusplus
}
#endif

#endif
