/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type { BytesOrB64, EncryptedBlob_2, EncryptJSON } from "./types";

export const _encryptBoxB64 = libsodium.encryptBoxB64;

export const _encryptBlob = libsodium.encryptBlob;

export const _encryptBlobB64 = libsodium.encryptBlobB64;

export const _encryptThumbnail = async (data: BytesOrB64, key: BytesOrB64) => {
    const { encryptedData, decryptionHeader } = await _encryptBlob(data, key);
    return {
        encryptedData,
        decryptionHeader: await libsodium.toB64(decryptionHeader),
    };
};

export const _encryptMetadataJSON_New = ({ jsonValue, keyB64 }: EncryptJSON) =>
    _encryptBlobB64(
        new TextEncoder().encode(JSON.stringify(jsonValue)),
        keyB64,
    );

export const _encryptMetadataJSON = async (r: EncryptJSON) => {
    // Deprecated. Keep the old API for now.
    const { encryptedData, decryptionHeader } =
        await _encryptMetadataJSON_New(r);
    return {
        encryptedDataB64: encryptedData,
        decryptionHeaderB64: decryptionHeader,
    };
};

export const _decryptBox = libsodium.decryptBox2;

export const _decryptBoxB64 = libsodium.decryptBoxB64;

export const _decryptBlob = libsodium.decryptBlob2;

export const _decryptBlobB64 = libsodium.decryptBlobB64;

export const _decryptThumbnail = _decryptBlob;

export const _decryptMetadataJSON_New = async (
    blob: EncryptedBlob_2,
    key: BytesOrB64,
) =>
    JSON.parse(
        new TextDecoder().decode(await _decryptBlob(blob, key)),
    ) as unknown;

export const _decryptMetadataJSON = async (r: {
    encryptedDataB64: string;
    decryptionHeaderB64: string;
    keyB64: string;
}) =>
    _decryptMetadataJSON_New(
        {
            encryptedData: r.encryptedDataB64,
            decryptionHeader: r.decryptionHeaderB64,
        },
        r.keyB64,
    );
