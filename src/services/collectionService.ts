import { getEndpoint } from 'utils/common/apiUtil';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { File } from './fileService';
import localForage from 'utils/storage/localForage';

import HTTPService from './HTTPService';
import { B64EncryptionResult } from './uploadService';
import { getActualKey, getToken } from 'utils/common/key';
import { getPublicKey, User } from './userService';
import CryptoWorker from 'utils/crypto';
import { errorCodes, ErrorHandler } from 'utils/common/errorUtil';

const ENDPOINT = getEndpoint();

export enum CollectionType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
}

const COLLECTION_UPDATION_TIME = 'collection-updation-time';
const FAV_COLLECTION = 'fav-collection';
const COLLECTIONS = 'collections';

export interface Collection {
    id: number;
    owner: User;
    key?: string;
    name?: string;
    encryptedName?: string;
    nameDecryptionNonce?: string;
    type: CollectionType;
    attributes: collectionAttributes;
    sharees: User[];
    updationTime: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
}

interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string;
}

export interface CollectionAndItsLatestFile {
    collection: Collection;
    file: File;
}

const getCollectionWithSecrets = async (
    collection: Collection,
    masterKey: string
) => {
    const worker = await new CryptoWorker();
    const userID = getData(LS_KEYS.USER).id;
    let decryptedKey: string;
    if (collection.owner.id == userID) {
        decryptedKey = await worker.decryptB64(
            collection.encryptedKey,
            collection.keyDecryptionNonce,
            masterKey
        );
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await worker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey
        );
        decryptedKey = await worker.boxSealOpen(
            collection.encryptedKey,
            keyAttributes.publicKey,
            secretKey
        );
    }
    collection.name =
        collection.name ||
        (await worker.decryptToUTF8(
            collection.encryptedName,
            collection.nameDecryptionNonce,
            decryptedKey
        ));
    return {
        ...collection,
        key: decryptedKey,
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
                sinceTime: sinceTime,
            },
            { 'X-Auth-Token': token }
        );
        const promises: Promise<Collection>[] = resp.data.collections.map(
            async (collection: Collection) => {
                if (collection.isDeleted) {
                    return collection;
                }
                let collectionWithSecrets = collection;
                try {
                    collectionWithSecrets = await getCollectionWithSecrets(
                        collection,
                        key
                    );
                } catch (e) {
                    console.error(
                        `decryption failed for collection with id=${collection.id}`,
                        e
                    );
                } finally {
                    return collectionWithSecrets;
                }
            }
        );
        return await Promise.all(promises);
    } catch (e) {
        console.error('getCollections failed- ', e);
        throw new Error(e?.status?.toString());
    }
};

export const getLocalCollections = async (): Promise<Collection[]> => {
    const collections: Collection[] =
        (await localForage.getItem(COLLECTIONS)) ?? [];
    return collections;
};

export const getCollectionUpdationTime = async (): Promise<number> => {
    return (await localForage.getItem<number>(COLLECTION_UPDATION_TIME)) ?? 0;
};

export const syncCollections = async () => {
    const localCollections = await getLocalCollections();
    const lastCollectionUpdationTime = await getCollectionUpdationTime();
    const token = getToken();
    let key;
    try {
        key = await getActualKey();
    } catch (e) {
        throw e;
    }
    const updatedCollections =
        (await getCollections(token, lastCollectionUpdationTime, key)) ?? [];
    if (updatedCollections.length == 0) {
        return localCollections;
    }
    const allCollectionsInstances = [
        ...localCollections,
        ...updatedCollections,
    ];
    var latestCollectionsInstances = new Map<number, Collection>();
    allCollectionsInstances.forEach((collection) => {
        if (
            !latestCollectionsInstances.has(collection.id) ||
            latestCollectionsInstances.get(collection.id).updationTime <
                collection.updationTime
        ) {
            latestCollectionsInstances.set(collection.id, collection);
        }
    });

    let collections = [],
        updationTime = await localForage.getItem<number>(
            COLLECTION_UPDATION_TIME
        );
    for (const [_, collection] of latestCollectionsInstances) {
        if (!collection.isDeleted) {
            collections.push(collection);
            updationTime = Math.max(updationTime, collection.updationTime);
        }
    }
    collections.sort((a, b) => b.updationTime - a.updationTime);
    collections.sort((a, b) => (b.type === CollectionType.favorites ? 1 : 0));
    await localForage.setItem(COLLECTION_UPDATION_TIME, updationTime);
    await localForage.setItem(COLLECTIONS, collections);
    return collections;
};

export const getCollectionsAndTheirLatestFile = (
    collections: Collection[],
    files: File[]
): CollectionAndItsLatestFile[] => {
    const latestFile = new Map<number, File>();

    files.forEach((file) => {
        if (!latestFile.has(file.collectionID)) {
            latestFile.set(file.collectionID, file);
        }
    });
    let collectionsAndTheirLatestFile: CollectionAndItsLatestFile[] = [];
    const userID = getData(LS_KEYS.USER)?.id;

    for (const collection of collections) {
        if (
            collection.owner.id != userID ||
            collection.type == CollectionType.favorites
        ) {
            continue;
        }
        collectionsAndTheirLatestFile.push({
            collection,
            file: latestFile.get(collection.id),
        });
    }
    return collectionsAndTheirLatestFile;
};

export const getFavItemIds = async (files: File[]): Promise<Set<number>> => {
    let favCollection = await getFavCollection();
    if (!favCollection) return new Set();

    return new Set(
        files
            .filter((file) => file.collectionID === favCollection.id)
            .map((file): number => file.id)
    );
};

export const createAlbum = async (albumName: string) => {
    return createCollection(albumName, CollectionType.album);
};

export const createCollection = async (
    collectionName: string,
    type: CollectionType
): Promise<Collection> => {
    try {
        const existingCollections = await getLocalCollections();
        for (let collection of existingCollections) {
            if (collection.name === collectionName) {
                return collection;
            }
        }
        const worker = await new CryptoWorker();
        const encryptionKey = await getActualKey();
        const token = getToken();
        const collectionKey: string = await worker.generateEncryptionKey();
        const {
            encryptedData: encryptedKey,
            nonce: keyDecryptionNonce,
        }: B64EncryptionResult = await worker.encryptToB64(
            collectionKey,
            encryptionKey
        );
        const {
            encryptedData: encryptedName,
            nonce: nameDecryptionNonce,
        }: B64EncryptionResult = await worker.encryptUTF8(
            collectionName,
            collectionKey
        );
        const newCollection: Collection = {
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
        };
        let createdCollection: Collection = await postCollection(
            newCollection,
            token
        );
        createdCollection = await getCollectionWithSecrets(
            createdCollection,
            encryptionKey
        );
        return createdCollection;
    } catch (e) {
        console.error('Add collection failed', e);
    }
};

const postCollection = async (
    collectionData: Collection,
    token: string
): Promise<Collection> => {
    try {
        const response = await HTTPService.post(
            `${ENDPOINT}/collections`,
            collectionData,
            null,
            { 'X-Auth-Token': token }
        );
        return response.data.collection;
    } catch (e) {
        console.error('create Collection failed ', e);
    }
};

export const addToFavorites = async (file: File) => {
    let favCollection = await getFavCollection();
    if (!favCollection) {
        favCollection = await createCollection(
            'Favorites',
            CollectionType.favorites
        );
        await localForage.setItem(FAV_COLLECTION, favCollection);
    }
    await addToCollection(favCollection, [file]);
};

export const removeFromFavorites = async (file: File) => {
    let favCollection = await getFavCollection();
    await removeFromCollection(favCollection, [file]);
};

export const addToCollection = async (
    collection: Collection,
    files: File[]
) => {
    try {
        const params = new Object();
        const worker = await new CryptoWorker();
        const token = getToken();
        params['collectionID'] = collection.id;
        await Promise.all(
            files.map(async (file) => {
                file.collectionID = collection.id;
                const newEncryptedKey: B64EncryptionResult = await worker.encryptToB64(
                    file.key,
                    collection.key
                );
                file.encryptedKey = newEncryptedKey.encryptedData;
                file.keyDecryptionNonce = newEncryptedKey.nonce;
                if (params['files'] == undefined) {
                    params['files'] = [];
                }
                params['files'].push({
                    id: file.id,
                    encryptedKey: file.encryptedKey,
                    keyDecryptionNonce: file.keyDecryptionNonce,
                });
                return file;
            })
        );
        await HTTPService.post(
            `${ENDPOINT}/collections/add-files`,
            params,
            null,
            { 'X-Auth-Token': token }
        );
    } catch (e) {
        console.error('Add to collection Failed ', e);
    }
};
const removeFromCollection = async (collection: Collection, files: File[]) => {
    try {
        const params = new Object();
        const token = getToken();
        params['collectionID'] = collection.id;
        await Promise.all(
            files.map(async (file) => {
                if (params['fileIDs'] == undefined) {
                    params['fileIDs'] = [];
                }
                params['fileIDs'].push(file.id);
            })
        );
        await HTTPService.post(
            `${ENDPOINT}/collections/remove-files`,
            params,
            null,
            { 'X-Auth-Token': token }
        );
    } catch (e) {
        console.error('remove from collection failed ', e);
    }
};

export const deleteCollection = async (
    collectionID: number,
    syncWithRemote: () => Promise<void>,
    redirectToAll: () => void
) => {
    try {
        const token = getToken();

        await HTTPService.delete(
            `${ENDPOINT}/collections/${collectionID}`,
            null,
            null,
            { 'X-Auth-Token': token }
        );
        await syncWithRemote();
        redirectToAll();
    } catch (e) {
        console.error('delete collection failed ', e);
    }
};

export const renameCollection = async (
    collection: Collection,
    newCollectionName: string
) => {
    const token = getToken();
    const worker = await new CryptoWorker();
    const {
        encryptedData: encryptedName,
        nonce: nameDecryptionNonce,
    }: B64EncryptionResult = await worker.encryptUTF8(
        newCollectionName,
        collection.key
    );
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
export const shareCollection = async (
    collection: Collection,
    withUserEmail: string
) => {
    try {
        const worker = await new CryptoWorker();

        const token = getToken();
        const publicKey: string = await getPublicKey(withUserEmail);
        const encryptedKey: string = await worker.boxSeal(
            collection.key,
            publicKey
        );
        const shareCollectionRequest = {
            collectionID: collection.id,
            email: withUserEmail,
            encryptedKey: encryptedKey,
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
        console.error('share collection failed ', e);
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
        console.error('unshare collection failed ', e);
        throw e;
    }
};

export const getFavCollection = async () => {
    const collections = await getLocalCollections();
    for (let collection of collections) {
        if (collection.type == CollectionType.favorites) {
            return collection;
        }
    }
    return null;
};

export const getNonEmptyCollections = (
    collections: Collection[],
    files: File[]
) => {
    const nonEmptyCollectionsIds = new Set<number>();
    for (let file of files) {
        nonEmptyCollectionsIds.add(file.collectionID);
    }
    return collections.filter((collection) =>
        nonEmptyCollectionsIds.has(collection.id)
    );
};
