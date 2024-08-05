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
 * Encrypt arbitrary data associated with an Ente object (file, collection,
 * entity) using the object's key.
 *
 * Use {@link decryptAssociatedData} to decrypt the result.
 *
 * See {@link encryptChaChaOneShot} for the implementation details.
 *
 * @param data A {@link Uint8Array} containing the bytes to encrypt.
 *
 * @param keyB64 Base64 string containing the encryption key. This is expected
 * to the key of the object with which {@link data} is associated. For example,
 * if this is data associated with a file, then this will be the file's key.
 *
 * @returns The encrypted data and the (Base64 encoded) decryption header.
 */
export const encryptAssociatedData = libsodium.encryptChaChaOneShot;

/**
 * Encrypted the embedding associated with a file using the file's key.
 *
 * This as a variant of {@link encryptAssociatedData} tailored for
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
    const { encryptedData, decryptionHeaderB64 } = await encryptAssociatedData(
        data,
        keyB64,
    );
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

/**
 * Encrypt the metadata associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is a variant of {@link encryptAssociatedData} tailored for encrypting
 * any arbitrary metadata associated with an Ente object. For example, it is
 * used for encrypting the various metadata fields (See: [Note: Metadatum])
 * associated with a file, using that file's key.
 *
 * Instead of raw bytes, it takes as input an arbitrary JSON object which it
 * encodes into a string, and encrypts that. And instead of returning the raw
 * encrypted bytes, it returns their Base64 string representation.
 *
 * Use {@link decryptMetadata} to decrypt the result.
 *
 * @param metadata The JSON value to encrypt. It can be an arbitrary JSON value,
 * but since TypeScript currently doesn't have a native JSON type, it is typed
 * as an unknown.
 *
 * @returns The encrypted data and decryption header, both as Base64 strings.
 */
export const encryptMetadata = async (metadata: unknown, keyB64: string) => {
    const encodedMetadata = new TextEncoder().encode(JSON.stringify(metadata));

    const { encryptedData, decryptionHeaderB64 } = await encryptAssociatedData(
        encodedMetadata,
        keyB64,
    );
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

/**
 * Decrypt arbitrary data associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is the sibling of {@link encryptAssociatedData}.
 *
 * See {@link decryptChaChaOneShot2} for the implementation details.
 *
 * @param encryptedData A {@link Uint8Array} containing the bytes to decrypt.
 *
 * @param headerB64 A Base64 string containing the decryption header that was
 * produced during encryption.
 *
 * @param keyB64 A Base64 encoded string containing the encryption key. This is
 * expected to be the key of the file with which {@link encryptedDataB64} is
 * associated.
 *
 * @returns The decrypted bytes.
 */
export const decryptAssociatedData = libsodium.decryptChaChaOneShot2;

/**
 * Decrypt the embedding associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileEmbedding}.
 *
 * @param encryptedDataB64 A Base64 string containing the encrypted embedding.
 *
 * @param headerB64 A Base64 string containing the decryption header produced
 * during encryption.
 *
 * @param keyB64 A Base64 string containing the encryption key. This is expected
 * to be the key of the file with which {@link encryptedDataB64} is associated.
 *
 * @returns The decrypted metadata JSON object.
 */
export const decryptFileEmbedding = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    decryptAssociatedData(
        await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    );

/**
 * Decrypt the metadata associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is the sibling of {@link decryptMetadata}.
 *
 * @param encryptedDataB64 Base64 encoded string containing the encrypted data.
 *
 * @param headerB64 Base64 encoded string containing the decryption header
 * produced during encryption.
 *
 * @param keyB64 Base64 encoded string containing the encryption key. This is
 * expected to be the key of the object with which {@link encryptedDataB64} is
 * associated.
 *
 * @returns The decrypted JSON value. Since TypeScript does not have a native
 * JSON type, we need to return it as an `unknown`.
 */

export const decryptMetadata = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    JSON.parse(
        new TextDecoder().decode(
            await decryptAssociatedData(
                await libsodium.fromB64(encryptedDataB64),
                decryptionHeaderB64,
                keyB64,
            ),
        ),
    ) as unknown;
