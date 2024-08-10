/**
 * @file Higher level functions that use the ontology of Ente's types
 *
 * [Note: Crypto code hierarchy]
 *
 * 1.  crypto/ente.ts        (Ente specific higher level functions)
 * 2.  crypto/libsodium.ts   (More primitive wrappers over libsodium)
 * 3.  libsodium-wrappers    (JavaScript bindings to libsodium)
 *
 * Our cryptography primitives are provided by libsodium, specifically, its
 * JavaScript bindings ("libsodium-wrappers"). This is the lowest layer.
 *
 * Direct usage of "libsodium-wrappers" is restricted to `crypto/libsodium.ts`.
 * This is the next higher layer, and the first one that our code should
 * directly use. Usually the functions in this file are thin wrappers over the
 * raw libsodium APIs, with a bit of massaging. They also ensure that
 * sodium.ready has been called before accessing libsodium's APIs, thus all the
 * functions it exposes are async.
 *
 * The final layer is this file, `crypto/ente.ts`. These are usually thin
 * compositions of functionality exposed by `crypto/libsodium.ts`, but the
 * difference is that the functions in ente.ts don't talk in terms of the crypto
 * algorithms, but rather in terms the higher-level Ente specific goal we are
 * trying to accomplish.
 *
 * There is an additional actor in the play. Cryptographic operations are CPU
 * intensive and would cause the UI to stutter if used directly on the main
 * thread. To keep the UI smooth, we instead want to run them in a web worker.
 * However, sometimes we already _are_ running in a web worker, and delegating
 * to another worker is wasteful.
 *
 * To handle both these scenario, each function in this file is split into the
 * external API, and the underlying implementation (denoted by an "I" suffix).
 * The external API functions check to see if we're already in a web worker, and
 * if so directly invoke the implementation. Otherwise the call the sibling
 * function in a shared "crypto" web worker (which then invokes the
 * implementation, but this time in the context of a web worker).
 *
 * To avoid a circular dependency during webpack imports, we need to keep the
 * implementation functions in a separate file (ente-impl.ts). This is a bit
 * unfortunate, since it makes them harder to read and reason about (since their
 * documentation and parameter names are all in ente.ts).
 *
 * Some older code directly calls the functions in the shared crypto.worker.ts,
 * but that should be avoided since it makes the code not behave the way we want
 * when we're already in a web worker. There are exceptions to this
 * recommendation though (in circumstances where we create more crypto workers
 * instead of using the shared one).
 */
import { assertionFailed } from "../assert";
import { inWorker } from "../env";
import * as ei from "./ente-impl";
import * as libsodium from "./libsodium";
import { sharedCryptoWorker } from "./worker";

/**
 * Some functions we haven't yet needed to use on the main thread. These don't
 * have a corresponding sharedCryptoWorker interface. This assertion will let us
 * know when we need to implement them (in production it'll just log a warning).
 */
const assertInWorker = <T>(x: T): T => {
    if (!inWorker()) assertionFailed("Currently only usable in a web worker");
    return x;
};

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
 * @param keyB64 base64 string containing the encryption key. This is expected
 * to the key of the object with which {@link data} is associated. For example,
 * if this is data associated with a file, then this will be the file's key.
 *
 * @returns The encrypted data and the (base64 encoded) decryption header.
 */
export const encryptAssociatedData = (data: Uint8Array, keyB64: string) =>
    assertInWorker(ei.encryptAssociatedDataI(data, keyB64));

/**
 * Encrypt the thumbnail for a file.
 *
 * This is just an alias for {@link encryptAssociatedData}.
 *
 * @param data The thumbnail's data.
 *
 * @param keyB64 The key associated with the file whose thumbnail this is.
 *
 * @returns The encrypted thumbnail, and the associated decryption header
 * (base64 encoded).
 */
export const encryptThumbnail = (data: Uint8Array, keyB64: string) =>
    assertInWorker(ei.encryptThumbnailI(data, keyB64));

/**
 * Encrypted the embedding associated with a file using the file's key.
 *
 * This as a variant of {@link encryptAssociatedData} tailored for
 * encrypting the embeddings (a.k.a. derived data) associated with a file. In
 * particular, it returns the encrypted data in the result as a base64 string
 * instead of its bytes.
 *
 * Use {@link decryptFileEmbedding} to decrypt the result.
 */
export const encryptFileEmbedding = async (data: Uint8Array, keyB64: string) =>
    assertInWorker(ei.encryptFileEmbeddingI(data, keyB64));

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
 * encrypted bytes, it returns their base64 string representation.
 *
 * Use {@link decryptMetadata} to decrypt the result.
 *
 * @param metadata The JSON value to encrypt. It can be an arbitrary JSON value,
 * but since TypeScript currently doesn't have a native JSON type, it is typed
 * as an unknown.
 *
 * @returns The encrypted data and decryption header, both as base64 strings.
 */
export const encryptMetadata = async (metadata: unknown, keyB64: string) =>
    assertInWorker(ei.encryptMetadataI(metadata, keyB64));

/**
 * Decrypt arbitrary data associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is the sibling of {@link encryptAssociatedData}.
 *
 * See {@link decryptChaChaOneShot} for the implementation details.
 *
 * @param encryptedData A {@link Uint8Array} containing the bytes to decrypt.
 *
 * @param headerB64 A base64 string containing the decryption header that was
 * produced during encryption.
 *
 * @param keyB64 A base64 string containing the encryption key. This is expected
 * to be the key of the object to which {@link encryptedDataB64} is associated.
 *
 * @returns The decrypted bytes.
 */
export const decryptAssociatedData = (    encryptedData: Uint8Array,
    headerB64: string,
    keyB64: string,
) => libsodium.decryptChaChaOneShot;

/**
 * Decrypt the thumbnail for a file.
 *
 * This is just an alias for {@link decryptAssociatedData}.
 */
export const decryptThumbnail = decryptAssociatedData;

/**
 * Decrypt the embedding associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileEmbedding}.
 *
 * @param encryptedDataB64 A base64 string containing the encrypted embedding.
 *
 * @param headerB64 A base64 string containing the decryption header produced
 * during encryption.
 *
 * @param keyB64 A base64 string containing the encryption key. This is expected
 * to be the key of the file with which {@link encryptedDataB64} is associated.
 *
 * @returns The decrypted metadata JSON object.
 */
export const decryptFileEmbedding = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    assertInWorker(
        ei.decryptFileEmbeddingI(encryptedDataB64, decryptionHeaderB64, keyB64),
    );

/**
 * Decrypt the metadata associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is the sibling of {@link encryptMetadata}.
 *
 * @param encryptedDataB64 base64 encoded string containing the encrypted data.
 *
 * @param headerB64 base64 encoded string containing the decryption header
 * produced during encryption.
 *
 * @param keyB64 base64 encoded string containing the encryption key. This is
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
    inWorker()
        ? ei.decryptMetadataI(encryptedDataB64, decryptionHeaderB64, keyB64)
        : sharedCryptoWorker().then((w) =>
              w.decryptMetadata(encryptedDataB64, decryptionHeaderB64, keyB64),
          );

/**
 * A variant of {@link decryptMetadata} that does not attempt to parse the
 * decrypted data as a JSON string and instead just returns the raw decrypted
 * bytes that we got.
 */
export const decryptMetadataBytes = (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    inWorker()
        ? ei.decryptMetadataBytesI(
              encryptedDataB64,
              decryptionHeaderB64,
              keyB64,
          )
        : sharedCryptoWorker().then((w) =>
              w.decryptMetadataBytes(
                  encryptedDataB64,
                  decryptionHeaderB64,
                  keyB64,
              ),
          );
