/**
 * @file A thin-ish layer over the actual libsodium APIs, to make them more
 * palatable to the rest of our Javascript code.
 *
 * All functions are stateless, async, and safe to use in Web Workers.
 *
 * Docs for the JS library: https://github.com/jedisct1/libsodium.js
 */
import { mergeUint8Arrays } from "@/utils/array";
import { CustomError } from "@ente/shared/error";
import sodium, { type StateAddress } from "libsodium-wrappers";

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
 * Encrypt the given {@link data} using the given (base64 encoded) key.
 *
 * Use {@link decryptChaChaOneShot} to decrypt the result.
 *
 * [Note: Salsa and ChaCha]
 *
 * This uses the same stream encryption algorithm (XChaCha20 stream cipher with
 * Poly1305 MAC authentication) that we use for encrypting other streams, in
 * particular the actual file's contents.
 *
 * The difference here is that this function does a one shot instead of a
 * streaming encryption. This is only meant to be used for relatively small
 * amounts of data (few MBs).
 *
 * See: https://doc.libsodium.org/secret-key_cryptography/secretstream
 *
 * Libsodium also provides the `crypto_secretbox_easy` APIs for one shot
 * encryption, which we do use in other places where we need to one shot
 * encryption of independent bits of data.
 *
 * These secretbox APIs use XSalsa20 with Poly1305. XSalsa20 is a minor variant
 * (predecessor in fact) of XChaCha20.
 *
 * See: https://doc.libsodium.org/secret-key_cryptography/secretbox
 *
 * The difference here is that this function is meant to used for data
 * associated with a file (or some other Ente object, like a collection or an
 * entity). There is no technical reason to do it that way, just this way all
 * data associated with a file, including its actual contents, use the same
 * underlying (streaming) libsodium APIs. In other cases, where we have free
 * standing independent data, we continue using the secretbox APIs for one shot
 * encryption and decryption.
 *
 * @param data A {@link Uint8Array} containing the bytes that we want to
 * encrypt.
 *
 * @param keyB64 A base64 string containing the encryption key.
 *
 * @returns The encrypted data (bytes) and decryption header pair (base64
 * encoded string). Both these values are needed to decrypt the data. The header
 * does not need to be secret.
 */
export const encryptChaChaOneShot = async (
    data: Uint8Array,
    keyB64: string,
) => {
    await sodium.ready;

    const uintkey: Uint8Array = await fromB64(keyB64);
    const initPushResult =
        sodium.crypto_secretstream_xchacha20poly1305_init_push(uintkey);
    const [pushState, header] = [initPushResult.state, initPushResult.header];

    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
        pushState,
        data,
        null,
        sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL,
    );
    return {
        encryptedData: pushResult,
        decryptionHeaderB64: await toB64(header),
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
 * Decrypt the result of {@link encryptChaChaOneShot}.
 *
 * @param encryptedData A {@link Uint8Array} containing the bytes to decrypt.
 *
 * @param header A base64 string containing the bytes of the decryption header
 * that was produced during encryption.
 *
 * @param keyB64 The base64 string containing the key that was used to encrypt
 * the data.
 *
 * @returns The decrypted bytes.
 *
 * @returns The decrypted metadata bytes.
 */
export const decryptChaChaOneShot2 = async (
    encryptedData: Uint8Array,
    headerB64: string,
    keyB64: string,
) => {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        await fromB64(headerB64),
        await fromB64(keyB64),
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        encryptedData,
        null,
    );
    return pullResult.message;
};

export const decryptChaChaOneShot = async (
    data: Uint8Array,
    header: Uint8Array,
    keyB64: string,
) => {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(keyB64),
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        data,
        null,
    );
    return pullResult.message;
};

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

export async function encryptToB64(data: string, key: string) {
    await sodium.ready;
    const encrypted = await encrypt(await fromB64(data), await fromB64(key));

    return {
        encryptedData: await toB64(encrypted.encryptedData),
        key: await toB64(encrypted.key),
        nonce: await toB64(encrypted.nonce),
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

export async function decryptB64(data: string, nonce: string, key: string) {
    await sodium.ready;
    const decrypted = await decrypt(
        await fromB64(data),
        await fromB64(nonce),
        await fromB64(key),
    );

    return await toB64(decrypted);
}

export async function decryptToUTF8(data: string, nonce: string, key: string) {
    await sodium.ready;
    const decrypted = await decrypt(
        await fromB64(data),
        await fromB64(nonce),
        await fromB64(key),
    );

    return sodium.to_string(decrypted);
}

async function encrypt(data: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(data, nonce, key);
    return {
        encryptedData,
        key,
        nonce,
    };
}

async function decrypt(data: Uint8Array, nonce: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    return sodium.crypto_secretbox_open_easy(data, nonce, key);
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
