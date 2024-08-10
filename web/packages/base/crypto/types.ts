/**
 * An encryption request with the plaintext data as bytes.
 */
export interface EncryptBytes {
    /**
     * A {@link Uint8Array} containing the bytes to encrypt.
     */
    data: Uint8Array;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * An encryption request with the plaintext data as a JSON value.
 */
export interface EncryptJSON {
    /**
     * The JSON value to encrypt.
     *
     * This can be an arbitrary JSON value, but since TypeScript currently
     * doesn't have a native JSON type, it is typed as {@link unknown}.
     */
    jsonValue: unknown;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * A decryption request with the encrypted data as a base64 encoded string.
 */
export interface DecryptB64 {
    /**
     * A base64 string containing the data to decrypt.
     */
    encryptedDataB64: string;
    /**
     * A base64 string containing the decryption header that was produced during
     * encryption.
     *
     * The header contains a random nonce and other libsodium metadata. It does
     * not need to be kept secret.
     */
    decryptionHeaderB64: string;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * A decryption request with the encrypted data as bytes.
 */
export interface DecryptBytes {
    /**
     * A {@link Uint8Array} containing the bytes to decrypt.
     */
    encryptedData: Uint8Array;
    /**
     * A base64 string containing the decryption header that was produced during
     * encryption.
     *
     * The header contains a random nonce and other libsodium metadata. It does
     * not need to be kept secret.
     */
    decryptionHeaderB64: string;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}
