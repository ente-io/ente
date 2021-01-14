import { getEndpoint } from "utils/common/apiUtil";
import { getData, LS_KEYS } from "utils/storage/localStorage";
import { user } from "./fileService";
import HTTPService from "./HTTPService";
import * as Comlink from 'comlink';
import { keyEncryptionResult } from "./uploadService";


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
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(keyAttributes.publicKey),
            await worker.fromB64(secretKey)
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
    return getCollections(token, '0', key);
};

export const createAlbum = async (albumName: string, key: string, token: string) => {
    const worker = await new CryptoWorker();
    const collectionKey: Uint8Array = await worker.generateMasterKey();
    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce }: keyEncryptionResult = await worker.encryptToB64(collectionKey, key);
    const newCollection: collection = {
        id: null,
        owner: null,
        encryptedKey,
        keyDecryptionNonce,
        name: albumName,
        type: CollectionType.album,
        attributes: {},
        sharees: null,
        updationTime: null,
        isDeleted: false
    };
    let createdCollection: collection = await createCollection(newCollection, token);
    createdCollection = await getCollectionKey(createdCollection, key);
    return createdCollection;
}

const createCollection = async (collectionData: collection, token: string): Promise<collection> => {
    const response = await HTTPService.post(`${ENDPOINT}/collections`, collectionData, { token });
    return response.data.collection;
}
