/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type { DecryptB64, EncryptBytes, EncryptJSON } from "./types";

export const _encryptAssociatedData = libsodium.encryptChaChaOneShot;

export const _encryptThumbnail = _encryptAssociatedData;

export const _encryptFileEmbedding = async (r: EncryptBytes) => {
    const { encryptedData, decryptionHeaderB64 } =
        await _encryptAssociatedData(r);
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

export const _encryptMetadata = async ({ jsonValue, keyB64 }: EncryptJSON) => {
    const data = new TextEncoder().encode(JSON.stringify(jsonValue));

    const { encryptedData, decryptionHeaderB64 } = await _encryptAssociatedData(
        { data, keyB64 },
    );
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

export const _decryptAssociatedData = libsodium.decryptChaChaOneShot;

export const _decryptThumbnail = _decryptAssociatedData;

export const _decryptFileEmbedding = async ({
    encryptedDataB64,
    decryptionHeaderB64,
    keyB64,
}: DecryptB64) =>
    _decryptAssociatedData({
        encryptedData: await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    });

export const _decryptMetadata = async (r: DecryptB64) =>
    JSON.parse(
        new TextDecoder().decode(await _decryptMetadataBytes(r)),
    ) as unknown;

export const _decryptMetadataBytes = async ({
    encryptedDataB64,
    decryptionHeaderB64,
    keyB64,
}: DecryptB64) =>
    await _decryptAssociatedData({
        encryptedData: await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    });
