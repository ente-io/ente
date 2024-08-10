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
 * The highest layer is this file, `crypto/ente.ts`. These are usually simple
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
 * external API, and the underlying implementation (denoted by an "_" prefix).
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
import type {
    DecryptB64,
    DecryptBytes,
    EncryptBytes,
    EncryptJSON,
} from "./types";
import { sharedCryptoWorker } from "./worker";

/**
 * Some of these functions have not yet been needed on the main thread, and for
 * these we don't have a corresponding sharedCryptoWorker method.
 *
 * This assertion will let us know when we need to implement them (this'll
 * gracefully degrade in production: the functionality will work, just that the
 * crypto will happen on the main thread itself).
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
 */
export const encryptAssociatedData = (r: EncryptBytes) =>
    assertInWorker(ei._encryptAssociatedData(r));

/**
 * Encrypt the thumbnail for a file.
 *
 * This is just an alias for {@link encryptAssociatedData}.
 *
 * Use {@link decryptFileEmbedding} to decrypt the result.
 */
export const encryptThumbnail = (r: EncryptBytes) =>
    assertInWorker(ei._encryptThumbnail(r));

/**
 * A variant of {@link encryptAssociatedData} that returns the encrypted data in
 * the result as a base64 string instead of its bytes.
 *
 * Use {@link decryptMetadataBytes} to decrypt the result.
 */
export const encryptMetadataBytes = (r: EncryptBytes) =>
    assertInWorker(ei._encryptMetadataBytes(r));

/**
 * Encrypted the embedding associated with a file using the file's key.
 *
 * This is just an alias for {@link encryptMetadataBytes}.
 *
 * Use {@link decryptFileEmbedding} to decrypt the result.
 */
export const encryptFileEmbedding = async (r: EncryptBytes) =>
    assertInWorker(ei._encryptFileEmbedding(r));

/**
 * Encrypt the JSON metadata associated with an Ente object (file, collection or
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
 * Use {@link decryptMetadataJSON} to decrypt the result.
 */
export const encryptMetadataJSON = async (r: EncryptJSON) =>
    assertInWorker(ei._encryptMetadataJSON(r));

/**
 * Decrypt arbitrary data associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is the sibling of {@link encryptAssociatedData}.
 *
 * See {@link decryptChaChaOneShot} for the implementation details.
 */
export const decryptAssociatedData = (r: DecryptBytes) =>
    assertInWorker(ei._decryptAssociatedData(r));

/**
 * Decrypt the thumbnail for a file.
 *
 * This is the sibling of {@link encryptThumbnail}.
 */
export const decryptThumbnail = (r: DecryptBytes) =>
    assertInWorker(ei._decryptThumbnail(r));

/**
 * Decrypt metadata associated with an Ente object.
 *
 * This is the sibling of {@link decryptMetadataBytes}.
 */
export const decryptMetadataBytes = (r: DecryptB64) =>
    inWorker()
        ? ei._decryptMetadataBytes(r)
        : sharedCryptoWorker().then((w) => w.decryptMetadataBytes(r));

/**
 * Decrypt the embedding associated with a file using the file's key.
 *
 * This is the sibling of {@link encryptFileEmbedding}.
 */
export const decryptFileEmbedding = async (r: DecryptB64) =>
    assertInWorker(ei._decryptFileEmbedding(r));

/**
 * Decrypt the metadata JSON associated with an Ente object.
 *
 * This is the sibling of {@link encryptMetadataJSON}.
 *
 * @returns The decrypted JSON value. Since TypeScript does not have a native
 * JSON type, we need to return it as an `unknown`.
 */
export const decryptMetadataJSON = (r: DecryptB64) =>
    inWorker()
        ? ei._decryptMetadataJSON(r)
        : sharedCryptoWorker().then((w) => w.decryptMetadataJSON(r));
