// TODO: Review this file
/* eslint-disable @typescript-eslint/prefer-optional-chain */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import type { Collection } from "ente-media/collection";
import { ItemVisibility } from "ente-media/file-metadata";

export interface MagicMetadataCore<T> {
    version: number;
    count: number;
    header: string;
    data: T;
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
        typeof item.magicMetadata.data == "string" ||
        typeof item.magicMetadata.data.order == "undefined"
    ) {
        return false;
    }
    return item.magicMetadata.data.order !== 0;
}
