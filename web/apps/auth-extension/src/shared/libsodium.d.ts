/**
 * Type declarations for libsodium-wrappers-sumo.
 */
declare module "libsodium-wrappers-sumo" {
    interface Sodium {
        ready: Promise<void>;

        // Base64 encoding/decoding
        to_base64(input: Uint8Array, variant: number): string;
        from_base64(input: string, variant: number): Uint8Array;
        from_string(input: string): Uint8Array;

        // Base64 variants
        base64_variants: {
            ORIGINAL: number;
            URLSAFE: number;
            URLSAFE_NO_PADDING: number;
        };

        // Key generation
        crypto_secretbox_keygen(): Uint8Array;
        crypto_secretstream_xchacha20poly1305_keygen(): Uint8Array;

        // Secretbox (Box encryption)
        crypto_secretbox_NONCEBYTES: number;
        crypto_secretbox_KEYBYTES: number;
        randombytes_buf(length: number): Uint8Array;
        crypto_secretbox_easy(message: Uint8Array, nonce: Uint8Array, key: Uint8Array): Uint8Array;
        crypto_secretbox_open_easy(ciphertext: Uint8Array, nonce: Uint8Array, key: Uint8Array): Uint8Array;

        // Secretstream (Blob/Stream encryption)
        crypto_secretstream_xchacha20poly1305_init_push(key: Uint8Array): {
            state: unknown;
            header: Uint8Array;
        };
        crypto_secretstream_xchacha20poly1305_init_pull(header: Uint8Array, key: Uint8Array): unknown;
        crypto_secretstream_xchacha20poly1305_push(
            state: unknown,
            message: Uint8Array,
            ad: null,
            tag: number
        ): Uint8Array;
        crypto_secretstream_xchacha20poly1305_pull(
            state: unknown,
            ciphertext: Uint8Array,
            ad?: null
        ): { message: Uint8Array; tag: number };
        crypto_secretstream_xchacha20poly1305_TAG_MESSAGE: number;
        crypto_secretstream_xchacha20poly1305_TAG_FINAL: number;

        // Password hashing / key derivation
        crypto_pwhash_SALTBYTES: number;
        crypto_pwhash_ALG_ARGON2ID13: number;
        crypto_pwhash(
            keyLength: number,
            password: Uint8Array,
            salt: Uint8Array,
            opsLimit: number,
            memLimit: number,
            algorithm: number
        ): Uint8Array;

        // Hashing
        crypto_hash(message: Uint8Array): Uint8Array;

        // Key derivation
        crypto_kdf_derive_from_key(
            subkeyLength: number,
            subkeyId: number,
            context: string,
            key: Uint8Array
        ): Uint8Array;

        // Sealed box (asymmetric encryption)
        crypto_box_seal_open(
            ciphertext: Uint8Array,
            publicKey: Uint8Array,
            secretKey: Uint8Array
        ): Uint8Array;
    }

    const sodium: Sodium;
    export default sodium;
}
