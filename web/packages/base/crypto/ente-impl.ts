/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type {
    DecryptB64,
    EncryptBytes,
    EncryptedB64,
    EncryptedBytes,
    EncryptJSON,
} from "./types";

const EncryptedBytesToB64 = async ({
    encryptedData,
    decryptionHeaderB64,
}: EncryptedBytes): Promise<EncryptedB64> => ({
    encryptedDataB64: await libsodium.toB64(encryptedData),
    decryptionHeaderB64,
});

export const _encryptAssociatedData = libsodium.encryptChaChaOneShot;

export const _encryptThumbnail = _encryptAssociatedData;

export const _encryptMetadataBytes = (r: EncryptBytes) =>
    _encryptAssociatedData(r).then(EncryptedBytesToB64);

export const _encryptFileEmbedding = _encryptMetadataBytes;

export const _encryptMetadataJSON = ({ jsonValue, keyB64 }: EncryptJSON) =>
    _encryptMetadataBytes({
        data: new TextEncoder().encode(JSON.stringify(jsonValue)),
        keyB64,
    });

export const _decryptAssociatedData = libsodium.decryptChaChaOneShot;

export const _decryptThumbnail = _decryptAssociatedData;

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

export const _decryptFileEmbedding = _decryptMetadataBytes;

export const _decryptMetadataJSON = async (r: DecryptB64) =>
    JSON.parse(
        new TextDecoder().decode(await _decryptMetadataBytes(r)),
    ) as unknown;
