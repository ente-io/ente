// TODO: Review this file
/* eslint-disable @typescript-eslint/prefer-optional-chain */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { sharedCryptoWorker } from "@/base/crypto";
import type { Collection } from "@/media/collection";
import { fileLogID, type EnteFile, type MagicMetadataCore } from "@/media/file";
import {
    ItemVisibility,
    type PrivateMagicMetadata,
} from "@/media/file-metadata";

/**
 * Return the magic metadata for an {@link EnteFile}.
 *
 * We are not expected to be in a scenario where the file gets to the UI without
 * having its magic metadata decrypted, so this function is a sanity
 * check and should be a no-op in usually. It'll throw if it finds its
 * assumptions broken. Once the types have been refactored this entire
 * check/cast shouldn't be needed, and this should become a trivial accessor.
 */
export const fileMagicMetadata = (file: EnteFile) => {
    if (!file.magicMetadata) return undefined;
    if (typeof file.magicMetadata.data == "string") {
        throw new Error(
            `Magic metadata for ${fileLogID(file)} had not been decrypted even when the file reached the UI layer`,
        );
    }
    // This cast is unavoidable in the current setup. We need to refactor the
    // types so that this cast in not needed.
    return file.magicMetadata.data as PrivateMagicMetadata;
};

/**
 * Return the {@link ItemVisibility} for the given {@link file}.
 */
export const fileVisibility = (file: EnteFile) =>
    fileMagicMetadata(file)?.visibility;

export const isArchivedFile = (item: EnteFile) =>
    fileVisibility(item) === ItemVisibility.archived;

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
