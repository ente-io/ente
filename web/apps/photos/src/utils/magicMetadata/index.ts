import { sharedCryptoWorker } from "@/base/crypto";
import { ItemVisibility } from "@/media/file-metadata";
import { EnteFile } from "@/new/photos/types/file";
import { MagicMetadataCore } from "@/new/photos/types/magicMetadata";
import { Collection } from "types/collection";

export function isArchivedFile(item: EnteFile): boolean {
    if (!item || !item.magicMetadata || !item.magicMetadata.data) {
        return false;
    }
    return item.magicMetadata.data.visibility === ItemVisibility.archived;
}

export function isArchivedCollection(item: Collection): boolean {
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
}

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
        // @ts-expect-error TODO: Need to use zod here.
        originalMagicMetadata.data = await cryptoWorker.decryptMetadata(
            originalMagicMetadata.data,
            originalMagicMetadata.header,
            decryptionKey,
        );
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
        count: Object.keys(nonEmptyMagicMetadataProps).length,
    };

    return magicMetadata;
}

export const getNewMagicMetadata = <T>(): MagicMetadataCore<T> => {
    return {
        version: 1,
        data: null,
        header: null,
        count: 0,
    };
};

export const getNonEmptyMagicMetadataProps = <T>(magicMetadataProps: T): T => {
    return Object.fromEntries(
        Object.entries(magicMetadataProps).filter(
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            ([_, v]) => v !== null && v !== undefined,
        ),
    ) as T;
};
