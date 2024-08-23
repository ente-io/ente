/**
 * @file A thin-ish layer over the actual libsodium APIs, to make them more
 * palatable to the rest of our Javascript code.
 *
 * All functions are stateless, async, and safe to use in Web Workers.
 *
 * Docs for the JS library: https://github.com/jedisct1/libsodium.js.
 *
 * To see where this code fits, see [Note: Crypto code hierarchy].
 */
import { mergeUint8Arrays } from "@/utils/array";
import { CustomError } from "@ente/shared/error";
import sodium, { type StateAddress } from "libsodium-wrappers-sumo";
import type {
    BytesOrB64,
    EncryptedBlob,
    EncryptedBlobB64,
    EncryptedBlobBytes,
    EncryptedBox,
    EncryptedBoxB64,
} from "./types";

/**
 * Convert bytes ({@link Uint8Array}) to a base64 string.
 *
 * See also {@link toB64URLSafe} and {@link toB64URLSafeNoPadding}.
 */
export const toB64 = async (input: Uint8Array) => {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.ORIGINAL);
};

/**
 * Convert a base64 string to bytes ({@link Uint8Array}).
 *
 * This is the converse of {@link toBase64}.
 */
export const fromB64 = async (input: string) => {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.ORIGINAL);
};

/**
 * Convert bytes ({@link Uint8Array}) to a URL-safe base64 string.
 *
 * See also {@link toB64URLSafe} and {@link toB64URLSafeNoPadding}.
 */
export const toB64URLSafe = async (input: Uint8Array) => {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.URLSAFE);
};

/**
 * Convert bytes ({@link Uint8Array}) to a unpadded URL-safe base64 string.
 *
 * This differs from {@link toB64URLSafe} in that it does not append any
 * trailing padding character(s) "=" to make the resultant string's length be an
 * integer multiple of 4.
 *
 * -   In some contexts, for example when serializing WebAuthn binary for
 *     transmission over the network, this is the required / recommended
 *     approach.
 *
 * -   In other cases, for example when trying to pass an arbitrary JSON string
 *     via a URL parameter, this is also convenient so that we do not have to
 *     deal with any ambiguity surrounding the "=" which is also the query
 *     parameter key value separator.
 */
export const toB64URLSafeNoPadding = async (input: Uint8Array) => {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.URLSAFE_NO_PADDING);
};

/**
 * Convert a unpadded URL-safe base64 string to  bytes ({@link Uint8Array}).
 *
 * This is the converse of {@link toB64URLSafeNoPadding}, and does not expect
 * its input string's length to be a an integer multiple of 4.
 */
export const fromB64URLSafeNoPadding = async (input: string) => {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.URLSAFE_NO_PADDING);
};

/**
 * Variant of {@link toB64URLSafeNoPadding} that works with {@link string}
 * inputs. See also its sibling method {@link fromB64URLSafeNoPaddingString}.
 */
export const toB64URLSafeNoPaddingString = async (input: string) => {
    await sodium.ready;
    return toB64URLSafeNoPadding(sodium.from_string(input));
};

/**
 * Variant of {@link fromB64URLSafeNoPadding} that works with {@link strings}. See also
 * its sibling method {@link toB64URLSafeNoPaddingString}.
 */
export const fromB64URLSafeNoPaddingString = async (input: string) => {
    await sodium.ready;
    return sodium.to_string(await fromB64URLSafeNoPadding(input));
};

export async function fromUTF8(input: string) {
    await sodium.ready;
    return sodium.from_string(input);
}

export async function toUTF8(input: string) {
    await sodium.ready;
    return sodium.to_string(await fromB64(input));
}

export async function toHex(input: string) {
    await sodium.ready;
    return sodium.to_hex(await fromB64(input));
}

export async function fromHex(input: string) {
    await sodium.ready;
    return await toB64(sodium.from_hex(input));
}

/**
 * If the provided {@link bob} ("Bytes or B64 string") is already a
 * {@link Uint8Array}, return it unchanged, otherwise convert the base64 string
 * into bytes and return those.
 */
const bytes = async (bob: BytesOrB64) =>
    typeof bob == "string" ? fromB64(bob) : bob;

/**
 * Generate a key for use with the *Box encryption functions.
 *
 * This returns a new randomly generated 256-bit key suitable for being used
 * with libsodium's secretbox APIs.
 */
export const generateBoxKey = async () => {
    await sodium.ready;
    return toB64(sodium.crypto_secretbox_keygen());
};

/**
 * Encrypt the given data using libsodium's secretbox APIs, using a randomly
 * generated nonce.
 *
 * Use {@link decryptBox} to decrypt the result.
 *
 * @param data The data to encrypt.
 *
 * @param key The key to use for encryption.
 *
 * @returns The encrypted data and the generated nonce, both as base64 strings.
 *
 * [Note: 3 forms of encryption (Box | Blob | Stream)]
 *
 * libsodium provides two "high level" encryption patterns:
 *
 * 1.  Authenticated encryption ("secretbox")
 *     https://doc.libsodium.org/secret-key_cryptography/secretbox
 *
 * 2.  Encrypted streams and file encryption ("secretstream")
 *     https://doc.libsodium.org/secret-key_cryptography/secretstream
 *
 * In terms of the underlying algorithm, they are essentially the same.
 *
 * 1.  The secretbox APIs use XSalsa20 with Poly1305 (where XSalsa20 is the
 *     stream cipher used for encryption, which Poly1305 is the MAC used for
 *     authentication).
 *
 * 2.  The secretstream APIs use XChaCha20 with Poly1305.
 *
 * XSalsa20 is a minor variant (predecessor in fact) of XChaCha20. I am not
 * aware why libsodium uses both the variants, but they seem to have similar
 * characteristics.
 *
 * These two sets of APIs map functionally map to two different use cases.
 *
 * 1.  If there is a single independent bit of data to encrypt, the secretbox
 *     APIs fit the bill.
 *
 * 2.  If there is a set of related data to encrypt, e.g. the contents of a file
 *     where the file is too big to fit into a single message, then the
 *     secretstream APIs are more appropriate.
 *
 * However, in our code we have evolved two different use cases for the 2nd
 * option.
 *
 * Say we have an Ente object, specifically an {@link EnteFile}. This holds the
 * encryption keys for encrypting the contents of the file that a user wishes to
 * upload. The secretstream APIs are the obvious fit, and indeed that's what we
 * use, chunking the file if the contents are bigger than some threshold. But if
 * the file is small enough, there is no need to chunk, so we also expose a
 * function that does streaming encryption, but in "one-shot" mode.
 *
 * Later on, say we have to encrypt the public magic metadata associated with
 * the {@link EnteFile}. Instead of using the secretbox APIs, we just us the
 * same streaming encryption that the rest of the file uses, but since such
 * metadata is well below the threshold for chunking, it invariably uses the
 * "one-shot" mode.
 *
 * Thus, we have three scenarios:
 *
 * 1.  Box: Using secretbox APIs to encrypt some independent blob of data.
 *
 * 2.  Blob: Using secretstream APIs in one-shot mode. This is used to encrypt
 *     data associated to an Ente object (file, collection, entity, etc), when
 *     the data is small-ish (less than a few MBs).
 *
 * 3.  Stream/Chunks: Using secretstream APIs for encrypting chunks. This is
 *     used to encrypt the actual content of the files associated with an
 *     EnteFile object.
 *
 * "Blob" is not a prior term of art in this context, it is just something we
 * use to abbreviate "data encrypted using secretstream APIs in one-shot mode".
 *
 * The distinction between Box and Blob is also handy since not only does the
 * underlying algorithm differ, but also the terminology that libsodium use for
 * the nonce.
 *
 * 1.  When using the secretbox APIs, the nonce is called the "nonce", and needs
 *     to be provided by us (the caller).
 *
 * 2.  When using the secretstream APIs, the nonce is internally generated by
 *     libsodium and provided by libsodium to us (the caller) as a "header".
 *
 * However, even for case 1, the functions we expose from libsodium.ts generate
 * the nonce for the caller. So for higher level functions, the difference
 * between Box and Blob encryption is:
 *
 * 1.  Box uses secretbox APIs (Salsa), Blob uses secretstream APIs (ChaCha).
 *
 * 2.  While both are one-shot, Blob should generally be used for data
 *     associated with an Ente object, and Box for the other cases.
 *
 * 3.  Box returns a "nonce", while Blob returns a "header".
 */
export const encryptBoxB64 = async (
    data: BytesOrB64,
    key: BytesOrB64,
): Promise<EncryptedBoxB64> => {
    await sodium.ready;
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(
        await bytes(data),
        nonce,
        await bytes(key),
    );
    return {
        encryptedData: await toB64(encryptedData),
        nonce: await toB64(nonce),
    };
};

/**
 * Encrypt the given data using libsodium's secretstream APIs in one-shot mode.
 *
 * Use {@link decryptBlob} to decrypt the result.
 *
 * @param data The data to encrypt.
 *
 * @param key The key to use for encryption.
 *
 * @returns The encrypted data and the decryption header as {@link Uint8Array}s.
 *
 * -   See: [Note: 3 forms of encryption (Box | Blob | Stream)].
 *
 * -   See: https://doc.libsodium.org/secret-key_cryptography/secretstream
 */
export const encryptBlob = async (
    data: BytesOrB64,
    key: BytesOrB64,
): Promise<EncryptedBlobBytes> => {
    await sodium.ready;

    const uintkey = await bytes(key);
    const initPushResult =
        sodium.crypto_secretstream_xchacha20poly1305_init_push(uintkey);
    const [pushState, header] = [initPushResult.state, initPushResult.header];

    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
        pushState,
        await bytes(data),
        null,
        sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL,
    );
    return {
        encryptedData: pushResult,
        decryptionHeader: header,
    };
};

/**
 * A variant of {@link encryptBlob} that returns the both the encrypted data and
 * decryption header as base64 strings.
 */
export const encryptBlobB64 = async (
    data: BytesOrB64,
    key: BytesOrB64,
): Promise<EncryptedBlobB64> => {
    const { encryptedData, decryptionHeader } = await encryptBlob(data, key);
    return {
        encryptedData: await toB64(encryptedData),
        decryptionHeader: await toB64(decryptionHeader),
    };
};

export const ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;

export const encryptChaCha = async (data: Uint8Array) => {
    await sodium.ready;

    const uintkey: Uint8Array =
        sodium.crypto_secretstream_xchacha20poly1305_keygen();

    const initPushResult =
        sodium.crypto_secretstream_xchacha20poly1305_init_push(uintkey);
    const [pushState, header] = [initPushResult.state, initPushResult.header];
    let bytesRead = 0;
    let tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;

    const encryptedChunks = [];

    while (tag !== sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        let chunkSize = ENCRYPTION_CHUNK_SIZE;
        if (bytesRead + chunkSize >= data.length) {
            chunkSize = data.length - bytesRead;
            tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL;
        }

        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        bytesRead += chunkSize;
        const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
            pushState,
            buffer,
            null,
            tag,
        );
        encryptedChunks.push(pushResult);
    }
    return {
        key: await toB64(uintkey),
        file: {
            encryptedData: mergeUint8Arrays(encryptedChunks),
            decryptionHeader: await toB64(header),
        },
    };
};

export async function initChunkEncryption() {
    await sodium.ready;
    const key = sodium.crypto_secretstream_xchacha20poly1305_keygen();
    const initPushResult =
        sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
    const [pushState, header] = [initPushResult.state, initPushResult.header];
    return {
        key: await toB64(key),
        decryptionHeader: await toB64(header),
        pushState,
    };
}

export async function encryptFileChunk(
    data: Uint8Array,
    pushState: sodium.StateAddress,
    isFinalChunk: boolean,
) {
    await sodium.ready;
    const tag = isFinalChunk
        ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
        : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
        pushState,
        data,
        null,
        tag,
    );

    return pushResult;
}

/**
 * Decrypt the result of {@link encryptBoxB64}.
 */
export const decryptBox = async (
    { encryptedData, nonce }: EncryptedBox,
    key: BytesOrB64,
): Promise<Uint8Array> => {
    await sodium.ready;
    return sodium.crypto_secretbox_open_easy(
        await bytes(encryptedData),
        await bytes(nonce),
        await bytes(key),
    );
};

/**
 * Variant of {@link decryptBox} that returns the data as a base64 string.
 */
export const decryptBoxB64 = (
    box: EncryptedBox,
    key: BytesOrB64,
): Promise<string> => decryptBox(box, key).then(toB64);

/**
 * Decrypt the result of {@link encryptBlob} or {@link encryptBlobB64}.
 */
export const decryptBlob = async (
    { encryptedData, decryptionHeader }: EncryptedBlob,
    key: BytesOrB64,
): Promise<Uint8Array> => {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        await bytes(decryptionHeader),
        await bytes(key),
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        await bytes(encryptedData),
        null,
    );
    return pullResult.message;
};

/**
 * A variant of {@link decryptBlob} that returns the result as a base64 string.
 */
export const decryptBlobB64 = (
    blob: EncryptedBlob,
    key: BytesOrB64,
): Promise<string> => decryptBlob(blob, key).then(toB64);

/** Decrypt Stream, but merge the results. */
export const decryptChaCha = async (
    data: Uint8Array,
    header: Uint8Array,
    key: string,
) => {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(key),
    );
    const decryptionChunkSize =
        ENCRYPTION_CHUNK_SIZE +
        sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
    let bytesRead = 0;
    const decryptedChunks = [];
    let tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
    while (tag !== sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        let chunkSize = decryptionChunkSize;
        if (bytesRead + chunkSize > data.length) {
            chunkSize = data.length - bytesRead;
        }
        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
            pullState,
            buffer,
        );
        // TODO:
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (!pullResult.message) {
            throw new Error(CustomError.PROCESSING_FAILED);
        }
        decryptedChunks.push(pullResult.message);
        tag = pullResult.tag;
        bytesRead += chunkSize;
    }
    return mergeUint8Arrays(decryptedChunks);
};

export async function initChunkDecryption(header: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        key,
    );
    const decryptionChunkSize =
        ENCRYPTION_CHUNK_SIZE +
        sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
    const tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
    return { pullState, decryptionChunkSize, tag };
}

export async function decryptFileChunk(
    data: Uint8Array,
    pullState: StateAddress,
) {
    await sodium.ready;
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        data,
    );
    // TODO:
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (!pullResult.message) {
        throw new Error(CustomError.PROCESSING_FAILED);
    }
    const newTag = pullResult.tag;
    return { decryptedData: pullResult.message, newTag };
}

export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

/** Deprecated, use {@link encryptBoxB64} instead */
export async function encryptToB64(data: string, keyB64: string) {
    await sodium.ready;
    const encrypted = await encryptBoxB64(data, keyB64);
    return {
        encryptedData: encrypted.encryptedData,
        key: keyB64,
        nonce: encrypted.nonce,
    } as B64EncryptionResult;
}

export async function generateKeyAndEncryptToB64(data: string) {
    await sodium.ready;
    const key = sodium.crypto_secretbox_keygen();
    return await encryptToB64(data, await toB64(key));
}

export async function encryptUTF8(data: string, key: string) {
    const b64Data = await toB64(await fromUTF8(data));
    return await encryptToB64(b64Data, key);
}

/** Deprecated, use {@link decryptBoxB64} instead. */
export async function decryptB64(
    encryptedData: string,
    nonce: string,
    keyB64: string,
) {
    return decryptBoxB64({ encryptedData, nonce }, keyB64);
}

/** Deprecated */
export async function decryptToUTF8(
    encryptedData: string,
    nonce: string,
    keyB64: string,
) {
    await sodium.ready;
    const decrypted = await decryptBox({ encryptedData, nonce }, keyB64);
    return sodium.to_string(decrypted);
}

export async function initChunkHashing() {
    await sodium.ready;
    const hashState = sodium.crypto_generichash_init(
        null,
        sodium.crypto_generichash_BYTES_MAX,
    );
    return hashState;
}

export async function hashFileChunk(
    hashState: sodium.StateAddress,
    chunk: Uint8Array,
) {
    await sodium.ready;
    sodium.crypto_generichash_update(hashState, chunk);
}

export async function completeChunkHashing(hashState: sodium.StateAddress) {
    await sodium.ready;
    const hash = sodium.crypto_generichash_final(
        hashState,
        sodium.crypto_generichash_BYTES_MAX,
    );
    const hashString = toB64(hash);
    return hashString;
}

export async function deriveKey(
    passphrase: string,
    salt: string,
    opsLimit: number,
    memLimit: number,
) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_pwhash(
            sodium.crypto_secretbox_KEYBYTES,
            await fromUTF8(passphrase),
            await fromB64(salt),
            opsLimit,
            memLimit,
            sodium.crypto_pwhash_ALG_ARGON2ID13,
        ),
    );
}

export async function deriveSensitiveKey(passphrase: string, salt: string) {
    await sodium.ready;
    const minMemLimit = sodium.crypto_pwhash_MEMLIMIT_MIN;
    let opsLimit = sodium.crypto_pwhash_OPSLIMIT_SENSITIVE;
    let memLimit = sodium.crypto_pwhash_MEMLIMIT_SENSITIVE;
    while (memLimit > minMemLimit) {
        try {
            const key = await deriveKey(passphrase, salt, opsLimit, memLimit);
            return {
                key,
                opsLimit,
                memLimit,
            };
        } catch (e) {
            opsLimit *= 2;
            memLimit /= 2;
        }
    }
    throw new Error("Failed to derive key: Memory limit exceeded");
}

export async function deriveInteractiveKey(passphrase: string, salt: string) {
    await sodium.ready;
    const key = await toB64(
        sodium.crypto_pwhash(
            sodium.crypto_secretbox_KEYBYTES,
            await fromUTF8(passphrase),
            await fromB64(salt),
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_ARGON2ID13,
        ),
    );
    return {
        key,
        opsLimit: sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
        memLimit: sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
    };
}

export async function generateEncryptionKey() {
    await sodium.ready;
    return await toB64(sodium.crypto_kdf_keygen());
}

export async function generateSaltToDeriveKey() {
    await sodium.ready;
    return await toB64(sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES));
}

/**
 * Generate a new public/private keypair, and return their base64
 * representations.
 */
export const generateKeyPair = async () => {
    await sodium.ready;
    const keyPair = sodium.crypto_box_keypair();
    return {
        publicKey: await toB64(keyPair.publicKey),
        privateKey: await toB64(keyPair.privateKey),
    };
};

export async function boxSealOpen(
    input: string,
    publicKey: string,
    secretKey: string,
) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_box_seal_open(
            await fromB64(input),
            await fromB64(publicKey),
            await fromB64(secretKey),
        ),
    );
}

export async function boxSeal(input: string, publicKey: string) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_box_seal(await fromB64(input), await fromB64(publicKey)),
    );
}

export async function generateSubKey(
    key: string,
    subKeyLength: number,
    subKeyID: number,
    context: string,
) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_kdf_derive_from_key(
            subKeyLength,
            subKeyID,
            context,
            await fromB64(key),
        ),
    );
}
