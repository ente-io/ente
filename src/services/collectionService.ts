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
    folder,
    favorites,
    album,
}

export interface collection {
    id: string;
    owner: user;
    key?: Uint8Array;
    name: string;
    type: number;
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

const getCollectionKey = async (collection: collection, key: Uint8Array) => {
    const worker = await new CryptoWorker();
    const userID = getData(LS_KEYS.USER).id;
    var decryptedKey;
    if (collection.owner.id == userID) {
        decryptedKey = await worker.decrypt(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(collection.keyDecryptionNonce),
            key
        );
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await worker.decrypt(
            await worker.fromB64(keyAttributes.encryptedSecretKey),
            await worker.fromB64(keyAttributes.secretKeyDecryptionNonce),
            key
        );
        decryptedKey = await worker.boxSealOpen(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(keyAttributes.publicKey),
            secretKey
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
    key: Uint8Array
): Promise<collection[]> => {
    const resp = await HTTPService.get(`${ENDPOINT}/collections`, {
        token: token,
        sinceTime: sinceTime,
    });

    const promises: Promise<collection>[] = resp.data.collections.map(
        (collection: collection) => getCollectionKey(collection, key)
    );
    return await Promise.all(promises);
};

export const fetchCollections = async (token: string, key: string) => {
    const worker = await new CryptoWorker();
    return getCollections(token, '0', await worker.fromB64(key));
};

export const createAlbum = async (albumName: string, key: Uint8Array, token: string) => {
    const worker = await new CryptoWorker();
    const collectionKey = await worker.generateMasterKey();
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
    return response.data
}
