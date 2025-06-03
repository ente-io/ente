/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type { BytesOrB64, EncryptedBlob, EncryptedFile } from "./types";

export const _toB64 = libsodium.toB64;

export const _toB64URLSafe = libsodium.toB64URLSafe;

export const _fromB64 = libsodium.fromB64;

export const _toHex = libsodium.toHex;

export const _fromHex = libsodium.fromHex;

export const _generateKey = libsodium.generateKey;

export const _generateBlobOrStreamKey = libsodium.generateBlobOrStreamKey;

export const _encryptBoxB64 = libsodium.encryptBoxB64;

export const _encryptBlob = libsodium.encryptBlob;

export const _encryptBlobB64 = libsodium.encryptBlobB64;

export const _encryptThumbnail = async (
    data: BytesOrB64,
    key: BytesOrB64,
): Promise<EncryptedFile> => {
    const { encryptedData, decryptionHeader } = await _encryptBlob(data, key);
    return {
        encryptedData,
        decryptionHeader: await libsodium.toB64(decryptionHeader),
    };
};

export const _encryptStreamBytes = libsodium.encryptStreamBytes;

export const _initChunkEncryption = libsodium.initChunkEncryption;

export const _encryptStreamChunk = libsodium.encryptStreamChunk;

export const _encryptMetadataJSON_New = (jsonValue: unknown, key: BytesOrB64) =>
    _encryptBlobB64(new TextEncoder().encode(JSON.stringify(jsonValue)), key);

// Deprecated, translates to the old API for now.
export const _encryptMetadataJSON = async (r: {
    jsonValue: unknown;
    keyB64: string;
}) => {
    const { encryptedData, decryptionHeader } = await _encryptMetadataJSON_New(
        r.jsonValue,
        r.keyB64,
    );
    return {
        encryptedDataB64: encryptedData,
        decryptionHeaderB64: decryptionHeader,
    };
};

export const _decryptBox = libsodium.decryptBox;

export const _decryptBoxB64 = libsodium.decryptBoxB64;

export const _decryptBlob = libsodium.decryptBlob;

export const _decryptBlobB64 = libsodium.decryptBlobB64;

export const _decryptThumbnail = _decryptBlob;

export const _decryptStreamBytes = libsodium.decryptStreamBytes;

export const _initChunkDecryption = libsodium.initChunkDecryption;

export const _decryptStreamChunk = libsodium.decryptStreamChunk;

export const _decryptMetadataJSON_New = async (
    blob: EncryptedBlob,
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

export const _chunkHashInit = libsodium.chunkHashInit;

export const _chunkHashUpdate = libsodium.chunkHashUpdate;

export const _chunkHashFinal = libsodium.chunkHashFinal;

export const _generateKeyPair = libsodium.generateKeyPair;

export const _boxSeal = libsodium.boxSeal;

export const _boxSealOpen = libsodium.boxSealOpen;

export const _deriveKey = libsodium.deriveKey;

export const _deriveSensitiveKey = libsodium.deriveSensitiveKey;

export const _deriveInteractiveKey = libsodium.deriveInteractiveKey;
