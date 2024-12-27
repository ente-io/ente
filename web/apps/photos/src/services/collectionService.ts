import { encryptMetadataJSON, sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import {
    Collection,
    CollectionMagicMetadata,
    CollectionMagicMetadataProps,
    CollectionPublicMagicMetadata,
    CollectionType,
    CreatePublicAccessTokenRequest,
    EncryptedCollection,
    PublicURL,
    RemoveFromCollectionRequest,
    SUB_TYPE,
    UpdatePublicURL,
} from "@/media/collection";
import { EncryptedMagicMetadata, EnteFile } from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";
import {
    addToCollection,
    isDefaultHiddenCollection,
    moveToCollection,
} from "@/new/photos/services/collection";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import {
    CollectionSummaryOrder,
    CollectionsSortBy,
} from "@/new/photos/services/collection/ui";
import {
    getCollectionWithSecrets,
    getLocalCollections,
} from "@/new/photos/services/collections";
import {
    getLocalFiles,
    groupFilesByCollectionID,
    sortFiles,
} from "@/new/photos/services/files";
import { updateMagicMetadata } from "@/new/photos/services/magic-metadata";
import type { FamilyData } from "@/new/photos/services/user-details";
import { batch } from "@/utils/array";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { getActualKey } from "@ente/shared/user";
import type { User } from "@ente/shared/user/types";
import {
    changeCollectionSubType,
    isQuickLinkCollection,
    isValidMoveTarget,
} from "utils/collection";
import { UpdateMagicMetadataRequest } from "./fileService";
import { getPublicKey } from "./userService";

const UNCATEGORIZED_COLLECTION_NAME = "Uncategorized";
export const HIDDEN_COLLECTION_NAME = ".hidden";
const FAVORITE_COLLECTION_NAME = "Favorites";

const REQUEST_BATCH_SIZE = 1000;

export const createAlbum = (albumName: string) => {
    return createCollection(albumName, CollectionType.album);
};

const createCollection = async (
    collectionName: string,
    type: CollectionType,
    magicMetadataProps?: CollectionMagicMetadataProps,
): Promise<Collection> => {
    try {
        const cryptoWorker = await sharedCryptoWorker();
        const encryptionKey = await getActualKey();
        const token = getToken();
        const collectionKey = await cryptoWorker.generateEncryptionKey();
        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await cryptoWorker.encryptToB64(collectionKey, encryptionKey);
        const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
            await cryptoWorker.encryptUTF8(collectionName, collectionKey);
        let encryptedMagicMetadata: EncryptedMagicMetadata;
        if (magicMetadataProps) {
            const magicMetadata = await updateMagicMetadata(magicMetadataProps);
            const encryptedMagicMetadataProps =
                await cryptoWorker.encryptMetadataJSON({
                    jsonValue: magicMetadataProps,
                    keyB64: collectionKey,
                });

            encryptedMagicMetadata = {
                ...magicMetadata,
                data: encryptedMagicMetadataProps.encryptedDataB64,
                header: encryptedMagicMetadataProps.decryptionHeaderB64,
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
            encryptionKey,
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

export const createFavoritesCollection = () => {
    return createCollection(FAVORITE_COLLECTION_NAME, CollectionType.favorites);
};

export const addToFavorites = async (file: EnteFile) => {
    await addMultipleToFavorites([file]);
};

export const addMultipleToFavorites = async (files: EnteFile[]) => {
    try {
        let favCollection = await getFavCollection();
        if (!favCollection) {
            favCollection = await createFavoritesCollection();
        }
        await addToCollection(favCollection, files);
    } catch (e) {
        log.error("failed to add to favorite", e);
    }
};

export const removeFromFavorites = async (file: EnteFile) => {
    try {
        const favCollection = await getFavCollection();
        if (!favCollection) {
            throw Error("favorite collection missing");
        }
        await removeFromCollection(favCollection.id, [file]);
    } catch (e) {
        log.error("remove from favorite failed", e);
    }
};

export const removeFromCollection = async (
    collectionID: number,
    toRemoveFiles: EnteFile[],
    allFiles?: EnteFile[],
) => {
    try {
        const user: User = getData(LS_KEYS.USER);
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
        const user: User = getData(LS_KEYS.USER);

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

export const leaveSharedAlbum = async (collectionID: number) => {
    try {
        const token = getToken();

        await HTTPService.post(
            await apiURL(`/collections/leave/${collectionID}`),
            null,
            null,
            { "X-Auth-Token": token },
        );
    } catch (e) {
        log.error("leave shared album failed ", e);
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

    const { encryptedDataB64, decryptionHeaderB64 } = await encryptMetadataJSON(
        { jsonValue: updatedMagicMetadata.data, keyB64: collection.key },
    );

    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedMagicMetadata.version,
            count: updatedMagicMetadata.count,
            data: encryptedDataB64,
            header: decryptionHeaderB64,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/magic-metadata"),
        reqBody,
        null,
        {
            "X-Auth-Token": token,
        },
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

    const { encryptedDataB64, decryptionHeaderB64 } = await encryptMetadataJSON(
        { jsonValue: updatedMagicMetadata.data, keyB64: collection.key },
    );
    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedMagicMetadata.version,
            count: updatedMagicMetadata.count,
            data: encryptedDataB64,
            header: decryptionHeaderB64,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/sharee-magic-metadata"),
        reqBody,
        null,
        {
            "X-Auth-Token": token,
        },
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

    const { encryptedDataB64, decryptionHeaderB64 } = await encryptMetadataJSON(
        { jsonValue: updatedPublicMagicMetadata.data, keyB64: collection.key },
    );
    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: updatedPublicMagicMetadata.version,
            count: updatedPublicMagicMetadata.count,
            data: encryptedDataB64,
            header: decryptionHeaderB64,
        },
    };

    await HTTPService.put(
        await apiURL("/collections/public-magic-metadata"),
        reqBody,
        null,
        {
            "X-Auth-Token": token,
        },
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
) => {
    if (isQuickLinkCollection(collection)) {
        // Convert quick link collection to normal collection on rename
        await changeCollectionSubType(collection, SUB_TYPE.DEFAULT);
    }
    const token = getToken();
    const cryptoWorker = await sharedCryptoWorker();
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await cryptoWorker.encryptUTF8(newCollectionName, collection.key);
    const collectionRenameRequest = {
        collectionID: collection.id,
        encryptedName,
        nameDecryptionNonce,
    };
    await HTTPService.post(
        await apiURL("/collections/rename"),
        collectionRenameRequest,
        null,
        {
            "X-Auth-Token": token,
        },
    );
};

export const shareCollection = async (
    collection: Collection,
    withUserEmail: string,
    role: string,
) => {
    try {
        const cryptoWorker = await sharedCryptoWorker();
        const token = getToken();
        const publicKey: string = await getPublicKey(withUserEmail);
        const encryptedKey = await cryptoWorker.boxSeal(
            collection.key,
            publicKey,
        );
        const shareCollectionRequest = {
            collectionID: collection.id,
            email: withUserEmail,
            role: role,
            encryptedKey,
        };
        await HTTPService.post(
            await apiURL("/collections/share"),
            shareCollectionRequest,
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("share collection failed ", e);
        throw e;
    }
};

export const unshareCollection = async (
    collection: Collection,
    withUserEmail: string,
) => {
    try {
        const token = getToken();
        const shareCollectionRequest = {
            collectionID: collection.id,
            email: withUserEmail,
        };
        await HTTPService.post(
            await apiURL("/collections/unshare"),
            shareCollectionRequest,
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("unshare collection failed ", e);
    }
};

export const createShareableURL = async (collection: Collection) => {
    try {
        const token = getToken();
        if (!token) {
            return null;
        }
        const createPublicAccessTokenRequest: CreatePublicAccessTokenRequest = {
            collectionID: collection.id,
        };
        const resp = await HTTPService.post(
            await apiURL("/collections/share-url"),
            createPublicAccessTokenRequest,
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data.result as PublicURL;
    } catch (e) {
        log.error("createShareableURL failed ", e);
        throw e;
    }
};

export const deleteShareableURL = async (collection: Collection) => {
    try {
        const token = getToken();
        if (!token) {
            return null;
        }
        await HTTPService.delete(
            await apiURL(`/collections/share-url/${collection.id}`),
            null,
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("deleteShareableURL failed ", e);
        throw e;
    }
};

export const updateShareableURL = async (
    request: UpdatePublicURL,
): Promise<PublicURL> => {
    try {
        const token = getToken();
        if (!token) {
            return null;
        }
        const res = await HTTPService.put(
            await apiURL("/collections/share-url"),
            request,
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return res.data.result as PublicURL;
    } catch (e) {
        log.error("updateShareableURL failed ", e);
        throw e;
    }
};

export const getFavCollection = async () => {
    const collections = await getLocalCollections();
    for (const collection of collections) {
        if (collection.type === CollectionType.favorites) {
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
        // TODO:
        // eslint-disable-next-line no-constant-binary-expression
        .sort((a, b) => b.order ?? 0 - a.order ?? 0)
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
        (collection) => collection.type === CollectionType.uncategorized,
    );

    return uncategorizedCollection;
}

export function createUnCategorizedCollection() {
    return createCollection(
        UNCATEGORIZED_COLLECTION_NAME,
        CollectionType.uncategorized,
    );
}

export async function getDefaultHiddenCollection(): Promise<Collection> {
    const collections = await getLocalCollections("hidden");
    const hiddenCollection = collections.find((collection) =>
        isDefaultHiddenCollection(collection),
    );

    return hiddenCollection;
}

export function createHiddenCollection() {
    return createCollection(HIDDEN_COLLECTION_NAME, CollectionType.album, {
        subType: SUB_TYPE.DEFAULT_HIDDEN,
        visibility: ItemVisibility.hidden,
    });
}

export async function moveToHiddenCollection(files: EnteFile[]) {
    try {
        let hiddenCollection = await getDefaultHiddenCollection();
        if (!hiddenCollection) {
            hiddenCollection = await createHiddenCollection();
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

export const constructUserIDToEmailMap = (
    user: User,
    collections: Collection[],
): Map<number, string> => {
    try {
        const userIDToEmailMap = new Map<number, string>();
        collections.forEach((item) => {
            const { owner, sharees } = item;
            if (user.id !== owner.id && owner.email) {
                userIDToEmailMap.set(owner.id, owner.email);
            }
            if (sharees) {
                sharees.forEach((item) => {
                    if (item.id !== user.id)
                        userIDToEmailMap.set(item.id, item.email);
                });
            }
        });
        return userIDToEmailMap;
    } catch (e) {
        log.error("Error Mapping UserId to email:", e);
        return new Map<number, string>();
    }
};

export const constructEmailList = (
    user: User,
    collections: Collection[],
    familyData: FamilyData,
): string[] => {
    const emails = collections
        .map((item) => {
            const { owner, sharees } = item;
            if (owner.email && item.owner.id !== user.id) {
                return [item.owner.email];
            } else {
                if (!sharees?.length) {
                    return [];
                }
                const shareeEmails = item.sharees
                    .filter((sharee) => sharee.email !== user.email)
                    .map((sharee) => sharee.email);
                return shareeEmails;
            }
        })
        .flat();

    // adding family members
    if (familyData) {
        const family = familyData.members.map((member) => member.email);
        emails.push(...family);
    }
    return Array.from(new Set(emails));
};
