import type { User } from "ente-accounts/services/user";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { groupFilesByCollectionID, sortFiles } from "ente-gallery/utils/file";
import { EnteFile } from "ente-media/file";
import {
    addToFavorites,
    createUncategorizedCollection,
    moveFromCollection,
    savedUserFavoritesCollection,
} from "ente-new/photos/services/collection";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import {
    CollectionSummaryOrder,
    CollectionsSortBy,
} from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import HTTPService from "ente-shared/network/HTTPService";
import { getData } from "ente-shared/storage/localStorage";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import { batch } from "ente-utils/array";
import { isValidMoveTarget } from "utils/collection";

const REQUEST_BATCH_SIZE = 1000;

export const addToFavorites1 = async (file: EnteFile) => {
    await addToFavorites([file]);
};

export const removeFromFavorites1 = async (file: EnteFile) => {
    const favCollection = await savedUserFavoritesCollection();
    if (!favCollection) {
        throw Error("favorite collection missing");
    }
    await removeFromCollection(favCollection.id, [file]);
};

export const removeFromCollection = async (
    collectionID: number,
    toRemoveFiles: EnteFile[],
) => {
    try {
        const user: User = getData("user");
        const nonUserFiles = [];
        const userFiles = [];
        for (const file of toRemoveFiles) {
            if (file.ownerID === user.id) {
                userFiles.push(file);
            } else {
                nonUserFiles.push(file);
            }
        }

        if (nonUserFiles.length > 0) {
            await removeNonUserFiles(collectionID, nonUserFiles);
        }
        if (userFiles.length > 0) {
            await removeUserFiles(collectionID, userFiles);
        }
    } catch (e) {
        log.error("remove from collection failed ", e);
        throw e;
    }
};

export const removeUserFiles = async (
    sourceCollectionID: number,
    toRemoveFiles: EnteFile[],
) => {
    try {
        const allFiles = await savedCollectionFiles();

        const toRemoveFilesIds = new Set(toRemoveFiles.map((f) => f.id));
        const toRemoveFilesCopiesInOtherCollections = allFiles.filter((f) => {
            return toRemoveFilesIds.has(f.id);
        });
        const groupedFiles = groupFilesByCollectionID(
            toRemoveFilesCopiesInOtherCollections,
        );

        const collections = await savedCollections();
        const collectionsMap = new Map(collections.map((c) => [c.id, c]));
        const user: User = getData("user");

        for (const [targetCollectionID, files] of groupedFiles.entries()) {
            const targetCollection = collectionsMap.get(targetCollectionID);
            if (
                !isValidMoveTarget(sourceCollectionID, targetCollection, user)
            ) {
                continue;
            }
            const toMoveFiles = files.filter((f) => {
                if (toRemoveFilesIds.has(f.id)) {
                    toRemoveFilesIds.delete(f.id);
                    return true;
                }
                return false;
            });
            if (toMoveFiles.length === 0) {
                continue;
            }
            await moveFromCollection(
                sourceCollectionID,
                targetCollection,
                toMoveFiles,
            );
        }
        const leftFiles = toRemoveFiles.filter((f) =>
            toRemoveFilesIds.has(f.id),
        );

        if (leftFiles.length === 0) {
            return;
        }

        const uncategorizedCollection =
            collections.find((c) => c.type == "uncategorized") ??
            (await createUncategorizedCollection());

        await moveFromCollection(
            sourceCollectionID,
            uncategorizedCollection,
            leftFiles,
        );
    } catch (e) {
        log.error("remove user files failed ", e);
        throw e;
    }
};

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}

export const removeNonUserFiles = async (
    collectionID: number,
    nonUserFiles: EnteFile[],
) => {
    try {
        const fileIDs = nonUserFiles.map((f) => f.id);
        const token = getToken();
        const batchedFileIDs = batch(fileIDs, REQUEST_BATCH_SIZE);
        for (const batch of batchedFileIDs) {
            const request: RemoveFromCollectionRequest = {
                collectionID,
                fileIDs: batch,
            };

            await HTTPService.post(
                await apiURL("/collections/v3/remove-files"),
                request,
                null,
                { "X-Auth-Token": token },
            );
        }
    } catch (e) {
        log.error("remove non user files failed ", e);
        throw e;
    }
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
            await removeFromCollection(collectionID, collectionFiles);
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
        .sort((a, b) => (b.order ?? 0) - (a.order ?? 0))
        .sort(
            (a, b) =>
                CollectionSummaryOrder.get(a.type) -
                CollectionSummaryOrder.get(b.type),
        );

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
