/**
 * @file Higher level functions that use the ontology of Ente's types
 *
 * [Note: Crypto code hierarchy]
 *
 * The functions in this file (base/crypto/ente.ts) are are thin wrappers over
 * the (thin-) wrappers in internal/libsodium.ts. The main difference is that
 * these functions don't talk in terms of the crypto algorithms, but rather in
 * terms the higher-level Ente specific goal we are trying to accomplish.
 *
 * Some of these are also exposed via the web worker in
 * internal/crypto.worker.ts. The web worker variants should be used when we
 * need to perform these operations from the main thread, so that the UI remains
 * responsive while the potentially CPU-intensive encryption etc happens.
 *
 * 1. ente.ts or crypto.worker.ts (high level, Ente specific).
 * 2. internal/libsodium.ts (wrappers over libsodium)
 * 3. libsodium (JS bindings).
 */
import * as libsodium from "@ente/shared/crypto/internal/libsodium";

/**
 * Encrypt arbitrary data associated with a file using the file's key.
 *
 * Use {@link decryptFileAssociatedData} to decrypt the result.
 *
 * See {@link encryptChaChaOneShot} for the implementation details.
 *
 * @param data A {@link Uint8Array} containing the bytes to encrypt.
 *
 * @param keyB64 Base64 encoded string containing the encryption key. This is
 * expected to the key of the file with which {@link data} is associated.
 *
 * @returns The encrypted data and the (Base64 encoded) decryption header.
 */
export const encryptFileAssociatedData = libsodium.encryptChaChaOneShot;

/**
 * Encrypted the embedding associated with a file using the file's key.
 *
 * This as a variant of {@link encryptFileAssociatedData} tailored for
 * encrypting the embeddings (a.k.a. derived data) associated with a file. In
 * particular, it returns the encrypted data in the result as a Base64 string
 * instead of its bytes.
 *
 * Use {@link decryptFileEmbedding} to decrypt the result.
 */
export const encryptFileEmbedding = async (
    data: Uint8Array,
    keyB64: string,
) => {
    const { encryptedData, decryptionHeaderB64 } =
        await encryptFileAssociatedData(data, keyB64);
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

/**
 * A variant of {@link encryptFileAssociatedData} tailored for encrypting the
 * various metadata fields associated with a file.
 *
 * Instead of raw bytes, it takes as input an arbitrary JSON object which it
 * encodes into a string, and encrypts that. Also, instead of returning the raw
 * encrypted bytes, it returns their Base64 encoded string representation.
 */
export const encryptFileMetadata = async (
    // Arbitrary JSON really, but since TypeScript doesn't have a native JSON
    // type use a string Record as a standin replacement.
    metadata: Record<string, unknown>,
    keyB64: string,
) => {
    const textEncoder = new TextEncoder();
    const encodedMetadata = textEncoder.encode(JSON.stringify(metadata));

    const { encryptedData, decryptionHeaderB64 } =
        await encryptFileAssociatedData(encodedMetadata, keyB64);
    return {
        encryptedData: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

/**
 * Decrypt arbitrary data associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileAssociatedData}.
 *
 * See {@link decryptChaChaOneShot2} for the implementation details.
 *
 * @param encryptedData A {@link Uint8Array} containing the bytes to decrypt.
 *
 * @param header A Base64 string containing the bytes of the decryption header
 * that was produced during encryption.
 *
 * @param keyB64 Base64 encoded string containing the encryption key. This is
 * expected to be the key of the file with which {@link encryptedDataB64} is
 * associated.
 *
 * @returns The decrypted bytes.
 */
export const decryptFileAssociatedData = libsodium.decryptChaChaOneShot2;

/**
 * Decrypt the embedding associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileEmbedding}.
 *
 * @param encryptedDataB64 Base64 encoded string containing the encrypted data.
 *
 * @param headerB64 Base64 encoded string containing the decryption header
 * produced during encryption.
 *
 * @param keyB64 Base64 encoded string containing the encryption key. This is
 * expected to be the key of the file with which {@link encryptedDataB64} is
 * associated.
 *
 * @returns The decrypted metadata bytes.
 */
export const decryptFileEmbedding = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    decryptFileAssociatedData(
        await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    );
