import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import localForage from 'utils/storage/localForage';

import { collection } from './collectionService';
import { DataStream, MetadataObject } from './uploadService';
import CryptoWorker from 'utils/crypto/cryptoWorker';
import { getToken } from 'utils/common/key';
import { selectedState } from 'pages/gallery';

const ENDPOINT = getEndpoint();
const DIFF_LIMIT: number = 2500;

const FILES = 'files';

export interface fileAttribute {
    encryptedData?: DataStream | Uint8Array;
    objectKey?: string;
    decryptionHeader: string;
}

export interface file {
    id: number;
    collectionID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: MetadataObject;
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
    updationTime: number;
}

export const syncData = async (collections) => {
    const { files: resp, isUpdated } = await syncFiles(collections);

    return {
        data: resp.map((item) => ({
            ...item,
            w: window.innerWidth,
            h: window.innerHeight,
        })),
        isUpdated,
    };
};

export const localFiles = async () => {
    let files: Array<file> = (await localForage.getItem<file[]>(FILES)) || [];
    return files;
};

export const syncFiles = async (collections: collection[]) => {
    let files = await localFiles();
    let isUpdated = false;
    files = await removeDeletedCollectionFiles(collections, files);
    for (let collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime =
            (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }
        isUpdated = true;
        let fetchedFiles =
            (await getFiles(collection, lastSyncTime, DIFF_LIMIT)) ?? [];
        files.push(...fetchedFiles);
        var latestVersionFiles = new Map<string, file>();
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
        for (const [_, file] of latestVersionFiles) {
            if (file.isDeleted) {
                continue;
            }
            files.push(file);
        }
        files = files.sort(
            (a, b) => b.metadata.creationTime - a.metadata.creationTime
        );
        await localForage.setItem('files', files);
        await localForage.setItem(
            `${collection.id}-time`,
            collection.updationTime
        );
    }
    return { files, isUpdated };
};

export const getFiles = async (
    collection: collection,
    sinceTime: number,
    limit: number
): Promise<file[]> => {
    try {
        const worker = await new CryptoWorker();
        let promises: Promise<file>[] = [];
        let time =
            sinceTime ||
            (await localForage.getItem<number>(`${collection.id}-time`)) ||
            0;
        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                `${ENDPOINT}/collections/diff`,
                {
                    collectionID: collection.id,
                    sinceTime: time,
                    limit: limit,
                },
                {
                    'X-Auth-Token': token,
                }
            );
            promises.push(
                ...resp.data.diff.map(async (file: file) => {
                    if (!file.isDeleted) {
                        file.key = await worker.decryptB64(
                            file.encryptedKey,
                            file.keyDecryptionNonce,
                            collection.key
                        );
                        file.metadata = await worker.decryptMetadata(file);
                    }
                    return file;
                })
            );

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
        } while (resp.data.diff.length === limit);
        return await Promise.all(promises);
    } catch (e) {
        console.error('Get files failed', e);
    }
};

const removeDeletedCollectionFiles = async (
    collections: collection[],
    files: file[]
) => {
    const syncedCollectionIds = new Set<number>();
    for (let collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

export const deleteFiles = async (clickedFiles: selectedState) => {
    try {
        let filesToDelete = [];
        for (let [key, val] of Object.entries(clickedFiles)) {
            if (typeof val === 'boolean' && val) {
                filesToDelete.push(Number(key));
            }
        }
        const token = getToken();
        if (!token) {
            throw new Error('Invalid token');
        }
        await HTTPService.post(
            `${ENDPOINT}/files/delete`,
            { fileIDs: filesToDelete },
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        console.error('delete failed');
    }
};
