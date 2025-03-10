// TODO: Review this file
/* eslint-disable @typescript-eslint/prefer-optional-chain */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { sharedCryptoWorker } from "@/base/crypto";
import type { Collection } from "@/media/collection";
import type { EnteFile, MagicMetadataCore } from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";

export function isArchivedFile(item: EnteFile): boolean {
    if (!item || !item.magicMetadata || !item.magicMetadata.data) {
        return false;
    }
    return item.magicMetadata.data.visibility === ItemVisibility.archived;
}

export const isArchivedCollection = (item: Collection) => {
    if (!item) {
        return false;
    }

    if (item.magicMetadata && item.magicMetadata.data) {
        return item.magicMetadata.data.visibility === ItemVisibility.archived;
    }

    if (item.sharedMagicMetadata && item.sharedMagicMetadata.data) {
        return (
            item.sharedMagicMetadata.data.visibility === ItemVisibility.archived
        );
    }
    return false;
};

export function isPinnedCollection(item: Collection) {
    if (
        !item ||
        !item.magicMetadata ||
        !item.magicMetadata.data ||
        typeof item.magicMetadata.data === "string" ||
        typeof item.magicMetadata.data.order === "undefined"
    ) {
        return false;
    }
    return item.magicMetadata.data.order !== 0;
}

export async function updateMagicMetadata<T>(
    magicMetadataUpdates: T,
    originalMagicMetadata?: MagicMetadataCore<T>,
    decryptionKey?: string,
): Promise<MagicMetadataCore<T>> {
    const cryptoWorker = await sharedCryptoWorker();

    if (!originalMagicMetadata) {
        originalMagicMetadata = getNewMagicMetadata<T>();
    }

    if (typeof originalMagicMetadata?.data === "string") {
        // TODO: When converting this (and other parses of magic metadata) to
        // use zod, remember to use passthrough.
        //
        // See: [Note: Use passthrough for metadata Zod schemas]
        // @ts-expect-error TODO: Need to use zod here.
        originalMagicMetadata.data = await cryptoWorker.decryptMetadataJSON({
            encryptedDataB64: originalMagicMetadata.data,
            decryptionHeaderB64: originalMagicMetadata.header,
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            keyB64: decryptionKey,
        });
    }
    // copies the existing magic metadata properties of the files and updates the visibility value
    // The expected behavior while updating magic metadata is to let the existing property as it is and update/add the property you want
    const magicMetadataProps: T = {
        ...originalMagicMetadata.data,
        ...magicMetadataUpdates,
    };

    const nonEmptyMagicMetadataProps =
        getNonEmptyMagicMetadataProps(magicMetadataProps);

    const magicMetadata = {
        ...originalMagicMetadata,
        data: nonEmptyMagicMetadataProps,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        count: Object.keys(nonEmptyMagicMetadataProps).length,
    };

    return magicMetadata;
}

export const getNewMagicMetadata = <T>(): MagicMetadataCore<T> => {
    return {
        version: 1,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        data: null,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        header: null,
        count: 0,
    };
};

export const getNonEmptyMagicMetadataProps = <T>(magicMetadataProps: T): T => {
    return Object.fromEntries(
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        Object.entries(magicMetadataProps).filter(
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            ([_, v]) => v !== null && v !== undefined,
        ),
    ) as T;
};
