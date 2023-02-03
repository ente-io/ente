import { getEndpoint } from 'utils/common/apiUtil';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';

import { getActualKey, getToken } from 'utils/common/key';
import { getPublicKey } from './userService';
import HTTPService from './HTTPService';
import { EnteFile } from 'types/file';
import { logError } from 'utils/sentry';
import { CustomError } from 'utils/error';
import {
    isSharedFile,
    sortFiles,
    groupFilesBasedOnCollectionID,
} from 'utils/file';
import {
    Collection,
    CollectionLatestFiles,
    AddToCollectionRequest,
    MoveToCollectionRequest,
    EncryptedFileKey,
    CreatePublicAccessTokenRequest,
    PublicURL,
    UpdatePublicURL,
    CollectionSummaries,
    CollectionSummary,
    CollectionFilesCount,
    EncryptedCollection,
    CollectionMagicMetadata,
    CollectionMagicMetadataProps,
} from 'types/collection';
import {
    COLLECTION_SORT_BY,
    CollectionType,
    ARCHIVE_SECTION,
    TRASH_SECTION,
    COLLECTION_SORT_ORDER,
    ALL_SECTION,
    CollectionSummaryType,
    UNCATEGORIZED_COLLECTION_NAME,
    FAVORITE_COLLECTION_NAME,
    DUMMY_UNCATEGORIZED_SECTION,
} from 'constants/collection';
import {
    NEW_COLLECTION_MAGIC_METADATA,
    SUB_TYPE,
    UpdateMagicMetadataRequest,
} from 'types/magicMetadata';
import constants from 'utils/strings/constants';
import { IsArchived, updateMagicMetadataProps } from 'utils/magicMetadata';
import { User } from 'types/user';
import {
    getNonHiddenCollections,
    isQuickLinkCollection,
    isOutgoingShare,
    isIncomingShare,
    isSharedOnlyViaLink,
} from 'utils/collection';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { getLocalFiles } from './fileService';

const ENDPOINT = getEndpoint();
const COLLECTION_TABLE = 'collections';
const COLLECTION_UPDATION_TIME = 'collection-updation-time';

export const getCollectionLastSyncTime = async (collection: Collection) =>
    (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;

export const setCollectionLastSyncTime = async (
    collection: Collection,
    time: number
) => await localForage.setItem<number>(`${collection.id}-time`, time);

export const removeCollectionLastSyncTime = async (collection: Collection) =>
    await localForage.removeItem(`${collection.id}-time`);

const getCollectionWithSecrets = async (
    collection: EncryptedCollection,
    masterKey: string
): Promise<Collection> => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const userID = getData(LS_KEYS.USER).id;
    let collectionKey: string;
    if (collection.owner.id === userID) {
        collectionKey = await cryptoWorker.decryptB64(
            collection.encryptedKey,
            collection.keyDecryptionNonce,
            masterKey
        );
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await cryptoWorker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey
        );
        collectionKey = await cryptoWorker.boxSealOpen(
            collection.encryptedKey,
            keyAttributes.publicKey,
            secretKey
        );
    }
    const collectionName =
        collection.name ||
        (await cryptoWorker.decryptToUTF8(
            collection.encryptedName,
            collection.nameDecryptionNonce,
            collectionKey
        ));

    let collectionMagicMetadata: CollectionMagicMetadata;
    if (collection.magicMetadata?.data) {
        collectionMagicMetadata = {
            ...collection.magicMetadata,
            data: await cryptoWorker.decryptMetadata(
                collection.magicMetadata.data,
                collection.magicMetadata.header,
                collectionKey
            ),
        };
    }
    return {
        ...collection,
        name: collectionName,
        key: collectionKey,
        magicMetadata: collectionMagicMetadata,
    };
};

const getCollections = async (
    token: string,
    sinceTime: number,
    key: string
): Promise<Collection[]> => {
    try {
        const resp = await HTTPService.get(
            `${ENDPOINT}/collections`,
            {
                sinceTime,
            },
            { 'X-Auth-Token': token }
        );
        const decryptedCollections: Collection[] = await Promise.all(
            resp.data.collections.map(
                async (collection: EncryptedCollection) => {
                    if (collection.isDeleted) {
                        return collection;
                    }
                    try {
                        return await getCollectionWithSecrets(collection, key);
                    } catch (e) {
                        logError(e, `decryption failed for collection`, {
                            collectionID: collection.id,
                        });
                        return collection;
                    }
                }
            )
        );
        // only allow deleted or collection with key, filtering out collection whose decryption failed
        const collections = decryptedCollections.filter(
            (collection) => collection.isDeleted || collection.key
        );
        return collections;
    } catch (e) {
        logError(e, 'getCollections failed');
        throw e;
    }
};

export const getLocalCollections = async (): Promise<Collection[]> => {
    const collections: Collection[] =
        (await localForage.getItem(COLLECTION_TABLE)) ?? [];
    return getNonHiddenCollections(collections);
};

export const getCollectionUpdationTime = async (): Promise<number> =>
    (await localForage.getItem<number>(COLLECTION_UPDATION_TIME)) ?? 0;

export const syncCollections = async () => {
    const localCollections = await getLocalCollections();
    const lastCollectionUpdationTime = await getCollectionUpdationTime();
    const token = getToken();
    const key = await getActualKey();
    const updatedCollections =
        (await getCollections(token, lastCollectionUpdationTime, key)) ?? [];
    if (updatedCollections.length === 0) {
        return localCollections;
    }
    const allCollectionsInstances = [
        ...localCollections,
        ...updatedCollections,
    ];
    const latestCollectionsInstances = new Map<number, Collection>();
    allCollectionsInstances.forEach((collection) => {
        if (
            !latestCollectionsInstances.has(collection.id) ||
            latestCollectionsInstances.get(collection.id).updationTime <
                collection.updationTime
        ) {
            latestCollectionsInstances.set(collection.id, collection);
        }
    });

    const collections: Collection[] = [];
    let updationTime = await localForage.getItem<number>(
        COLLECTION_UPDATION_TIME
    );
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    for (const [_, collection] of latestCollectionsInstances) {
        if (!collection.isDeleted) {
            collections.push(collection);
            updationTime = Math.max(updationTime, collection.updationTime);
        } else {
            removeCollectionLastSyncTime(collection);
        }
    }

    await localForage.setItem(COLLECTION_TABLE, collections);
    await localForage.setItem(COLLECTION_UPDATION_TIME, updationTime);
    return getNonHiddenCollections(collections);
};

export const getCollection = async (
    collectionID: number
): Promise<Collection> => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            `${ENDPOINT}/collections/${collectionID}`,
            null,
            { 'X-Auth-Token': token }
        );
        const key = await getActualKey();
        const collectionWithSecrets = await getCollectionWithSecrets(
            resp.data?.collection,
            key
        );
        return collectionWithSecrets;
    } catch (e) {
        logError(e, 'failed to get collection');
        throw e;
    }
};

export const getCollectionLatestFiles = (
    files: EnteFile[],
    archivedCollections: Set<number>
): CollectionLatestFiles => {
    const latestFiles = new Map<number, EnteFile>();

    files.forEach((file) => {
        if (!latestFiles.has(file.collectionID) && !file.isTrashed) {
            latestFiles.set(file.collectionID, file);
        }
        if (!latestFiles.has(ARCHIVE_SECTION) && IsArchived(file)) {
            latestFiles.set(ARCHIVE_SECTION, file);
        }
        if (!latestFiles.has(TRASH_SECTION) && file.isTrashed) {
            latestFiles.set(TRASH_SECTION, file);
        }
        if (
            !latestFiles.has(ALL_SECTION) &&
            !IsArchived(file) &&
            !file.isTrashed &&
            !archivedCollections.has(file.collectionID)
        ) {
            latestFiles.set(ALL_SECTION, file);
        }
    });
    return latestFiles;
};

export const getFavItemIds = async (
    files: EnteFile[]
): Promise<Set<number>> => {
    const favCollection = await getFavCollection();
    if (!favCollection) return new Set();

    return new Set(
        files
            .filter((file) => file.collectionID === favCollection.id)
            .map((file): number => file.id)
    );
};

export const createAlbum = async (
    albumName: string,
    existingCollection?: Collection[]
) => createCollection(albumName, CollectionType.album, existingCollection);

export const createCollection = async (
    collectionName: string,
    type: CollectionType,
    existingCollections?: Collection[]
): Promise<Collection> => {
    try {
        if (!existingCollections) {
            existingCollections = await syncCollections();
        }
        for (const collection of existingCollections) {
            if (collection.name === collectionName) {
                return collection;
            }
        }
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const encryptionKey = await getActualKey();
        const token = getToken();
        const collectionKey = await cryptoWorker.generateEncryptionKey();
        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
            await cryptoWorker.encryptToB64(collectionKey, encryptionKey);
        const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
            await cryptoWorker.encryptUTF8(collectionName, collectionKey);
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
            magicMetadata: null,
        };
        const createdCollection = await postCollection(newCollection, token);
        const decryptedCreatedCollection = await getCollectionWithSecrets(
            createdCollection,
            encryptionKey
        );
        return decryptedCreatedCollection;
    } catch (e) {
        logError(e, 'create collection failed');
        throw e;
    }
};

const postCollection = async (
    collectionData: EncryptedCollection,
    token: string
): Promise<EncryptedCollection> => {
    try {
        const response = await HTTPService.post(
            `${ENDPOINT}/collections`,
            collectionData,
            null,
            { 'X-Auth-Token': token }
        );
        return response.data.collection;
    } catch (e) {
        logError(e, 'post Collection failed ');
    }
};

export const addToFavorites = async (file: EnteFile) => {
    try {
        let favCollection = await getFavCollection();
        if (!favCollection) {
            favCollection = await createCollection(
                FAVORITE_COLLECTION_NAME,
                CollectionType.favorites
            );
            const localCollections = await getLocalCollections();
            await localForage.setItem(COLLECTION_TABLE, [
                ...localCollections,
                favCollection,
            ]);
        }
        await addToCollection(favCollection, [file]);
    } catch (e) {
        logError(e, 'failed to add to favorite');
    }
};

export const removeFromFavorites = async (file: EnteFile) => {
    try {
        const favCollection = await getFavCollection();
        if (!favCollection) {
            throw Error(CustomError.FAV_COLLECTION_MISSING);
        }
        await removeFromCollection(favCollection.id, [file]);
    } catch (e) {
        logError(e, 'remove from favorite failed');
    }
};

export const addToCollection = async (
    collection: Collection,
    files: EnteFile[]
) => {
    try {
        const token = getToken();
        const fileKeysEncryptedWithNewCollection =
            await encryptWithNewCollectionKey(collection, files);

        const requestBody: AddToCollectionRequest = {
            collectionID: collection.id,
            files: fileKeysEncryptedWithNewCollection,
        };
        await HTTPService.post(
            `${ENDPOINT}/collections/add-files`,
            requestBody,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'Add to collection Failed ');
        throw e;
    }
};

export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[]
) => {
    try {
        const token = getToken();
        const fileKeysEncryptedWithNewCollection =
            await encryptWithNewCollectionKey(collection, files);

        const requestBody: AddToCollectionRequest = {
            collectionID: collection.id,
            files: fileKeysEncryptedWithNewCollection,
        };
        await HTTPService.post(
            `${ENDPOINT}/collections/restore-files`,
            requestBody,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'restore to collection Failed ');
        throw e;
    }
};
export const moveToCollection = async (
    toCollection: Collection,
    fromCollectionID: number,
    files: EnteFile[]
) => {
    try {
        const token = getToken();
        const fileKeysEncryptedWithNewCollection =
            await encryptWithNewCollectionKey(toCollection, files);

        const requestBody: MoveToCollectionRequest = {
            fromCollectionID: fromCollectionID,
            toCollectionID: toCollection.id,
            files: fileKeysEncryptedWithNewCollection,
        };
        await HTTPService.post(
            `${ENDPOINT}/collections/move-files`,
            requestBody,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'move to collection Failed ');
        throw e;
    }
};

const encryptWithNewCollectionKey = async (
    newCollection: Collection,
    files: EnteFile[]
): Promise<EncryptedFileKey[]> => {
    const fileKeysEncryptedWithNewCollection: EncryptedFileKey[] = [];
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    for (const file of files) {
        const newEncryptedKey = await cryptoWorker.encryptToB64(
            file.key,
            newCollection.key
        );
        const encryptedKey = newEncryptedKey.encryptedData;
        const keyDecryptionNonce = newEncryptedKey.nonce;

        fileKeysEncryptedWithNewCollection.push({
            id: file.id,
            encryptedKey,
            keyDecryptionNonce,
        });
    }
    return fileKeysEncryptedWithNewCollection;
};
export const removeFromCollection = async (
    collectionID: number,
    toRemoveFiles: EnteFile[],
    allFiles?: EnteFile[]
) => {
    try {
        if (!allFiles) {
            allFiles = await getLocalFiles();
        }

        const toRemoveFilesIds = new Set(toRemoveFiles.map((f) => f.id));
        const toRemoveFilesCopiesInOtherCollections = allFiles.filter((f) => {
            if (f.collectionID === collectionID) {
                return false;
            }
            return toRemoveFilesIds.has(f.id);
        });
        const groupiedFiles = groupFilesBasedOnCollectionID(
            toRemoveFilesCopiesInOtherCollections
        );

        const collections = await getLocalCollections();
        const collectionsMap = new Map(collections.map((c) => [c.id, c]));

        for (const [toMoveCollectionID, files] of groupiedFiles.entries()) {
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
                collectionsMap.get(toMoveCollectionID),
                collectionID,
                toMoveFiles
            );
        }
        const leftFiles = toRemoveFiles.filter((f) =>
            toRemoveFilesIds.has(f.id)
        );

        if (leftFiles.length === 0) {
            return;
        }
        let uncategorizedCollection = await getUncategorizedCollection();
        if (!uncategorizedCollection) {
            uncategorizedCollection = await createUnCategorizedCollection();
        }
        await moveToCollection(
            uncategorizedCollection,
            collectionID,
            leftFiles
        );
    } catch (e) {
        logError(e, 'remove from collection failed ');
        throw e;
    }
};

export const deleteCollection = async (
    collectionID: number,
    keepFiles: boolean
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
            `${ENDPOINT}/collections/v3/${collectionID}`,
            null,
            { collectionID, keepFiles },
            { 'X-Auth-Token': token }
        );
    } catch (e) {
        logError(e, 'delete collection failed ');
        throw e;
    }
};

export const leaveSharedAlbum = async (collectionID: number) => {
    try {
        const token = getToken();

        await HTTPService.post(
            `${ENDPOINT}/collections/leave/${collectionID}`,
            null,
            null,
            { 'X-Auth-Token': token }
        );
    } catch (e) {
        logError(e, constants.LEAVE_SHARED_ALBUM_FAILED);
        throw e;
    }
};

export const updateCollectionMagicMetadata = async (collection: Collection) => {
    const token = getToken();
    if (!token) {
        return;
    }

    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    const { file: encryptedMagicMetadata } = await cryptoWorker.encryptMetadata(
        collection.magicMetadata.data,
        collection.key
    );

    const reqBody: UpdateMagicMetadataRequest = {
        id: collection.id,
        magicMetadata: {
            version: collection.magicMetadata.version,
            count: collection.magicMetadata.count,
            data: encryptedMagicMetadata.encryptedData,
            header: encryptedMagicMetadata.decryptionHeader,
        },
    };

    await HTTPService.put(
        `${ENDPOINT}/collections/magic-metadata`,
        reqBody,
        null,
        {
            'X-Auth-Token': token,
        }
    );
    const updatedCollection: Collection = {
        ...collection,
        magicMetadata: {
            ...collection.magicMetadata,
            version: collection.magicMetadata.version + 1,
        },
    };
    return updatedCollection;
};

export const renameCollection = async (
    collection: Collection,
    newCollectionName: string
) => {
    if (isQuickLinkCollection(collection)) {
        // Convert quick link collction to normal collection on rename
        await updateCollectionSubType(collection, SUB_TYPE.DEFAULT);
    }
    const token = getToken();
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await cryptoWorker.encryptUTF8(newCollectionName, collection.key);
    const collectionRenameRequest = {
        collectionID: collection.id,
        encryptedName,
        nameDecryptionNonce,
    };
    await HTTPService.post(
        `${ENDPOINT}/collections/rename`,
        collectionRenameRequest,
        null,
        {
            'X-Auth-Token': token,
        }
    );
};

const updateCollectionSubType = async (
    collection: Collection,
    subType: SUB_TYPE
) => {
    const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
        subType: subType,
    };
    const updatedCollection = {
        ...collection,
        magicMetadata: await updateMagicMetadataProps(
            collection.magicMetadata ?? NEW_COLLECTION_MAGIC_METADATA,
            collection.key,
            updatedMagicMetadataProps
        ),
    } as Collection;
    await updateCollectionMagicMetadata(updatedCollection);
};

export const shareCollection = async (
    collection: Collection,
    withUserEmail: string
) => {
    try {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const token = getToken();
        const publicKey: string = await getPublicKey(withUserEmail);
        const encryptedKey = await cryptoWorker.boxSeal(
            collection.key,
            publicKey
        );
        const shareCollectionRequest = {
            collectionID: collection.id,
            email: withUserEmail,
            encryptedKey,
        };
        await HTTPService.post(
            `${ENDPOINT}/collections/share`,
            shareCollectionRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'share collection failed ');
        throw e;
    }
};

export const unshareCollection = async (
    collection: Collection,
    withUserEmail: string
) => {
    try {
        const token = getToken();
        const shareCollectionRequest = {
            collectionID: collection.id,
            email: withUserEmail,
        };
        await HTTPService.post(
            `${ENDPOINT}/collections/unshare`,
            shareCollectionRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'unshare collection failed ');
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
            `${ENDPOINT}/collections/share-url`,
            createPublicAccessTokenRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data.result as PublicURL;
    } catch (e) {
        logError(e, 'createShareableURL failed ');
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
            `${ENDPOINT}/collections/share-url/${collection.id}`,
            null,
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'deleteShareableURL failed ');
        throw e;
    }
};

export const updateShareableURL = async (
    request: UpdatePublicURL
): Promise<PublicURL> => {
    try {
        const token = getToken();
        if (!token) {
            return null;
        }
        const res = await HTTPService.put(
            `${ENDPOINT}/collections/share-url`,
            request,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return res.data.result as PublicURL;
    } catch (e) {
        logError(e, 'updateShareableURL failed ');
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
    return null;
};

export const getNonEmptyCollections = (
    collections: Collection[],
    files: EnteFile[]
) => {
    const nonEmptyCollectionsIds = new Set<number>();
    for (const file of files) {
        if (!file.isTrashed) {
            nonEmptyCollectionsIds.add(file.collectionID);
        }
    }
    return collections.filter((collection) =>
        nonEmptyCollectionsIds.has(collection.id)
    );
};

export function sortCollectionSummaries(
    collectionSummaries: CollectionSummary[],
    sortBy: COLLECTION_SORT_BY
) {
    return collectionSummaries
        .sort((a, b) => {
            switch (sortBy) {
                case COLLECTION_SORT_BY.CREATION_TIME_ASCENDING:
                    return (
                        -1 *
                        compareCollectionsLatestFile(b.latestFile, a.latestFile)
                    );
                case COLLECTION_SORT_BY.UPDATION_TIME_DESCENDING:
                    return b.updationTime - a.updationTime;
                case COLLECTION_SORT_BY.NAME:
                    return a.name.localeCompare(b.name);
            }
        })
        .sort(
            (a, b) =>
                COLLECTION_SORT_ORDER.get(a.type) -
                COLLECTION_SORT_ORDER.get(b.type)
        );
}

function compareCollectionsLatestFile(first: EnteFile, second: EnteFile) {
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

export async function getCollectionSummaries(
    user: User,
    collections: Collection[],
    files: EnteFile[],
    archivedCollections: Set<number>
): Promise<CollectionSummaries> {
    const collectionSummaries: CollectionSummaries = new Map();
    const collectionLatestFiles = getCollectionLatestFiles(
        files,
        archivedCollections
    );
    const collectionFilesCount = getCollectionsFileCount(
        files,
        archivedCollections
    );

    for (const collection of collections) {
        if (
            collectionFilesCount.get(collection.id) ||
            collection.type === CollectionType.uncategorized
        ) {
            collectionSummaries.set(collection.id, {
                id: collection.id,
                name: collection.name,
                latestFile: collectionLatestFiles.get(collection.id),
                fileCount: collectionFilesCount.get(collection.id) ?? 0,
                updationTime: collection.updationTime,
                type: isIncomingShare(collection, user)
                    ? CollectionSummaryType.incomingShare
                    : isOutgoingShare(collection)
                    ? CollectionSummaryType.outgoingShare
                    : isSharedOnlyViaLink(collection)
                    ? CollectionSummaryType.sharedOnlyViaLink
                    : IsArchived(collection)
                    ? CollectionSummaryType.archived
                    : CollectionSummaryType[collection.type],
            });
        }
    }
    const uncategorizedCollection = await getUncategorizedCollection(
        collections
    );

    if (!uncategorizedCollection) {
        collectionSummaries.set(
            DUMMY_UNCATEGORIZED_SECTION,
            getDummyUncategorizedCollectionSummaries()
        );
    }
    collectionSummaries.set(
        ALL_SECTION,
        getAllCollectionSummaries(collectionFilesCount, collectionLatestFiles)
    );
    collectionSummaries.set(
        ARCHIVE_SECTION,
        getArchivedCollectionSummaries(
            collectionFilesCount,
            collectionLatestFiles
        )
    );
    collectionSummaries.set(
        TRASH_SECTION,
        getTrashedCollectionSummaries(
            collectionFilesCount,
            collectionLatestFiles
        )
    );

    return collectionSummaries;
}

function getCollectionsFileCount(
    files: EnteFile[],
    archivedCollections: Set<number>
): CollectionFilesCount {
    const collectionIDToFileMap = groupFilesBasedOnCollectionID(files);
    const collectionFilesCount = new Map<number, number>();
    for (const [id, files] of collectionIDToFileMap) {
        collectionFilesCount.set(id, files.length);
    }
    const user: User = getData(LS_KEYS.USER);
    const uniqueTrashedFileIDs = new Set<number>();
    const uniqueArchivedFileIDs = new Set<number>();
    const uniqueAllSectionFileIDs = new Set<number>();
    for (const file of files) {
        if (isSharedFile(user, file)) {
            continue;
        }
        if (file.isTrashed) {
            uniqueTrashedFileIDs.add(file.id);
        } else if (IsArchived(file)) {
            uniqueArchivedFileIDs.add(file.id);
        } else if (!archivedCollections.has(file.collectionID)) {
            uniqueAllSectionFileIDs.add(file.id);
        }
    }
    collectionFilesCount.set(TRASH_SECTION, uniqueTrashedFileIDs.size);
    collectionFilesCount.set(ARCHIVE_SECTION, uniqueArchivedFileIDs.size);
    collectionFilesCount.set(ALL_SECTION, uniqueAllSectionFileIDs.size);
    return collectionFilesCount;
}

function getAllCollectionSummaries(
    collectionFilesCount: CollectionFilesCount,
    collectionsLatestFile: CollectionLatestFiles
): CollectionSummary {
    return {
        id: ALL_SECTION,
        name: constants.ALL_SECTION_NAME,
        type: CollectionSummaryType.all,
        latestFile: collectionsLatestFile.get(ALL_SECTION),
        fileCount: collectionFilesCount.get(ALL_SECTION) || 0,
        updationTime: collectionsLatestFile.get(ALL_SECTION)?.updationTime,
    };
}

function getDummyUncategorizedCollectionSummaries(): CollectionSummary {
    return {
        id: ALL_SECTION,
        name: UNCATEGORIZED_COLLECTION_NAME,
        type: CollectionSummaryType.uncategorized,
        latestFile: null,
        fileCount: 0,
        updationTime: 0,
    };
}

function getArchivedCollectionSummaries(
    collectionFilesCount: CollectionFilesCount,
    collectionsLatestFile: CollectionLatestFiles
): CollectionSummary {
    return {
        id: ARCHIVE_SECTION,
        name: constants.ARCHIVE_SECTION_NAME,
        type: CollectionSummaryType.archive,
        latestFile: collectionsLatestFile.get(ARCHIVE_SECTION),
        fileCount: collectionFilesCount.get(ARCHIVE_SECTION) ?? 0,
        updationTime: collectionsLatestFile.get(ARCHIVE_SECTION)?.updationTime,
    };
}

function getTrashedCollectionSummaries(
    collectionFilesCount: CollectionFilesCount,
    collectionsLatestFile: CollectionLatestFiles
): CollectionSummary {
    return {
        id: TRASH_SECTION,
        name: constants.TRASH,
        type: CollectionSummaryType.trash,
        latestFile: collectionsLatestFile.get(TRASH_SECTION),
        fileCount: collectionFilesCount.get(TRASH_SECTION) ?? 0,
        updationTime: collectionsLatestFile.get(TRASH_SECTION)?.updationTime,
    };
}

export async function getUncategorizedCollection(
    collections?: Collection[]
): Promise<Collection> {
    if (!collections) {
        collections = await getLocalCollections();
    }
    const uncategorizedCollection = collections.find(
        (collection) => collection.type === CollectionType.uncategorized
    );

    return uncategorizedCollection;
}

export async function createUnCategorizedCollection() {
    return createCollection(
        UNCATEGORIZED_COLLECTION_NAME,
        CollectionType.uncategorized
    );
}
