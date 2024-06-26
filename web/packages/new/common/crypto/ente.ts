/**
 * @file Higher level functions that use the ontology of Ente's types
 *
 * These are thin wrappers over the (thin-) wrappers in internal/libsodium.ts.
 * The main difference is that they don't name things in terms of the crypto
 * algorithms, but rather by the specific Ente specific tasks we are trying to
 * do.
 */
import * as libsodium from "@ente/shared/crypto/internal/libsodium";

/**
 * Decrypt arbitrary metadata associated with a file using the its's key.
 *
 * @param encryptedMetadataB64 The Base64 encoded string containing the
 * encrypted data.
 *
 * @param headerB64 The Base64 encoded string containing the decryption header
 * produced during encryption.
 *
 * @param keyB64 The Base64 encoded string containing the encryption key
 * (this'll generally be the file's key).
 *
 * @returns The decrypted utf-8 string.
 */
export const decryptFileMetadata = async (
    encryptedMetadataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) => {
    const metadataBytes = await libsodium.decryptChaChaOneShot(
        await libsodium.fromB64(encryptedMetadataB64),
        await libsodium.fromB64(decryptionHeaderB64),
        keyB64,
    );
    const textDecoder = new TextDecoder();
    return textDecoder.decode(metadataBytes);
};
