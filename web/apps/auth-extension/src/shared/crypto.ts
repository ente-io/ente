/**
 * Crypto utilities adapted from packages/base/crypto/libsodium.ts.
 * Direct libsodium-wrappers-sumo usage without web worker.
 */
import sodium from "libsodium-wrappers-sumo";
import type { EncryptedBlob, EncryptedBox } from "./types";

type BytesOrB64 = Uint8Array | string;

/**
 * Convert bytes to a base64 string.
 */
export const toB64 = async (input: Uint8Array): Promise<string> => {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.ORIGINAL);
};

/**
 * Convert a base64 string to bytes.
 */
export const fromB64 = async (input: string): Promise<Uint8Array> => {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.ORIGINAL);
};

/**
 * Convert BytesOrB64 to bytes.
 */
const bytes = async (bob: BytesOrB64): Promise<Uint8Array> =>
    typeof bob === "string" ? fromB64(bob) : bob;

/**
 * Decrypt data encrypted with secretbox (Box encryption).
 */
export const decryptBoxBytes = async (
    { encryptedData, nonce }: EncryptedBox,
    key: BytesOrB64
): Promise<Uint8Array> => {
    await sodium.ready;
    return sodium.crypto_secretbox_open_easy(
        await bytes(encryptedData),
        await bytes(nonce),
        await bytes(key)
    );
};

/**
 * Decrypt box and return as base64 string.
 */
export const decryptBox = async (
    box: EncryptedBox,
    key: BytesOrB64
): Promise<string> => toB64(await decryptBoxBytes(box, key));

/**
 * Decrypt data encrypted with secretstream (Blob encryption).
 */
export const decryptBlobBytes = async (
    { encryptedData, decryptionHeader }: EncryptedBlob,
    key: BytesOrB64
): Promise<Uint8Array> => {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        await bytes(decryptionHeader),
        await bytes(key)
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        await bytes(encryptedData),
        null
    );
    return pullResult.message;
};

/**
 * Decrypt blob encrypted JSON metadata.
 */
export const decryptMetadataJSON = async (
    blob: EncryptedBlob,
    key: BytesOrB64
): Promise<unknown> =>
    JSON.parse(
        new TextDecoder().decode(await decryptBlobBytes(blob, key))
    ) as unknown;

/**
 * Derive a key using Argon2id.
 */
export const deriveKey = async (
    passphrase: string,
    salt: string,
    opsLimit: number,
    memLimit: number
): Promise<string> => {
    await sodium.ready;
    return await toB64(
        sodium.crypto_pwhash(
            sodium.crypto_secretbox_KEYBYTES,
            sodium.from_string(passphrase),
            await fromB64(salt),
            opsLimit,
            memLimit,
            sodium.crypto_pwhash_ALG_ARGON2ID13
        )
    );
};

/**
 * Generate a random encryption key.
 */
export const generateKey = async (): Promise<string> => {
    await sodium.ready;
    return toB64(sodium.crypto_secretbox_keygen());
};

/**
 * Encrypt data using secretbox.
 */
export const encryptBox = async (
    data: BytesOrB64,
    key: BytesOrB64
): Promise<EncryptedBox> => {
    await sodium.ready;
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(
        await bytes(data),
        nonce,
        await bytes(key)
    );
    return {
        encryptedData: await toB64(encryptedData),
        nonce: await toB64(nonce),
    };
};

/**
 * Hash a string using SHA256.
 */
export const hashString = async (input: string): Promise<string> => {
    await sodium.ready;
    return await toB64(sodium.crypto_hash(sodium.from_string(input)));
};

/**
 * Derive a subkey from a key.
 */
export const deriveSubKeyBytes = async (
    key: BytesOrB64,
    subKeyLength: number,
    subKeyID: number,
    context: string
): Promise<Uint8Array> => {
    await sodium.ready;
    return sodium.crypto_kdf_derive_from_key(
        subKeyLength,
        subKeyID,
        context,
        await bytes(key)
    );
};

/**
 * Box seal open (asymmetric decryption).
 */
export const boxSealOpenBytes = async (
    encryptedData: string,
    keyPair: { publicKey: string; privateKey: string }
): Promise<Uint8Array> => {
    await sodium.ready;
    return sodium.crypto_box_seal_open(
        await fromB64(encryptedData),
        await fromB64(keyPair.publicKey),
        await fromB64(keyPair.privateKey)
    );
};
