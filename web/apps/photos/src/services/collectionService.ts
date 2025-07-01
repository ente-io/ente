import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { sortFiles } from "ente-gallery/utils/file";
import { EnteFile } from "ente-media/file";
import {
    addToFavoritesCollection,
    removeFromOwnCollection,
    savedUserFavoritesCollection,
} from "ente-new/photos/services/collection";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { CollectionsSortBy } from "ente-new/photos/services/collection-summary";
import { savedCollectionFiles } from "ente-new/photos/services/photos-fdb";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";

export const addToFavorites1 = async (file: EnteFile) => {
    await addToFavoritesCollection([file]);
};

export const removeFromFavorites1 = async (file: EnteFile) => {
    const favCollection = await savedUserFavoritesCollection();
    if (!favCollection) {
        throw Error("favorite collection missing");
    }
    await removeFromOwnCollection(favCollection.id, [file]);
};

export const deleteCollection = async (
    collectionID: number,
    keepFiles: boolean,
) => {
    try {
        if (keepFiles) {
            const allFiles = await savedCollectionFiles();
            const collectionFiles = allFiles.filter(
                (file) => file.collectionID == collectionID,
            );
            await removeFromOwnCollection(collectionID, collectionFiles);
        }
        const token = getToken();

        await HTTPService.delete(
            await apiURL(`/collections/v3/${collectionID}`),
            null,
            { collectionID, keepFiles },
            { "X-Auth-Token": token },
        );
    } catch (e) {
        log.error("delete collection failed ", e);
        throw e;
    }
};

export const sortCollectionSummaries = (
    collectionSummaries: CollectionSummary[],
    by: CollectionsSortBy,
) =>
    collectionSummaries
        .sort((a, b) => {
            switch (by) {
                case "name":
                    return a.name.localeCompare(b.name);
                case "creation-time-asc":
                    return (
                        -1 *
                        compareCollectionsLatestFile(b.latestFile, a.latestFile)
                    );
                case "updation-time-desc":
                    return (b.updationTime ?? 0) - (a.updationTime ?? 0);
            }
        })
        .sort((a, b) => b.sortPriority - a.sortPriority);

function compareCollectionsLatestFile(
    first: EnteFile | undefined,
    second: EnteFile | undefined,
) {
    if (!first) {
        return 1;
    } else if (!second) {
        return -1;
    } else {
        const sortedFiles = sortFiles([first, second]);
        if (sortedFiles[0].id !== first.id) {
            return 1;
        } else {
            return -1;
        }
    }
}
