/**
 * @file Cryptographic operations. This is the highest layer of the crypto code
 * hierarchy, and is meant to be used directly by the rest of our code.
 *
 * --|
 * --> For each function, more detailed documentation is in `libsodium.ts` <-
 * --|
 *
 * [Note: Crypto code hierarchy]
 *
 * 1. ente-base/crypto            (Crypto API for our code)
 * 2. ente-base/crypto/libsodium  (The actual implementation)
 * 3. libsodium-wrappers          (JavaScript bindings to libsodium)
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
 * The highest layer is this file, `crypto/index.ts`. These are direct proxies
 * to functions exposed by `crypto/libsodium.ts`, but they automatically defer
 * to a worker thread if we're not already running on one.
 *
 * ---
 *
 * [Note: Using libsodium in worker thread]
 *
 * `crypto/ente-impl.ts` and `crypto/worker.ts` are logic-less internal files
 * meant to allow us to seamlessly use the the same API both from the main
 * thread or from a web worker whilst ensuring that the implementation never
 * runs on the main thread.
 *
 * Cryptographic operations like encryption are CPU intensive and would cause
 * the UI to stutter if used directly on the main thread. To keep the UI smooth,
 * we instead want to run them in a web worker. However, sometimes we already
 * _are_ running in a web worker, and delegating to another worker is wasteful.
 *
 * To handle both these scenario, the implementation of the functions in this
 * file are split into the external API, and the underlying implementation
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
 * and thus directly calls the functions in the web worker that it created
 * instead of going through this file.
 *
 * ---
 *
 * [Note: Crypto layer API data types]
 *
 * There are two primary types used when exchanging data with these functions:
 *
 * 1. Base64 strings. Unqualified strings are taken as base64 encoded
 *    representations of the underlying data. Usually, the unqualified "base"
 *    function deals with Base64 strings, since they also are the data type in
 *    which we usually send the encryted data etc to remote.
 *
 * 2. Raw bytes. Uint8Arrays are byte arrays. The functions that deal with bytes
 *    are indicated by a *Bytes suffix in their name.
 *
 * Where possible and useful, functions also accept a union of these two - a
 * {@link BytesOrB64} where the implementation will automatically convert
 * to/from base64 to bytes if needed, thus saving on unnecessary conversions at
 * the caller side.
 *
 * Apart from these two, there are other secondary and one off types.
 *
 * 1. "Regular" JavaScript strings. These are indicated by the *UTF8 suffix on
 *    the function that deals with them. These strings will be obtained by utf-8
 *    encoding (or decoding) the underlying bytes.
 *
 * 2. Hex representations of the bytes. These are indicated by the *Hex suffix
 *    on the functions dealing with them.
 *
 * 2. JSON values. These are indicated by the *JSON suffix on the functions
 *    dealing with them.
 */
import { ComlinkWorker } from "ente-base/worker/comlink-worker";
import { type StateAddress } from "libsodium-wrappers-sumo";
import { inWorker } from "../env";
import * as ei from "./ente-impl";
import type {
    BytesOrB64,
    EncryptedBlob,
    EncryptedBox,
    EncryptedFile,
} from "./types";
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

/** A shorter alias of {@link sharedCryptoWorker} for use within this file. */
const sharedWorker = sharedCryptoWorker;

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
 * Convert bytes ({@link Uint8Array}) to a base64 string.
 */
export const toB64 = (bytes: Uint8Array) =>
    inWorker() ? ei._toB64(bytes) : sharedWorker().then((w) => w.toB64(bytes));

/**
 * URL safe variant of {@link toB64}.
 */
export const toB64URLSafe = (bytes: Uint8Array) =>
    inWorker()
        ? ei._toB64URLSafe(bytes)
        : sharedWorker().then((w) => w.toB64URLSafe(bytes));

/**
 * Convert a base64 string to bytes ({@link Uint8Array}).
 */
export const fromB64 = (b64String: string) =>
    inWorker()
        ? ei._fromB64(b64String)
        : sharedWorker().then((w) => w.fromB64(b64String));

/**
 * Convert a base64 string to the hex representation of the underlying bytes.
 */
export const toHex = (b64String: string) =>
    inWorker()
        ? ei._toHex(b64String)
        : sharedWorker().then((w) => w.toHex(b64String));

/**
 * Convert a hex string to the base64 representation of the underlying bytes.
 */
export const fromHex = (hexString: string) =>
    inWorker()
        ? ei._fromHex(hexString)
        : sharedWorker().then((w) => w.fromHex(hexString));

/**
 * Return a new randomly generated 256-bit key (as a base64 string).
 *
 * The returned key is suitable for use with the *Box encryption functions, and
 * as a general encryption key (e.g. as the user's master key or recovery key).
 */
export const generateKey = () =>
    inWorker()
        ? ei._generateKey()
        : sharedWorker().then((w) => w.generateKey());

/**
 * Return a new randomly generated 256-bit key (as a base64 string) suitable for
 * use with the *Blob or *Stream encryption functions.
 */
export const generateBlobOrStreamKey = () =>
    inWorker()
        ? ei._generateBlobOrStreamKey()
        : sharedWorker().then((w) => w.generateBlobOrStreamKey());

/**
 * Encrypt the given data, returning a box containing the encrypted data and a
 * randomly generated nonce that was used during encryption.
 *
 * Both the encrypted data and the nonce are returned as base64 strings.
 *
 * Use {@link decryptBox} to decrypt the result.
 *
 * > The suffix "Box" comes from the fact that it uses the so called secretbox
 * > APIs provided by libsodium under the hood.
 * >
 * > See: [Note: 3 forms of encryption (Box | Blob | Stream)]
 */
export const encryptBox = (data: BytesOrB64, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptBox(data, key)
        : sharedWorker().then((w) => w.encryptBox(data, key));

/**
 * A variant of {@link encryptBox} that first UTF-8 encodes the input string to
 * obtain bytes, which it then encrypts.
 */
export const encryptBoxUTF8 = (data: string, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptBoxUTF8(data, key)
        : sharedWorker().then((w) => w.encryptBoxUTF8(data, key));

/**
 * Encrypt the given data, returning a blob containing the encrypted data and a
 * decryption header as base64 strings.
 *
 * This function is usually used to encrypt data associated with an Ente object
 * (file, collection, entity) using the object's key.
 *
 * Use {@link decryptBlob} or {@link decryptBlobBytes} to decrypt the result.
 *
 * > The suffix "Blob" comes from our convention of naming functions that use
 * > the secretstream APIs without breaking the data into chunks.
 * >
 * > See: [Note: 3 forms of encryption (Box | Blob | Stream)]
 */
export const encryptBlob = (data: BytesOrB64, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptBlob(data, key)
        : sharedWorker().then((w) => w.encryptBlob(data, key));

/**
 * A variant of {@link encryptBlob} that returns the result components as bytes
 * instead of as base64 strings.
 *
 * Use {@link decryptBlob} or {@link decryptBlobBytes} to decrypt the result.
 */
export const encryptBlobBytes = (data: BytesOrB64, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptBlobBytes(data, key)
        : sharedWorker().then((w) => w.encryptBlobBytes(data, key));

/**
 * Encrypt the given data using chunked streaming encryption, but process all
 * the chunks in one go.
 */
export const encryptStreamBytes = async (data: Uint8Array, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptStreamBytes(data, key)
        : sharedWorker().then((w) => w.encryptStreamBytes(data, key));

/**
 * Prepare for chunked streaming encryption using {@link encryptStreamChunk}.
 */
export const initChunkEncryption = async (key: BytesOrB64) =>
    inWorker()
        ? ei._initChunkEncryption(key)
        : sharedWorker().then((w) => w.initChunkEncryption(key));

/**
 * Encrypt a chunk as part of a chunked streaming encryption.
 */
export const encryptStreamChunk = async (
    data: Uint8Array,
    state: StateAddress,
    isFinalChunk: boolean,
) =>
    inWorker()
        ? ei._encryptStreamChunk(data, state, isFinalChunk)
        : sharedWorker().then((w) =>
              w.encryptStreamChunk(data, state, isFinalChunk),
          );

/**
 * Encrypt the JSON metadata associated with an Ente object (file, collection or
 * entity) using the object's key.
 *
 * This is a variant of {@link encryptBlob} tailored for encrypting any
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
export const encryptMetadataJSON = (jsonValue: unknown, key: BytesOrB64) =>
    inWorker()
        ? ei._encryptMetadataJSON(jsonValue, key)
        : sharedWorker().then((w) => w.encryptMetadataJSON(jsonValue, key));

/**
 * Decrypt a box encrypted using {@link encryptBox} and returns the decrypted
 * bytes as a base64 string.
 */
export const decryptBox = (box: EncryptedBox, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBox(box, key)
        : sharedWorker().then((w) => w.decryptBox(box, key));

/**
 * Variant of {@link decryptBox} that returns the decrypted bytes as it is
 * (without encoding them to base64).
 */
export const decryptBoxBytes = (box: EncryptedBox, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBoxBytes(box, key)
        : sharedWorker().then((w) => w.decryptBoxBytes(box, key));

/**
 * Variant of {@link decryptBoxBytes} that returns the decrypted bytes as a
 * "JavaScript string", specifically a UTF-8 string. That is, after decryption
 * we obtain raw bytes, which we interpret as a UTF-8 string.
 */
export const decryptBoxUTF8 = (box: EncryptedBox, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBoxUTF8(box, key)
        : sharedWorker().then((w) => w.decryptBoxUTF8(box, key));

/**
 * Decrypt a blob encrypted using either {@link encryptBlobBytes} or
 * {@link encryptBlob} and return it as a base64 encoded string.
 */
export const decryptBlob = (blob: EncryptedBlob, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBlob(blob, key)
        : sharedWorker().then((w) => w.decryptBlob(blob, key));

/**
 * A variant of {@link decryptBlobBytes} that returns the result bytes directly
 * (instead of encoding them as a base64 string).
 */
export const decryptBlobBytes = (blob: EncryptedBlob, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptBlobBytes(blob, key)
        : sharedWorker().then((w) => w.decryptBlobBytes(blob, key));

/**
 * Decrypt the result of {@link encryptStreamBytes}.
 */
export const decryptStreamBytes = async (
    file: EncryptedFile,
    key: BytesOrB64,
) =>
    inWorker()
        ? ei._decryptStreamBytes(file, key)
        : sharedWorker().then((w) => w.decryptStreamBytes(file, key));

/**
 * Prepare to decrypt the encrypted result produced using {@link initChunkEncryption} and
 * {@link encryptStreamChunk}.
 */
export const initChunkDecryption = async (header: string, key: BytesOrB64) =>
    inWorker()
        ? ei._initChunkDecryption(header, key)
        : sharedWorker().then((w) => w.initChunkDecryption(header, key));

/**
 * Decrypt an individual chunk produced by {@link encryptStreamChunk}.
 *
 * This function is used in tandem with {@link initChunkDecryption}.
 */
export const decryptStreamChunk = async (
    data: Uint8Array,
    state: StateAddress,
) =>
    inWorker()
        ? ei._decryptStreamChunk(data, state)
        : sharedWorker().then((w) => w.decryptStreamChunk(data, state));

/**
 * Decrypt the metadata JSON encrypted using {@link encryptMetadataJSON}.
 *
 * @returns The decrypted JSON value. Since TypeScript does not have a native
 * JSON type, we need to return it as an `unknown`.
 */
export const decryptMetadataJSON = (blob: EncryptedBlob, key: BytesOrB64) =>
    inWorker()
        ? ei._decryptMetadataJSON(blob, key)
        : sharedWorker().then((w) => w.decryptMetadataJSON(blob, key));

/**
 * Generate a new public/private keypair.
 */
export const generateKeyPair = async () =>
    inWorker()
        ? ei._generateKeyPair()
        : sharedWorker().then((w) => w.generateKeyPair());

/**
 * Public key encryption.
 */
export const boxSeal = async (data: string, publicKey: string) =>
    inWorker()
        ? ei._boxSeal(data, publicKey)
        : sharedWorker().then((w) => w.boxSeal(data, publicKey));

/**
 * Decrypt the result of {@link boxSeal}.
 */
export const boxSealOpen = async (
    encryptedData: string,
    publicKey: string,
    secretKey: string,
) =>
    inWorker()
        ? ei._boxSealOpen(encryptedData, publicKey, secretKey)
        : sharedWorker().then((w) =>
              w.boxSealOpen(encryptedData, publicKey, secretKey),
          );

/**
 * Derive a key by hashing the given {@link passphrase} using Argon 2id.
 */
export const deriveKey = async (
    passphrase: string,
    salt: string,
    opsLimit: number,
    memLimit: number,
) =>
    inWorker()
        ? ei._deriveKey(passphrase, salt, opsLimit, memLimit)
        : sharedWorker().then((w) =>
              w.deriveKey(passphrase, salt, opsLimit, memLimit),
          );

/**
 * Derive a sensitive key from the given {@link passphrase}.
 */
export const deriveSensitiveKey = async (passphrase: string, salt: string) =>
    inWorker()
        ? ei._deriveSensitiveKey(passphrase, salt)
        : sharedWorker().then((w) => w.deriveSensitiveKey(passphrase, salt));

/**
 * Derive an interactive key from the given {@link passphrase}.
 */
export const deriveInteractiveKey = async (passphrase: string, salt: string) =>
    inWorker()
        ? ei._deriveInteractiveKey(passphrase, salt)
        : sharedWorker().then((w) => w.deriveInteractiveKey(passphrase, salt));
