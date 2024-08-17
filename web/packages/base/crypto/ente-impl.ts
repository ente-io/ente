/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type {
    BytesOrB64,
    DecryptBlobB64,
    EncryptBytes,
    EncryptedBlobB64,
    EncryptedBlobBytes,
    EncryptedBox2,
    EncryptJSON,
} from "./types";

const EncryptedBlobBytesToB64 = async ({
    encryptedData,
    decryptionHeaderB64,
}: EncryptedBlobBytes): Promise<EncryptedBlobB64> => ({
    encryptedDataB64: await libsodium.toB64(encryptedData),
    decryptionHeaderB64,
});

export const _encryptBoxB64 = libsodium.encryptBoxB64;

export const _encryptAssociatedData = libsodium.encryptBlob;

export const _encryptThumbnail = _encryptAssociatedData;

export const _encryptAssociatedDataB64 = (r: EncryptBytes) =>
    _encryptAssociatedData(r).then(EncryptedBlobBytesToB64);

export const _encryptMetadataJSON = ({ jsonValue, keyB64 }: EncryptJSON) =>
    _encryptAssociatedDataB64({
        data: new TextEncoder().encode(JSON.stringify(jsonValue)),
        keyB64,
    });

export const _decryptBox = libsodium.decryptBox2;

export const _decryptBoxB64 = (b: EncryptedBox2, k: BytesOrB64) =>
    _decryptBox(b, k).then(libsodium.toB64);

export const _decryptAssociatedData = libsodium.decryptBlob;

export const _decryptThumbnail = _decryptAssociatedData;

export const _decryptAssociatedDataB64 = async ({
    encryptedDataB64,
    decryptionHeaderB64,
    keyB64,
}: DecryptBlobB64) =>
    await _decryptAssociatedData({
        encryptedData: await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    });

export const _decryptMetadataJSON = async (r: DecryptBlobB64) =>
    JSON.parse(
        new TextDecoder().decode(await _decryptAssociatedDataB64(r)),
    ) as unknown;
