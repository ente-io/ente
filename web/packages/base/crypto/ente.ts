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
 * See {@link encryptChaChaOneShot} for the implementation details.
 *
 * @param data The data (bytes) to encrypt.
 *
 * @param keyB64 Base64 encoded string containing the encryption key. This is
 * expected to the key of the file with which {@link data} is associated.
 *
 * @returns The encrypted data and the (Base64 encoded) decryption header.
 */
export const encryptFileAssociatedData = (data: Uint8Array, keyB64: string) =>
    libsodium.encryptChaChaOneShot(data, keyB64);

/**
 * A variant of {@link encryptFileAssociatedData} that Base64 encodes the
 * encrypted data.
 *
 * This is the sibling of {@link decryptFileAssociatedDataFromB64}.
 *
 * It is useful in cases where the (encrypted) associated data needs to
 * transferred as the HTTP POST body.
 */
export const encryptFileAssociatedDataToB64 = async (
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
 * Decrypt arbitrary data associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileAssociatedDataToB64}.
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
export const decryptFileAssociatedDataFromB64 = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    libsodium.decryptChaChaOneShot(
        await libsodium.fromB64(encryptedDataB64),
        await libsodium.fromB64(decryptionHeaderB64),
        keyB64,
    );
