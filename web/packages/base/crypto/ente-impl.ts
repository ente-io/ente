/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";

export const encryptAssociatedDataI = libsodium.encryptChaChaOneShot;

export const encryptThumbnailI = encryptAssociatedDataI;

export const encryptFileEmbeddingI = async (
    data: Uint8Array,
    keyB64: string,
) => {
    const { encryptedData, decryptionHeaderB64 } = await encryptAssociatedDataI(
        data,
        keyB64,
    );
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

export const encryptMetadataI = async (metadata: unknown, keyB64: string) => {
    const encodedMetadata = new TextEncoder().encode(JSON.stringify(metadata));

    const { encryptedData, decryptionHeaderB64 } = await encryptAssociatedDataI(
        encodedMetadata,
        keyB64,
    );
    return {
        encryptedDataB64: await libsodium.toB64(encryptedData),
        decryptionHeaderB64,
    };
};

export const decryptAssociatedDataI = libsodium.decryptChaChaOneShot;

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
