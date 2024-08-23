/**
 * @file Higher level functions that use the ontology of Ente's requirements.
 *
 * [Note: Crypto code hierarchy]
 *
 * 1.  @/base/crypto            (Crypto API for our code)
 * 2.  @/base/crypto/libsodium  (Lower level wrappers over libsodium)
 * 3.  libsodium-wrappers       (JavaScript bindings to libsodium)
 *
 * Our cryptography primitives are provided by libsodium, specifically, its
 * JavaScript bindings ("libsodium-wrappers"). This is the lowest layer. Note
 * that we use the sumo variant, "libsodium-wrappers-sumo", since the standard
 * variant does not provide the `crypto_pwhash_*` functions.
 *
 * Direct usage of "libsodium-wrappers" is restricted to `crypto/libsodium.ts`.
 * This is the next higher layer. Usually the functions in this file are thin
 * wrappers over the raw libsodium APIs, with a bit of massaging. They also
 * ensure that sodium.ready has been called before accessing libsodium's APIs,
 * thus all the functions it exposes are async.
 *
 * The highest layer is this file, `crypto/index.ts`, and the one that our own
 * code should use. These are usually simple compositions of functionality
 * exposed by `crypto/libsodium.ts`, the primary difference being that these
 * functions try to talk in terms of higher-level Ente specific goal we are
 * trying to accomplish instead of the specific underlying crypto algorithms.
 *
 * There is an additional actor in play. Cryptographic operations like
 * encryption are CPU intensive and would cause the UI to stutter if used
 * directly on the main thread. To keep the UI smooth, we instead want to run
 * them in a web worker. However, sometimes we already _are_ running in a web
 * worker, and delegating to another worker is wasteful.
 *
 * To handle both these scenario, the potentially CPU intensive functions in
 * this file are split into the external API, and the underlying implementation
 * (denoted by an "_" prefix). To avoid a circular dependency during webpack
 * imports, we need to keep the implementation functions in a separate file
 * (`ente-impl.ts`).
 *
 * The external API functions check to see if we're already in a web worker, and
 * if so directly invoke the implementation. Otherwise the call the sibling
 * function in a shared "crypto" web worker (which then invokes the
 * implementation function, but this time in the context of a web worker).
 *
 * Also, some code (e.g. the uploader) creates it own crypto worker instances,
 * and thus directly calls the functions in the web worker (it created) instead
 * of going through this file.
 */
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import { assertionFailed } from "../assert";
import { inWorker } from "../env";
import * as ei from "./ente-impl";
import * as libsodium from "./libsodium";
import type { BytesOrB64, EncryptedBlob, EncryptedBox } from "./types";
import type { CryptoWorker } from "./worker";

/**
 * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
 */
let _comlinkWorker: ComlinkWorker<typeof CryptoWorker> | undefined;

/**
 * Lazily created, cached, instance of a CryptoWorker web worker.
 */
export const sharedCryptoWorker = async () =>
    (_comlinkWorker ??= createComlinkCryptoWorker()).remote;

/**
 * Create a new instance of a comlink worker that wraps a {@link CryptoWorker}
 * web worker.
 */
export const createComlinkCryptoWorker = () =>
    new ComlinkWorker<typeof CryptoWorker>(
        "crypto",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Some of the potentially CPU intensive functions below have not yet been
 * needed on the main thread, and for these we don't have a corresponding
 * sharedCryptoWorker method.
 *
 * This assertion will let us know when we need to implement them. This will
 * gracefully degrade in production: the functionality will work, just that the
 * crypto operations will happen on the main thread itself.
 */
const assertInWorker = <T>(x: T): T => {
    if (!inWorker()) assertionFailed("Currently only usable in a web worker");
    return x;
};

/**
 * Generate a new randomly generated 256-bit key suitable for use with the *Box
 * encryption functions.
 */
export const generateBoxKey = libsodium.generateBoxKey;

/**
 * Encrypt the given data, returning a box containing the encrypted data and a
 * randomly generated nonce that was used during encryption.
 *
 * Both the encrypted data and the nonce are returned as base64 strings.
 *
 * Use {@link decryptBoxB64} to decrypt the result.
 *
 * > The suffix "Box" comes from the fact that it uses the so called secretbox
 * > APIs provided by libsodium under the hood.
 * >
 * > See: [Note: 3 forms of encryption (Box | Blob | Stream)]
 */
export const encryptBoxB64 = (data: BytesOrB64, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptBoxB64(data, key)
        : sharedCryptoWorker().then((w) => w.encryptBoxB64(data, key));

/**
 * Encrypt the given data, returning a blob containing the encrypted data and a
 * decryption header.
 *
 * This function is usually used to encrypt data associated with an Ente object
 * (file, collection, entity) using the object's key.
 *
 * Use {@link decryptBlob} to decrypt the result.
 *
 * > The suffix "Blob" comes from our convention of naming functions that use
 * > the secretstream APIs in one-shot mode.
 * >
 * > See: [Note: 3 forms of encryption (Box | Blob | Stream)]
 */
export const encryptBlob = (data: BytesOrB64, key: BytesOrB64) =>
    assertInWorker(ei._encryptBlob(data, key));

/**
 * A variant of {@link encryptBlob} that returns the result components as base64
 * strings.
 */
export const encryptBlobB64 = (data: BytesOrB64, key: BytesOrB64) =>
    assertInWorker(ei._encryptBlobB64(data, key));

/**
 * Encrypt the thumbnail for a file.
 *
 * This is midway variant of {@link encryptBlob} and {@link encryptBlobB64} that
 * returns the decryption header as a base64 string, but leaves the data
 * unchanged.
 *
 * Use {@link decryptThumbnail} to decrypt the result.
 */
export const encryptThumbnail = (data: BytesOrB64, key: BytesOrB64) =>
    assertInWorker(ei._encryptThumbnail(data, key));

/**
 * Encrypt the JSON metadata associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is a variant of {@link encryptBlobB64} tailored for encrypting any
 * arbitrary metadata associated with an Ente object. For example, it is used
 * for encrypting the various metadata fields associated with a file, using that
 * file's key.
 *
 * Instead of raw bytes, it takes as input an arbitrary JSON object which it
 * encodes into a string, and encrypts that.
 *
 * Use {@link decryptMetadataJSON} to decrypt the result.
 *
 * @param jsonValue The JSON value to encrypt. This can be an arbitrary JSON
 * value, but since TypeScript currently doesn't have a native JSON type, it is
 * typed as {@link unknown}.
 *
 * @param key The encryption key.
 */
export const encryptMetadataJSON_New = (jsonValue: unknown, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptMetadataJSON_New(jsonValue, key)
        : sharedCryptoWorker().then((w) =>
              w.encryptMetadataJSON_New(jsonValue, key),
          );

/**
 * Deprecated, use {@link encryptMetadataJSON_New} instead.
 */
export const encryptMetadataJSON = async (r: {
    jsonValue: unknown;
    keyB64: string;
}) =>
    inWorker()
        ? ei._encryptMetadataJSON(r)
        : sharedCryptoWorker().then((w) => w.encryptMetadataJSON(r));

/**
 * Decrypt a box encrypted using {@link encryptBoxB64}.
 */
export const decryptBox = (box: EncryptedBox, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBox(box, key)
        : sharedCryptoWorker().then((w) => w.decryptBox(box, key));

/**
 * Variant of {@link decryptBox} that returns the result as a base64 string.
 */
export const decryptBoxB64 = (box: EncryptedBox, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBoxB64(box, key)
        : sharedCryptoWorker().then((w) => w.decryptBoxB64(box, key));

/**
 * Decrypt a blob encrypted using either {@link encryptBlob} or
 * {@link encryptBlobB64}.
 */
export const decryptBlob = (blob: EncryptedBlob, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBlob(blob, key)
        : sharedCryptoWorker().then((w) => w.decryptBlob(blob, key));

/**
 * A variant of {@link decryptBlob} that returns the result as a base64 string.
 */
export const decryptBlobB64 = (blob: EncryptedBlob, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBlobB64(blob, key)
        : sharedCryptoWorker().then((w) => w.decryptBlobB64(blob, key));

/**
 * Decrypt the thumbnail encrypted using {@link encryptThumbnail}.
 */
export const decryptThumbnail = (blob: EncryptedBlob, key: BytesOrB64) =>
    assertInWorker(ei._decryptThumbnail(blob, key));

/**
 * Decrypt the metadata JSON encrypted using {@link encryptMetadataJSON}.
 *
 * @returns The decrypted JSON value. Since TypeScript does not have a native
 * JSON type, we need to return it as an `unknown`.
 */
export const decryptMetadataJSON_New = (
    blob: EncryptedBlob,
    key: BytesOrB64,
) =>
    inWorker()
        ? ei._decryptMetadataJSON_New(blob, key)
        : sharedCryptoWorker().then((w) =>
              w.decryptMetadataJSON_New(blob, key),
          );

/**
 * Deprecated, retains the old API.
 */
export const decryptMetadataJSON = (r: {
    encryptedDataB64: string;
    decryptionHeaderB64: string;
    keyB64: string;
}) =>
    inWorker()
        ? ei._decryptMetadataJSON(r)
        : sharedCryptoWorker().then((w) => w.decryptMetadataJSON(r));
