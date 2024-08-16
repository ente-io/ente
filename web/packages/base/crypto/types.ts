/**
 * An encryption request with the data to encrypt provided as bytes.
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
 * A variant of {@link EncryptBytes} with the data as base64 encoded string.
 */
export interface EncryptB64 {
    /**
     * A base64 string containing the data to encrypt.
     */
    dataB64: string;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * A variant of {@link EncryptBytes} with the data as a JSON value.
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
 * The result of encryption using the secretbox APIs.
 *
 * It contains the encrypted data (bytes) and nonce (base64 encoded string)
 * pair. Both these values are needed to decrypt the data. The nonce does not
 * need to be secret.
 *
 * See: [Note: 3 forms of encryption (Box | Blob | Stream)].
 */
export interface EncryptedBoxBytes {
    /**
     * A {@link Uint8Array} containing the encrypted data.
     */
    encryptedData: Uint8Array;
    /**
     * A base64 string containing the nonce used during encryption.
     *
     * A randomly generated nonce for this encryption. It does not need to be
     * confidential, but it will be required to decrypt the data.
     */
    nonceB64: string;
}

/**
 * A variant of {@link EncryptedBoxBytes} with the encrypted data encoded as a
 * base64 string.
 */
export interface EncryptedBox64 {
    /**
     * A base64 string containing the encrypted data.
     */
    encryptedDataB64: string;
    /**
     * A base64 string containing the nonce used during encryption.
     *
     * A randomly generated nonce for this encryption. It does not need to be
     * confidential, but it will be required to decrypt the data.
     */
    nonceB64: string;
}

/**
 * The result of encryption using the secretstream APIs used in one-shot mode.
 *
 * It contains the encrypted data (bytes) and decryption header (base64 encoded
 * string) pair. Both these values are needed to decrypt the data. The header
 * does not need to be secret.
 *
 * See: [Note: 3 forms of encryption (Box | Blob | Stream)].
 */
export interface EncryptedBlobBytes {
    /**
     * A {@link Uint8Array} containing the encrypted data.
     */
    encryptedData: Uint8Array;
    /**
     * A base64 string containing the decryption header.
     *
     * The header contains a random nonce and other libsodium specific metadata.
     * It does not need to be secret, but it is required to decrypt the data.
     */
    decryptionHeaderB64: string;
}

/**
 * A variant of {@link EncryptedBlobBytes} with the encrypted data encoded as a
 * base64 string.
 */
export interface EncryptedBlobB64 {
    /**
     * A base64 string containing the encrypted data.
     */
    encryptedDataB64: string;
    /**
     * A base64 string containing the decryption header.
     *
     * The header contains a random nonce and other libsodium specific metadata.
     * It does not need to be secret, but it is required to decrypt the data.
     */
    decryptionHeaderB64: string;
}

/**
 * A decryption request to decrypt data encrypted using the secretbox APIs. The
 * encrypted Box's data is provided as bytes.
 *
 * See: [Note: 3 forms of encryption (Box | Blob | Stream)].
 */
export interface DecryptBoxBytes {
    /**
     * A {@link Uint8Array} containing the bytes to decrypt.
     */
    encryptedData: Uint8Array;
    /**
     * A base64 string containing the nonce that was used during encryption.
     *
     * The nonce is required to decrypt the data, but it does not need to be
     * kept secret.
     */
    nonceB64: string;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * A variant of {@link DecryptBoxBytes} with the encrypted Blob's data as a
 * base64 encoded string.
 */
export interface DecryptBoxB64 {
    /**
     * A base64 string containing the data to decrypt.
     */
    encryptedDataB64: string;
    /**
     * A base64 string containing the nonce that was used during encryption.
     *
     * The nonce is required to decrypt the data, but it does not need to be
     * kept secret.
     */
    nonceB64: string;
    /**
     * A base64 string containing the encryption key.
     */
    keyB64: string;
}

/**
 * A decryption request to decrypt data encrypted using the secretstream APIs in
 * one-shot mode. The encrypted Blob's data is provided as bytes.
 *
 * See: [Note: 3 forms of encryption (Box | Blob | Stream)].
 */
export interface DecryptBlobBytes {
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

/**
 * A variant of {@link DecryptBlobBytes} with the encrypted Blob's data as a
 * base64 encoded string.
 */
export interface DecryptBlobB64 {
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
