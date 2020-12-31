import { getEndpoint } from "utils/common/apiUtil";
import HTTPService from "./HTTPService";
import * as Comlink from "comlink";
import { getData, LS_KEYS } from "utils/storage/localStorage";
import localForage from "localforage";

const CryptoWorker: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/crypto.worker.js", { type: 'module' }));
const ENDPOINT = getEndpoint();

localForage.config({
    driver: localForage.INDEXEDDB,
    name: 'ente-files',
    version: 1.0,
    storeName: 'files',
});

export interface fileAttribute {
    encryptedData: string;
    decryptionHeader: string;
    creationTime: number;
    fileType: number;
};

export interface user {
    id: number;
    name: string;
    email: string;
}

export interface collection {
    id: string;
    owner: user;
    key: string;
    name: string;
    type: string;
    creationTime: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
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
    msrc: string;
    html: string;
    w: number;
    h: number;
    isDeleted: boolean;
    dataIndex: number;
};

const getCollectionKey = async (collection: collection, key: Uint8Array) => {
    const worker = await new CryptoWorker();
    const userID = getData(LS_KEYS.USER).id;
    var decryptedKey;
    if (collection.owner.id == userID) {
        decryptedKey = await worker.decrypt(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(collection.keyDecryptionNonce),
            key);
    } else {
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const secretKey = await worker.decrypt(
            await worker.fromB64(keyAttributes.encryptedSecretKey),
            await worker.fromB64(keyAttributes.secretKeyDecryptionNonce),
            key);
        decryptedKey = await worker.boxSealOpen(
            await worker.fromB64(collection.encryptedKey),
            await worker.fromB64(keyAttributes.publicKey),
            secretKey);
    }
    return {
        ...collection,
        key: decryptedKey
    };
}

const getCollections = async (token: string, sinceTime: string, key: Uint8Array): Promise<collection[]> => {
    const resp = await HTTPService.get(`${ENDPOINT}/collections`, {
        'token': token,
        'sinceTime': sinceTime,
    });

    const promises: Promise<collection>[] = resp.data.collections.map(
        (collection: collection) => getCollectionKey(collection, key));
    return await Promise.all(promises);
}

export const fetchCollections = async (token: string, key: string) => {
    const worker = await new CryptoWorker();
    return getCollections(token, "0", await worker.fromB64(key));
}

export const getFiles = async (sinceTime: string, token: string, limit: string, key: string, collections: collection[]) => {
    const worker = await new CryptoWorker();
    let files: Array<file> = await localForage.getItem<file[]>('files') || [];
    for (const index in collections) {
        const collection = collections[index];
        if (collection.isDeleted) {
            // TODO: Remove files in this collection from localForage and cache
            continue;
        }
        let time = await localForage.getItem<string>(`${collection.id}-time`) || sinceTime;
        let resp;
        do {
            resp = await HTTPService.get(`${ENDPOINT}/collections/diff`, {
                'collectionID': collection.id, sinceTime: time, token, limit,
            });
            const promises: Promise<file>[] = resp.data.diff.map(
                async (file: file) => {
                    file.key = await worker.decrypt(
                        await worker.fromB64(file.encryptedKey),
                        await worker.fromB64(file.keyDecryptionNonce),
                        collection.key);
                    file.metadata = await worker.decryptMetadata(file);
                    return file;
                });
            files.push(...await Promise.all(promises));
            files = files.sort((a, b) => b.metadata.creationTime - a.metadata.creationTime);
            if (resp.data.diff.length) {
                time = (resp.data.diff.slice(-1)[0].updationTime).toString();
            }
        } while (resp.data.diff.length);
        await localForage.setItem(`${collection.id}-time`, time);
    }
    files = files.filter(item => !item.isDeleted)
    await localForage.setItem('files', files);
    return files;
}

export const getPreview = async (token: string, file: file) => {
    const cache = await caches.open('thumbs');
    const cacheResp: Response = await cache.match(file.id.toString());
    if (cacheResp) {
        return URL.createObjectURL(await cacheResp.blob());
    }
    const resp = await HTTPService.get(
        `${ENDPOINT}/files/preview/${file.id}`,
        { token }, null, { responseType: 'arraybuffer' },
    );
    const worker = await new CryptoWorker();
    const decrypted: any = await worker.decryptThumbnail(
        new Uint8Array(resp.data),
        await worker.fromB64(file.thumbnail.decryptionHeader),
        file.key);
    try {
        await cache.put(file.id.toString(), new Response(new Blob([decrypted])));
    } catch (e) {
        // TODO: handle storage full exception.
    }
    return URL.createObjectURL(new Blob([decrypted]));
}

export const getFile = async (token: string, file: file) => {
    const worker = await new CryptoWorker();
    if (file.metadata.fileType === 0) {
        const resp = await HTTPService.get(
            `${ENDPOINT}/files/download/${file.id}`,
            { token }, null, { responseType: 'arraybuffer' },
        );
        const decrypted: any = await worker.decryptFile(
            new Uint8Array(resp.data),
            await worker.fromB64(file.file.decryptionHeader),
            file.key,
        );
        return URL.createObjectURL(new Blob([decrypted]));
    } else {
        const source = new MediaSource();
        source.addEventListener('sourceopen', async () => {
            if (!source.sourceBuffers.length) {
                const sourceBuffer = source.addSourceBuffer('video/mp4; codecs="avc1.64000d,mp4a.40.2"');
                const resp = await fetch(`${ENDPOINT}/files/download/${file.id}?token=${token}`);
                const reader = resp.body.getReader();
                new ReadableStream({
                    async start() {
                        let { pullState, decryptionChunkSize, tag } = await worker.initDecryption(
                            await worker.fromB64(file.file.decryptionHeader),
                            file.key
                        );
                        console.log(pullState, decryptionChunkSize, tag);
                        let data = new Uint8Array();
                        // The following function handles each data chunk
                        function push() {
                            // "done" is a Boolean and value a "Uint8Array"
                            reader.read().then(async ({ done, value }) => {
                                // Is there more data to read?
                                if (!done) {
                                    const buffer = new Uint8Array(data.byteLength + value.byteLength);
                                    buffer.set(new Uint8Array(data), 0);
                                    buffer.set(new Uint8Array(value), data.byteLength);
                                    if (buffer.length > decryptionChunkSize) {
                                        const fileData = buffer.slice(0, decryptionChunkSize);
                                        const { decryptedData, newTag } = await worker.decryptChunk(fileData, pullState);
                                        sourceBuffer.appendBuffer(decryptedData);
                                        tag = newTag;
                                        data = buffer.slice(decryptionChunkSize);
                                        console.log('>', decryptionChunkSize, data.length, tag);
                                    } else {
                                        data = buffer;
                                        push();
                                    }
                                } else {
                                    console.log('end', value.length);
                                    source.endOfStream();
                                }
                            });
                        };
    
                        sourceBuffer.addEventListener('updateend', () => {
                            console.log('appended');
                            push();
                        });
    
                        push();
                    }
                });
            }
        });

        source.addEventListener('sourceended', () => {
            console.log('sourceend');
        });
        return URL.createObjectURL(source);
    }
}
