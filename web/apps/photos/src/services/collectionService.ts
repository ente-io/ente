import type { User } from "ente-accounts/services/user";
import { ensureLocalUser } from "ente-accounts/services/user";
import { encryptMetadataJSON, sharedCryptoWorker } from "ente-base/crypto";
import { isDevBuild } from "ente-base/env";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
import { UpdateMagicMetadataRequest } from "ente-gallery/services/file";
import { updateMagicMetadata } from "ente-gallery/services/magic-metadata";
import {
    Collection,
    CollectionMagicMetadata,
    CollectionMagicMetadataProps,
    CollectionPublicMagicMetadata,
    CollectionSubType,
    type CollectionType,
    EncryptedCollection,
    RemoveFromCollectionRequest,
} from "ente-media/collection";
import { EncryptedMagicMetadata, EnteFile } from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import {
    addToCollection,
    collection1To2,
    createCollection2,
    isDefaultHiddenCollection,
    moveToCollection,
    renameCollection2,
} from "ente-new/photos/services/collection";
import type { CollectionSummary } from "ente-new/photos/services/collection/ui";
import {
    CollectionSummaryOrder,
    CollectionsSortBy,
} from "ente-new/photos/services/collection/ui";
import {
    getCollectionWithSecrets,
    getLocalCollections,
} from "ente-new/photos/services/collections";
import {
    getLocalFiles,
    groupFilesByCollectionID,
    sortFiles,
} from "ente-new/photos/services/files";
import HTTPService from "ente-shared/network/HTTPService";
import { getData } from "ente-shared/storage/localStorage";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import { batch } from "ente-utils/array";
import {
    changeCollectionSubType,
    isQuickLinkCollection,
    isValidMoveTarget,
} from "utils/collection";

const uncategorizedCollectionName = "Uncategorized";
const defaultHiddenCollectionName = ".hidden";
const favoritesCollectionName = "Favorites";

const REQUEST_BATCH_SIZE = 1000;

export const createAlbum = (albumName: string) =>
    createCollection(albumName, "album");

// TODO(C2):
const enableC2 = () => isDevBuild && process.env.NEXT_PUBLIC_ENTE_WIP_NEWIMPL;

const createCollection = async (
    collectionName: string,
    type: CollectionType,
    magicMetadataProps?: CollectionMagicMetadataProps,
): Promise<Collection> => {
    if (enableC2()) {
        const z = createCollection2(collectionName, type, magicMetadataProps);
        z.then((x) => console.log(x));
        return z;
    }
    return createCollection1(collectionName, type, magicMetadataProps);
};

const createCollection1 = async (
    collectionName: string,
    type: CollectionType,
    magicMetadataProps?: CollectionMagicMetadataProps,
): Promise<Collection> => {
    try {
        const cryptoWorker = await sharedCryptoWorker();
        const masterKey = await ensureMasterKeyFromSession();
        const token = getToken();
        const collectionKey = await cryptoWorker.generateKey();
        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await cryptoWorker.encryptBox(collectionKey, masterKey);
        const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
            await cryptoWorker.encryptBox(
                new TextEncoder().encode(collectionName),
                collectionKey,
            );

        let encryptedMagicMetadata: EncryptedMagicMetadata;
        if (magicMetadataProps) {
            const magicMetadata = await updateMagicMetadata(magicMetadataProps);
            const { encryptedData, decryptionHeader } =
                await cryptoWorker.encryptMetadataJSON(
                    magicMetadataProps,
                    collectionKey,
                );
            encryptedMagicMetadata = {
                ...magicMetadata,
                data: encryptedData,
                header: decryptionHeader,
            };
        }
        const newCollection: EncryptedCollection = {
            id: null,
            owner: null,
            encryptedKey,
            keyDecryptionNonce,
            encryptedName,
            nameDecryptionNonce,
            type,
            attributes: {},
            sharees: null,
            updationTime: null,
            isDeleted: false,
            magicMetadata: encryptedMagicMetadata,
            pubMagicMetadata: null,
            sharedMagicMetadata: null,
        };
        const createdCollection = await postCollection(newCollection, token);
        const decryptedCreatedCollection = await getCollectionWithSecrets(
            createdCollection,
            masterKey,
        );
        return decryptedCreatedCollection;
    } catch (e) {
        log.error("create collection failed", e);
        throw e;
    }
};

const postCollection = async (
    collectionData: EncryptedCollection,
    token: string,
): Promise<EncryptedCollection> => {
    try {
        const response = await HTTPService.post(
            await apiURL("/collections"),
            collectionData,
            null,
            { "X-Auth-Token": token },
        );
        return response.data.collection;
    } catch (e) {
        log.error("post Collection failed ", e);
    }
};

export const createFavoritesCollection = () =>
    createCollection(favoritesCollectionName, "favorites");

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
    allFiles?: EnteFile[],
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
            await removeUserFiles(collectionID, userFiles, allFiles);
        }
    } catch (e) {
        log.error("remove from collection failed ", e);
        throw e;
    }
};

export const removeUserFiles = async (
    sourceCollectionID: number,
    toRemoveFiles: EnteFile[],
    allFiles?: EnteFile[],
) => {
    try {
        if (!allFiles) {
            allFiles = await getLocalFiles();
        }
        const toRemoveFilesIds = new Set(toRemoveFiles.map((f) => f.id));
        const toRemoveFilesCopiesInOtherCollections = allFiles.filter((f) => {
            return toRemoveFilesIds.has(f.id);
        });
        const groupedFiles = groupFilesByCollectionID(
            toRemoveFilesCopiesInOtherCollections,
        );

        const collections = await getLocalCollections();
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
        let uncategorizedCollection = await getUncategorizedCollection();
        if (!uncategorizedCollection) {
            uncategorizedCollection = await createUnCategorizedCollection();
        }
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
            const allFiles = await getLocalFiles();
            const collectionFiles = allFiles.filter((file) => {
                return file.collectionID === collectionID;
            });
            await removeFromCollection(collectionID, collectionFiles, allFiles);
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

export const updateCollectionMagicMetadata = async (
    collection: Collection,
    updatedMagicMetadata: CollectionMagicMetadata,
) => {
    const token = getToken();
    if (!token) {
        return;
    }

    const { encryptedData, decryptionHeader } = await encryptMetadataJSON(
        updatedMagicMetadata.data,
        collection.key,
    );

    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedMagicMetadata.version,
            count: updatedMagicMetadata.count,
            data: encryptedData,
            header: decryptionHeader,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/magic-metadata"),
        reqBody,
        null,
        { "X-Auth-Token": token },
    );
    const updatedCollection: Collection = {
        ...collection,
        magicMetadata: {
            ...updatedMagicMetadata,
            version: updatedMagicMetadata.version + 1,
        },
    };
    return updatedCollection;
};

export const updateSharedCollectionMagicMetadata = async (
    collection: Collection,
    updatedMagicMetadata: CollectionMagicMetadata,
) => {
    const token = getToken();
    if (!token) {
        return;
    }

    const { encryptedData, decryptionHeader } = await encryptMetadataJSON(
        updatedMagicMetadata.data,
        collection.key,
    );
    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedMagicMetadata.version,
            count: updatedMagicMetadata.count,
            data: encryptedData,
            header: decryptionHeader,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/sharee-magic-metadata"),
        reqBody,
        null,
        { "X-Auth-Token": token },
    );
    const updatedCollection: Collection = {
        ...collection,
        magicMetadata: {
            ...updatedMagicMetadata,
            version: updatedMagicMetadata.version + 1,
        },
    };
    return updatedCollection;
};

export const updatePublicCollectionMagicMetadata = async (
    collection: Collection,
    updatedPublicMagicMetadata: CollectionPublicMagicMetadata,
) => {
    const token = getToken();
    if (!token) {
        return;
    }

    const { encryptedData, decryptionHeader } = await encryptMetadataJSON(
        updatedPublicMagicMetadata.data,
        collection.key,
    );
    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedPublicMagicMetadata.version,
            count: updatedPublicMagicMetadata.count,
            data: encryptedData,
            header: decryptionHeader,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/public-magic-metadata"),
        reqBody,
        null,
        { "X-Auth-Token": token },
    );
    const updatedCollection: Collection = {
        ...collection,
        pubMagicMetadata: {
            ...updatedPublicMagicMetadata,
            version: updatedPublicMagicMetadata.version + 1,
        },
    };
    return updatedCollection;
};

export const renameCollection = async (
    collection: Collection,
    newCollectionName: string,
) =>
    enableC2()
        ? renameCollection2(await collection1To2(collection), newCollectionName)
        : renameCollection1(collection, newCollectionName);

const renameCollection1 = async (
    collection: Collection,
    newCollectionName: string,
) => {
    if (isQuickLinkCollection(collection)) {
        // Convert quick link collection to normal collection on rename
        await changeCollectionSubType(collection, CollectionSubType.default);
    }
    const token = getToken();
    const cryptoWorker = await sharedCryptoWorker();
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await cryptoWorker.encryptBox(
            new TextEncoder().encode(newCollectionName),
            collection.key,
        );
    const collectionRenameRequest = {
        collectionID: collection.id,
        encryptedName,
        nameDecryptionNonce,
    };
    await HTTPService.post(
        await apiURL("/collections/rename"),
        collectionRenameRequest,
        null,
        { "X-Auth-Token": token },
    );
};

/**
 * Return the user's own favorites collection, if any.
 */
export const getFavCollection = async () => {
    const collections = await getLocalCollections();
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

export async function getUncategorizedCollection(
    collections?: Collection[],
): Promise<Collection> {
    if (!collections) {
        collections = await getLocalCollections();
    }
    const uncategorizedCollection = collections.find(
        (collection) => collection.type == "uncategorized",
    );

    return uncategorizedCollection;
}

export const createUnCategorizedCollection = () =>
    createCollection(uncategorizedCollectionName, "uncategorized");

export async function getDefaultHiddenCollection(): Promise<Collection> {
    const collections = await getLocalCollections("hidden");
    const hiddenCollection = collections.find((collection) =>
        isDefaultHiddenCollection(collection),
    );

    return hiddenCollection;
}

const createDefaultHiddenCollection = () =>
    createCollection(defaultHiddenCollectionName, "album", {
        subType: CollectionSubType.defaultHidden,
        visibility: ItemVisibility.hidden,
    });

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
