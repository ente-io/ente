import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
import localForage from 'localforage';
import { collection } from './collectionService';

const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();

localForage.config({
    driver: localForage.INDEXEDDB,
    name: 'ente-files',
    version: 1.0,
    storeName: 'files',
});

export interface fileAttribute {
    encryptedData: Uint8Array | string;
    decryptionHeader: string;
    creationTime: number;
    fileType: number;
}

export interface user {
    id: number;
    name: string;
    email: string;
}


export interface file {
    id: number;
    collectionID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
    encryptedKey: string;
    keyDecryptionNonce: string;
    key: string;
    src: string;
    msrc: string;
    html: string;
    w: number;
    h: number;
    isDeleted: boolean;
    dataIndex: number;
}

export interface collectionLatestFile {
    collection: collection
    file: file;
}


export const fetchData = async (token, collections) => {
    const resp = await getFiles(
        '0',
        token,
        '100',
        collections
    );

    return (
        resp.map((item) => ({
            ...item,
            w: window.innerWidth,
            h: window.innerHeight,
        }))
    );
}

export const getFiles = async (
    sinceTime: string,
    token: string,
    limit: string,
    collections: collection[]
) => {
    const worker = await new CryptoWorker();
    let files: Array<file> = (await localForage.getItem<file[]>('files')) || [];
    for (const index in collections) {
        const collection = collections[index];
        if (collection.isDeleted) {
            // TODO: Remove files in this collection from localForage and cache
            continue;
        }
        let time =
            (await localForage.getItem<string>(`${collection.id}-time`)) || sinceTime;
        let resp;
        do {
            resp = await HTTPService.get(`${ENDPOINT}/collections/diff`, {
                collectionID: collection.id,
                sinceTime: time,
                token,
                limit,
            });
            const promises: Promise<file>[] = resp.data.diff.filter(file => !file.isDeleted).map(
                async (file: file) => {
                    console.log(file);
                    file.key = await worker.decryptB64(
                        file.encryptedKey,
                        file.keyDecryptionNonce,
                        collection.key
                    );
                    file.metadata = await worker.decryptMetadata(file);
                    return file;
                }
            );
            files.push(...(await Promise.all(promises)));
            files = files.sort(
                (a, b) => b.metadata.creationTime - a.metadata.creationTime
            );
            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime.toString();
            }
        } while (resp.data.diff.length);
        await localForage.setItem(`${collection.id}-time`, time);
    }
    await localForage.setItem('files', files);
    return files;
};

export const getPreview = async (token: string, file: file) => {
    const cache = await caches.open('thumbs');
    const cacheResp: Response = await cache.match(file.id.toString());
    if (cacheResp) {
        return URL.createObjectURL(await cacheResp.blob());
    }
    const resp = await HTTPService.get(
        `${ENDPOINT}/files/preview/${file.id}`,
        { token },
        null,
        { responseType: 'arraybuffer' }
    );
    const worker = await new CryptoWorker();
    const decrypted: any = await worker.decryptThumbnail(
        new Uint8Array(resp.data),
        await worker.fromB64(file.thumbnail.decryptionHeader),
        file.key
    );
    try {
        await cache.put(file.id.toString(), new Response(new Blob([decrypted])));
    } catch (e) {
        // TODO: handle storage full exception.
    }
    return URL.createObjectURL(new Blob([decrypted]));
};

export const getFile = async (token: string, file: file) => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/files/download/${file.id}`,
        { token },
        null,
        { responseType: 'arraybuffer' }
    );
    const worker = await new CryptoWorker();
    const decrypted: any = await worker.decryptFile(
        new Uint8Array(resp.data),
        await worker.fromB64(file.file.decryptionHeader),
        file.key
    );
    return URL.createObjectURL(new Blob([decrypted]));
};

export const getCollectionLatestFile = async (
    collections: collection[],
    data: file[]
): Promise<collectionLatestFile[]> => {
    let collectionIdSet = new Set<number>();
    let collectionMap = new Map<number, collection>();
    collections.forEach((collection) => {
        collectionMap.set(Number(collection.id), collection);
        collectionIdSet.add(Number(collection.id))
    });
    return Promise.all(
        data
            .filter((item) => {
                if (collectionIdSet.size !== 0 && collectionIdSet.has(item.collectionID)) {
                    collectionIdSet.delete(item.collectionID);
                    return true;
                }
                return false;
            })
            .map(async (item) => {
                return {
                    file: item,
                    collection: collectionMap.get(item.collectionID),
                };
            })
    );
};
