import { getEndpoint } from "utils/common/apiUtil";
import { getData, LS_KEYS } from "utils/storage/localStorage";
import { file, user, getFiles } from "./fileService";
import localForage from 'localforage';

import HTTPService from "./HTTPService";
import * as Comlink from 'comlink';
import { keyEncryptionResult } from "./uploadService";
import { getActualKey, getToken } from "utils/common/key";


const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();


enum CollectionType {
    folder = "folder",
    favorites = "favorites",
    album = "album",
}

export interface collection {
    id: string;
    owner: user;
    key?: string;
    name?: string;
    encryptedName?: string;
    nameDecryptionNonce?: string;
    type: string;
    attributes: collectionAttributes
    sharees: user[];
    updationTime: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
}

interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string
};

export interface collectionLatestFile {
    collection: collection
    file: file;
}


const getCollectionSecrets = async (collection: collection, masterKey: string) => {
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
    collection.name = collection.name || await worker.decryptString(
        collection.encryptedName,
        collection.nameDecryptionNonce,
        decryptedKey);
    return {
        ...collection,
        key: decryptedKey,
    };
};

const getCollections = async (
    token: string,
    sinceTime: string,
    key: string
): Promise<collection[]> => {
    try {
        const resp = await HTTPService.get(`${ENDPOINT}/collections`, {
            sinceTime: sinceTime,
        }, { 'X-Auth-Token': token, });
        const promises: Promise<collection>[] = resp.data.collections.map(
            (collection: collection) => getCollectionSecrets(collection, key)
        );
        return await Promise.all(promises);
    }
    catch (e) {
        console.log("getCollections falied- " + e);
    }
};

export const fetchCollections = async (token: string, key: string) => {
    const collectionUpdateTime = await localForage.getItem('collection-update-time') as string;
    const collections = await getCollections(token, collectionUpdateTime ?? '0', key);
    const favCollection = await localForage.getItem('fav-collection') as collection[] ?? collections.filter(collection => collection.type === CollectionType.favorites);
    await localForage.setItem('fav-collection', favCollection);
    await localForage.setItem('collection-update-time', Date.now() * 1000);
    return collections;
};

export const getCollectionLatestFile = async (
    collections: collection[],
    token
): Promise<collectionLatestFile[]> => {
    return Promise.all(
        collections.map(async collection => {
            const sinceTime: string = (Number(await localForage.getItem<string>(`${collection.id}-time`)) - 1).toString();
            const files: file[] = await getFiles([collection], sinceTime, "1", token) || [];

            return {
                file: files[0],
                collection,
            }
        }))
};

export const getFavItemIds = async (files: file[]): Promise<Set<number>> => {

    let favCollection: collection = (await localForage.getItem<collection>('fav-collection'))[0];
    if (!favCollection)
        return new Set();

    return new Set(files.filter(file => file.collectionID === Number(favCollection.id)).map((file): number => file.id));
}

export const createAlbum = async (albumName: string) => {
    return AddCollection(albumName, CollectionType.album);
}


export const AddCollection = async (collectionName: string, type: CollectionType) => {
    const worker = await new CryptoWorker();
    const encryptionKey = await getActualKey();
    const token = getToken();
    const collectionKey: string = await worker.generateMasterKey();
    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce }: keyEncryptionResult = await worker.encryptToB64(collectionKey, encryptionKey);
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce }: keyEncryptionResult = await worker.encryptToB64(collectionName, collectionKey);
    const newCollection: collection = {
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
        isDeleted: false
    };
    let createdCollection: collection = await createCollection(newCollection, token);
    createdCollection = await getCollectionSecrets(createdCollection, encryptionKey);
    return createdCollection;
}

const createCollection = async (collectionData: collection, token: string): Promise<collection> => {
    try {
        const response = await HTTPService.post(`${ENDPOINT}/collections`, collectionData, null, { 'X-Auth-Token': token });
        return response.data.collection;
    } catch (e) {
        console.log("create Collection failed " + e);
    }
}

export const addToFavorites = async (file: file) => {
    let favCollection: collection = (await localForage.getItem<collection>('fav-collection'))[0];
    if (!favCollection) {
        favCollection = await AddCollection("Favorites", CollectionType.favorites);
        await localForage.setItem('fav-collection', favCollection);
    }
    await addtoCollection(favCollection, [file])
}

export const removeFromFavorites = async (file: file) => {
    let favCollection: collection = (await localForage.getItem<collection>('fav-collection'))[0];
    await removeFromCollection(favCollection, [file])
}

const addtoCollection = async (collection: collection, files: file[]) => {
    try {
        const params = new Object();
        const worker = await new CryptoWorker();
        const token = getToken();
        params["collectionID"] = collection.id;
        await Promise.all(files.map(async file => {
            file.collectionID = Number(collection.id);
            const newEncryptedKey: keyEncryptionResult = await worker.encryptToB64(file.key, collection.key);
            file.encryptedKey = newEncryptedKey.encryptedData;
            file.keyDecryptionNonce = newEncryptedKey.nonce;
            if (params["files"] == undefined) {
                params["files"] = [];
            }
            params["files"].push({
                id: file.id,
                encryptedKey: file.encryptedKey,
                keyDecryptionNonce: file.keyDecryptionNonce
            })
            return file;
        }));
        await HTTPService.post(`${ENDPOINT}/collections/add-files`, params, null, { 'X-Auth-Token': token });
    } catch (e) {
        console.log("Add to collection Failed " + e);
    }
}
const removeFromCollection = async (collection: collection, files: file[]) => {
    try {
        const params = new Object();
        const token = getToken();
        params["collectionID"] = collection.id;
        await Promise.all(files.map(async file => {
            if (params["fileIDs"] == undefined) {
                params["fileIDs"] = [];
            }
            params["fileIDs"].push(file.id);
        }));
        await HTTPService.post(`${ENDPOINT}/collections/remove-files`, params, null, { 'X-Auth-Token': token });
    } catch (e) {
        console.log("remove from collection failed " + e);
    }
}

