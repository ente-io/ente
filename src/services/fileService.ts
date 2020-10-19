import { getEndpoint } from "utils/common/apiUtil";
import HTTPService from "./HTTPService";
import * as Comlink from "comlink";

const CryptoWorker: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/crypto.worker.js", { type: 'module' }));
const ENDPOINT = getEndpoint();

export interface fileAttribute {
    encryptedData: string;
    decryptionHeader: string;
};

export interface collection {
    id: number;
    ownerID: number;
    key: string;
    name: string;
    type: string;
    creationTime: number;
}

export interface file {
    id: number;
    collectionID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
    encryptedKey: string;
    keyDecryptionNonce: string;
    key: Uint8Array;
    src: string;
    w: number;
    h: number;
};

const getCollectionKeyUsingWorker = async (collection: any, key: Uint8Array) => {
    const worker = await new CryptoWorker();
    const collectionKey = await worker.decrypt(
        await worker.fromB64(collection.encryptedKey),
        await worker.fromB64(collection.keyDecryptionNonce),
        key);
    return {
        ...collection,
        key: collectionKey
    };
}

const getCollections = async (token: string, key: Uint8Array): Promise<collection[]> => {
    const resp = await HTTPService.get(`${ENDPOINT}/collections/owned`, {
        token
    });

    const promises: Promise<collection>[] = resp.data.collections.map(
        (collection: collection) => getCollectionKeyUsingWorker(collection, key));
    return await Promise.all(promises);
}

export const getFiles = async (sinceTime: string, token: string, limit: string, key: string) => {
    const worker = await new CryptoWorker();

    const collections = await getCollections(token, await worker.fromB64(key));
    const collectionMap = {}
    for (const collectionIndex in collections) {
        collectionMap[collections[collectionIndex].id] = collections[collectionIndex];
    }
    const resp = await HTTPService.get(`${ENDPOINT}/files/diff`, {
        sinceTime, token, limit,
    });

    const promises: Promise<file>[] = resp.data.diff.map(
        async (file: file) => {
            file.key = await worker.decrypt(
                await worker.fromB64(file.encryptedKey),
                await worker.fromB64(file.keyDecryptionNonce),
                collectionMap[file.collectionID].key)
            file.metadata = await worker.decryptMetadata(file);
            return file;
        });
    return await Promise.all(promises);
}

export const getPreview = async (token: string, file: file) => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/files/preview/${file.id}`,
        { token }, null, { responseType: 'arraybuffer' },
    );
    const worker = await new CryptoWorker();
    const decrypted: any = await worker.decryptFile(
        new Uint8Array(resp.data),
        await worker.fromB64(file.thumbnail.decryptionHeader),
        file.key);
    return URL.createObjectURL(new Blob([decrypted]));
}
