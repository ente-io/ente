#include <stdint.h>
#include <stddef.h>

intptr_t ente_notification_decrypt(const uint8_t private_key[32],
    const uint8_t *ciphertext, size_t ciphertext_length,
    uint8_t *plaintext, size_t plaintext_capacity);
