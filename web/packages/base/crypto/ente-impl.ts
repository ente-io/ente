/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";
import type { EncryptBytes, EncryptJSON } from "./types";

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

export const decryptThumbnailI = decryptAssociatedDataI;

export const decryptFileEmbeddingI = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    decryptAssociatedDataI(
        await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    );

export const decryptMetadataI = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    JSON.parse(
        new TextDecoder().decode(
            await decryptMetadataBytesI(
                encryptedDataB64,
                decryptionHeaderB64,
                keyB64,
            ),
        ),
    ) as unknown;

export const decryptMetadataBytesI = async (
    encryptedDataB64: string,
    decryptionHeaderB64: string,
    keyB64: string,
) =>
    await decryptAssociatedDataI(
        await libsodium.fromB64(encryptedDataB64),
        decryptionHeaderB64,
        keyB64,
    );
