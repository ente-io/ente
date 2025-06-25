import type { User } from "ente-accounts/services/user";
import { ensureLocalUser } from "ente-accounts/services/user";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { groupFilesByCollectionID, sortFiles } from "ente-gallery/utils/files";
import { Collection } from "ente-media/collection";
import { EnteFile } from "ente-media/file";
import {
    addToCollection,
    createDefaultHiddenCollection,
    createFavoritesCollection,
    createUncategorizedCollection,
    isDefaultHiddenCollection,
    moveToCollection,
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

export const addToFavorites = async (
    file: EnteFile,
    disableOldWorkaround?: boolean,
) => {
    await addMultipleToFavorites([file], disableOldWorkaround);
};

export const addMultipleToFavorites = async (
    files: EnteFile[],
    disableOldWorkaround?: boolean,
) => {
    try {
        let favCollection = await getFavCollection();
        if (!favCollection) {
            favCollection = await createFavoritesCollection();
        }
        await addToCollection(favCollection, files);
    } catch (e) {
        log.error("failed to add to favorite", e);
        // Old code swallowed the error here. This isn't good, but to
        // avoid changing existing behaviour only new code will set the
        // disableOldWorkaround flag to instead rethrow it.
        //
        // TODO: Migrate old code, remove this flag, always throw.
        if (disableOldWorkaround) throw e;
    }
};

export const removeFromFavorites = async (
    file: EnteFile,
    disableOldWorkaround?: boolean,
) => {
    try {
        const favCollection = await getFavCollection();
        if (!favCollection) {
            throw Error("favorite collection missing");
        }
        await removeFromCollection(favCollection.id, [file]);
    } catch (e) {
        log.error("remove from favorite failed", e);
        // TODO: See disableOldWorkaround in addMultipleToFavorites.
        if (disableOldWorkaround) throw e;
    }
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
            await moveToCollection(
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

        await moveToCollection(
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

/**
 * Return the user's own favorites collection, if any.
 */
export const getFavCollection = async () => {
    const collections = await savedCollections();
    const userID = ensureLocalUser().id;
    for (const collection of collections) {
        // See: [Note: User and shared favorites]
        if (collection.type == "favorites" && collection.owner.id == userID) {
            return collection;
        }
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

export async function getDefaultHiddenCollection(): Promise<Collection> {
    const collections = await savedCollections();
    const hiddenCollection = collections.find((collection) =>
        isDefaultHiddenCollection(collection),
    );

    return hiddenCollection;
}

export async function moveToHiddenCollection(files: EnteFile[]) {
    try {
        let hiddenCollection = await getDefaultHiddenCollection();
        if (!hiddenCollection) {
            hiddenCollection = await createDefaultHiddenCollection();
        }
        const groupedFiles = groupFilesByCollectionID(files);
        for (const [collectionID, files] of groupedFiles.entries()) {
            if (collectionID === hiddenCollection.id) {
                continue;
            }
            await moveToCollection(collectionID, hiddenCollection, files);
        }
    } catch (e) {
        log.error("move to hidden collection failed ", e);
        throw e;
    }
}

export async function unhideToCollection(
    collection: Collection,
    files: EnteFile[],
) {
    try {
        const groupedFiles = groupFilesByCollectionID(files);
        for (const [collectionID, files] of groupedFiles.entries()) {
            if (collectionID === collection.id) {
                continue;
            }
            await moveToCollection(collectionID, collection, files);
        }
    } catch (e) {
        log.error("unhide to collection failed ", e);
        throw e;
    }
}
