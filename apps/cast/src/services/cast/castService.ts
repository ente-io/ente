import { getEndpoint } from '@ente/shared/network/api';
import localForage from '@ente/shared/storage/localForage';
import { Collection, CollectionPublicMagicMetadata } from 'types/collection';
import HTTPService from '@ente/shared/network/HTTPService';
import { logError } from '@ente/shared/sentry';
import { decryptFile, mergeMetadata, sortFiles } from 'utils/file';
import { EncryptedEnteFile, EnteFile } from 'types/file';

import { CustomError, parseSharingErrorCodes } from '@ente/shared/error';
import ComlinkCryptoWorker from '@ente/shared/crypto';

export interface SavedCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}
const ENDPOINT = getEndpoint();
const COLLECTION_FILES_TABLE = 'collection-files';
const COLLECTIONS_TABLE = 'collections';

export const getPublicCollectionUID = (token: string) => `${token}`;

const getLastSyncKey = (collectionUID: string) => `${collectionUID}-time`;

export const getLocalFiles = async (
    collectionUID: string
): Promise<EnteFile[]> => {
    const localSavedcollectionFiles =
        (await localForage.getItem<SavedCollectionFiles[]>(
            COLLECTION_FILES_TABLE
        )) || [];
    const matchedCollection = localSavedcollectionFiles.find(
        (item) => item.collectionUID === collectionUID
    );
    return matchedCollection?.files || [];
};
export const savecollectionFiles = async (
    collectionUID: string,
    files: EnteFile[]
) => {
    const collectionFiles =
        (await localForage.getItem<SavedCollectionFiles[]>(
            COLLECTION_FILES_TABLE
        )) || [];
    await localForage.setItem(
        COLLECTION_FILES_TABLE,
        dedupeCollectionFiles([{ collectionUID, files }, ...collectionFiles])
    );
};

export const getLocalCollections = async (collectionKey: string) => {
    const localCollections =
        (await localForage.getItem<Collection[]>(COLLECTIONS_TABLE)) || [];
    const collection =
        localCollections.find(
            (localSavedPublicCollection) =>
                localSavedPublicCollection.key === collectionKey
        ) || null;
    return collection;
};

export const saveCollection = async (collection: Collection) => {
    const collections =
        (await localForage.getItem<Collection[]>(COLLECTIONS_TABLE)) ?? [];
    await localForage.setItem(
        COLLECTIONS_TABLE,
        dedupeCollections([collection, ...collections])
    );
};

const dedupeCollections = (collections: Collection[]) => {
    const keySet = new Set([]);
    return collections.filter((collection) => {
        if (!keySet.has(collection.key)) {
            keySet.add(collection.key);
            return true;
        } else {
            return false;
        }
    });
};

const dedupeCollectionFiles = (collectionFiles: SavedCollectionFiles[]) => {
    const keySet = new Set([]);
    return collectionFiles.filter(({ collectionUID }) => {
        if (!keySet.has(collectionUID)) {
            keySet.add(collectionUID);
            return true;
        } else {
            return false;
        }
    });
};

async function getSyncTime(collectionUID: string): Promise<number> {
    const lastSyncKey = getLastSyncKey(collectionUID);
    const lastSyncTime = await localForage.getItem<number>(lastSyncKey);
    return lastSyncTime ?? 0;
}

const updateSyncTime = async (collectionUID: string, time: number) =>
    await localForage.setItem(getLastSyncKey(collectionUID), time);

export const syncPublicFiles = async (
    token: string,
    collection: Collection,
    setPublicFiles: (files: EnteFile[]) => void
) => {
    try {
        let files: EnteFile[] = [];
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        const collectionUID = getPublicCollectionUID(token);
        const localFiles = await getLocalFiles(collectionUID);

        files = [...files, ...localFiles];
        try {
            if (!token) {
                return sortFiles(files, sortAsc);
            }
            const lastSyncTime = await getSyncTime(collectionUID);
            if (collection.updationTime === lastSyncTime) {
                return sortFiles(files, sortAsc);
            }
            const fetchedFiles = await fetchFiles(
                token,
                collection,
                lastSyncTime,
                files,
                setPublicFiles
            );

            files = [...files, ...fetchedFiles];
            const latestVersionFiles = new Map<string, EnteFile>();
            files.forEach((file) => {
                const uid = `${file.collectionID}-${file.id}`;
                if (
                    !latestVersionFiles.has(uid) ||
                    latestVersionFiles.get(uid).updationTime < file.updationTime
                ) {
                    latestVersionFiles.set(uid, file);
                }
            });
            files = [];
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            for (const [_, file] of latestVersionFiles) {
                if (file.isDeleted) {
                    continue;
                }
                files.push(file);
            }
            await savecollectionFiles(collectionUID, files);
            await updateSyncTime(collectionUID, collection.updationTime);
            setPublicFiles([...sortFiles(mergeMetadata(files), sortAsc)]);
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            logError(e, 'failed to sync shared collection files');
            if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                throw e;
            }
        }
        return [...sortFiles(mergeMetadata(files), sortAsc)];
    } catch (e) {
        logError(e, 'failed to get local  or sync shared collection files');
        throw e;
    }
};

const fetchFiles = async (
    token: string,
    collection: Collection,
    sinceTime: number,
    files: EnteFile[],
    setPublicFiles: (files: EnteFile[]) => void
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        do {
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                `${ENDPOINT}/public-collection/diff`,
                {
                    sinceTime: time,
                },
                {
                    'Cache-Control': 'no-cache',
                    'X-Auth-Access-Token': token,
                }
            );
            decryptedFiles = [
                ...decryptedFiles,
                ...(await Promise.all(
                    resp.data.diff.map(async (file: EncryptedEnteFile) => {
                        if (!file.isDeleted) {
                            return await decryptFile(file, collection.key);
                        } else {
                            return file;
                        }
                    }) as Promise<EnteFile>[]
                )),
            ];

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setPublicFiles(
                sortFiles(
                    mergeMetadata(
                        [...(files || []), ...decryptedFiles].filter(
                            (item) => !item.isDeleted
                        )
                    ),
                    sortAsc
                )
            );
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        logError(e, 'Get public  files failed');
        throw e;
    }
};

export const getCastCollection = async (
    token: string,
    collectionKey: string
): Promise<[Collection]> => {
    try {
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            `${ENDPOINT}/public-collection/info`,
            null,
            { 'Cache-Control': 'no-cache', 'X-Auth-Access-Token': token }
        );
        const fetchedCollection = resp.data.collection;

        const cryptoWorker = await ComlinkCryptoWorker.getInstance();

        const collectionName = (fetchedCollection.name =
            fetchedCollection.name ||
            (await cryptoWorker.decryptToUTF8(
                fetchedCollection.encryptedName,
                fetchedCollection.nameDecryptionNonce,
                collectionKey
            )));

        let collectionPublicMagicMetadata: CollectionPublicMagicMetadata;
        if (fetchedCollection.pubMagicMetadata?.data) {
            collectionPublicMagicMetadata = {
                ...fetchedCollection.pubMagicMetadata,
                data: await cryptoWorker.decryptMetadata(
                    fetchedCollection.pubMagicMetadata.data,
                    fetchedCollection.pubMagicMetadata.header,
                    collectionKey
                ),
            };
        }

        const collection = {
            ...fetchedCollection,
            name: collectionName,
            key: collectionKey,
            pubMagicMetadata: collectionPublicMagicMetadata,
        };
        await saveCollection(collection);
        return [collection];
    } catch (e) {
        logError(e, 'failed to get public collection');
        throw e;
    }
};

export const removeCollection = async (
    collectionUID: string,
    collectionKey: string
) => {
    const collections =
        (await localForage.getItem<Collection[]>(COLLECTIONS_TABLE)) || [];
    await localForage.setItem(
        COLLECTIONS_TABLE,
        collections.filter((collection) => collection.key !== collectionKey)
    );
    await removeCollectionFiles(collectionUID);
};

export const removeCollectionFiles = async (collectionUID: string) => {
    await localForage.removeItem(getLastSyncKey(collectionUID));
    const collectionFiles =
        (await localForage.getItem<SavedCollectionFiles[]>(
            COLLECTION_FILES_TABLE
        )) ?? [];
    await localForage.setItem(
        COLLECTION_FILES_TABLE,
        collectionFiles.filter(
            (collectionFiles) => collectionFiles.collectionUID !== collectionUID
        )
    );
};
