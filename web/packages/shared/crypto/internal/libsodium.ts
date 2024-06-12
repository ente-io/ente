import { CustomError } from "@ente/shared/error";
import sodium, { type StateAddress } from "libsodium-wrappers";
import { ENCRYPTION_CHUNK_SIZE } from "../constants";
import type { B64EncryptionResult } from "../types";

export async function decryptChaChaOneShot(
    data: Uint8Array,
    header: Uint8Array,
    key: string,
) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(key),
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        data,
        null,
    );
    return pullResult.message;
}

export async function decryptChaCha(
    data: Uint8Array,
    header: Uint8Array,
    key: string,
) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(key),
    );
    const decryptionChunkSize =
        ENCRYPTION_CHUNK_SIZE +
        sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
    let bytesRead = 0;
    const decryptedData = [];
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
        for (let index = 0; index < pullResult.message.length; index++) {
            decryptedData.push(pullResult.message[index]);
        }
        tag = pullResult.tag;
        bytesRead += chunkSize;
    }
    return Uint8Array.from(decryptedData);
}

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

export async function encryptChaChaOneShot(data: Uint8Array, key: string) {
    await sodium.ready;

    const uintkey: Uint8Array = await fromB64(key);
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
        key: await toB64(uintkey),
        file: {
            encryptedData: pushResult,
            decryptionHeader: await toB64(header),
        },
    };
}

export async function encryptChaCha(data: Uint8Array) {
    await sodium.ready;

    const uintkey: Uint8Array =
        sodium.crypto_secretstream_xchacha20poly1305_keygen();

    const initPushResult =
        sodium.crypto_secretstream_xchacha20poly1305_init_push(uintkey);
    const [pushState, header] = [initPushResult.state, initPushResult.header];
    let bytesRead = 0;
    let tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;

    const encryptedData = [];

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
        for (let index = 0; index < pushResult.length; index++) {
            encryptedData.push(pushResult[index]);
        }
    }
    return {
        key: await toB64(uintkey),
        file: {
            encryptedData: new Uint8Array(encryptedData),
            decryptionHeader: await toB64(header),
        },
    };
}

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
 * Generate a new public/private keypair, and return their Base64
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

export async function fromB64(input: string) {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.ORIGINAL);
}

export async function toB64(input: Uint8Array) {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.ORIGINAL);
}

/** Convert a {@link Uint8Array} to a URL safe Base64 encoded string. */
export const toB64URLSafe = async (input: Uint8Array) => {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.URLSAFE);
};

/**
 * Convert a {@link Uint8Array} to a URL safe Base64 encoded string.
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
 * Convert a Base64 encoded string to a {@link Uint8Array}.
 *
 * This is the converse of {@link toB64URLSafeNoPadding}, and does not expect
 * its input string's length to be a an integer multiple of 4.
 */
export const fromB64URLSafeNoPadding = async (input: string) => {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.URLSAFE_NO_PADDING);
};

/**
 * Variant of {@link toB64URLSafeNoPadding} that works with {@link strings}. See also
 * its sibling method {@link fromB64URLSafeNoPaddingString}.
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
