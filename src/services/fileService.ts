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



export const fetchData = async (token, collections) => {
    const resp = await fetchFiles(
        token,
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

export const fetchFiles = async (
    token: string,
    collections: collection[]
) => {
    let files: Array<file> = (await localForage.getItem<file[]>('files')) || [];
    const fetchedFiles = await getFiles(collections, null, "100", token);

    files.push(...fetchedFiles);
    files = files.sort(
        (a, b) => b.metadata.creationTime - a.metadata.creationTime
    );
    await localForage.setItem('files', files);
    return files;
};

export const getFiles = async (collections: collection[], sinceTime: string, limit: string, token: string): Promise<file[]> => {
    const worker = await new CryptoWorker();
    let promises: Promise<file>[] = [];
    for (const index in collections) {
        const collection = collections[index];
        if (collection.isDeleted) {
            // TODO: Remove files in this collection from localForage and cache
            continue;
        }
        let time =
            sinceTime || (await localForage.getItem<string>(`${collection.id}-time`)) || "0";
        let resp;
        do {
            resp = await HTTPService.get(`${ENDPOINT}/collections/diff`, {
                collectionID: collection.id,
                sinceTime: time,
                token,
                limit,
            });
            promises.push(...resp.data.diff.filter(file => !file.isDeleted).map(
                async (file: file) => {
                    file.key = await worker.decryptB64(
                        file.encryptedKey,
                        file.keyDecryptionNonce,
                        collection.key
                    );
                    file.metadata = await worker.decryptMetadata(file);
                    return file;
                }
            ));

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime.toString();
            }
        } while (resp.data.diff.length);
        await localForage.setItem(`${collection.id}-time`, time);
    }
    return Promise.all(promises);
}
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

