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
    name: string;
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


const getCollectionKey = async (collection: collection, masterKey: string) => {
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
            await collection.encryptedKey,
            await keyAttributes.publicKey,
            await secretKey
        );
    }
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
    const resp = await HTTPService.get(`${ENDPOINT}/collections`, {
        token: token,
        sinceTime: sinceTime,
    });
    const ignore: Set<number> = new Set([206, 208]);
    const promises: Promise<collection>[] = resp.data.collections.filter(collection => !ignore.has(collection.id)).map(
        (collection: collection) => getCollectionKey(collection, key)
    );
    return await Promise.all(promises);
};

export const fetchCollections = async (token: string, key: string) => {
    const collections = await getCollections(token, '0', key);
    const favCollection = collections.filter(collection => collection.type === CollectionType.favorites);
    await localForage.setItem('fav-collection', favCollection);
    return collections;
};

export const getCollectionLatestFile = async (
    collections: collection[],
    token
): Promise<collectionLatestFile[]> => {
    return Promise.all(
        collections.map(async collection => {
            const sinceTime: string = (Number(await localForage.getItem<string>(`${collection.id}-time`)) - 1).toString();
            const file: file[] = await getFiles([collection], sinceTime, "100", token);
            return {
                file: file[0],
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


export const AddCollection = async (albumName: string, type: CollectionType) => {
    const worker = await new CryptoWorker();
    const encryptionKey = await getActualKey();
    const token = getToken();
    const collectionKey: string = await worker.generateMasterKey();
    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce }: keyEncryptionResult = await worker.encryptToB64(collectionKey, encryptionKey);
    const newCollection: collection = {
        id: null,
        owner: null,
        encryptedKey,
        keyDecryptionNonce,
        name: albumName,
        type,
        attributes: {},
        sharees: null,
        updationTime: null,
        isDeleted: false
    };
    let createdCollection: collection = await createCollection(newCollection, token);
    createdCollection = await getCollectionKey(createdCollection, encryptionKey);
    return createdCollection;
}

const createCollection = async (collectionData: collection, token: string): Promise<collection> => {
    const response = await HTTPService.post(`${ENDPOINT}/collections`, collectionData, { token });
    return response.data.collection;
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
    await HTTPService.post(`${ENDPOINT}/collections/add-files`, params, { token });
}
const removeFromCollection = async (collection: collection, files: file[]) => {
    const params = new Object();
    const token = getToken();
    params["collectionID"] = collection.id;
    await Promise.all(files.map(async file => {
        if (params["fileIDs"] == undefined) {
            params["fileIDs"] = [];
        }
        params["fileIDs"].push(file.id);
    }));
    await HTTPService.post(`${ENDPOINT}/collections/remove-files`, params, { token });
}

