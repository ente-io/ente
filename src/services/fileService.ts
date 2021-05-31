import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import localForage from 'utils/storage/localForage';

import { Collection } from './collectionService';
import { DataStream, MetadataObject } from './uploadService';
import CryptoWorker from 'utils/crypto';
import { getToken } from 'utils/common/key';
import { selectedState } from 'pages/gallery';
import { ErrorHandler } from 'utils/common/errorUtil';

const ENDPOINT = getEndpoint();
const DIFF_LIMIT: number = 2500;

const FILES = 'files';

export interface fileAttribute {
    encryptedData?: DataStream | Uint8Array;
    objectKey?: string;
    decryptionHeader: string;
}

export interface File {
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

export const getLocalFiles = async () => {
    let files: Array<File> = (await localForage.getItem<File[]>(FILES)) || [];
    return files;
};

export const syncFiles = async (collections: Collection[]) => {
    const localFiles = await getLocalFiles();
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    if (files.length !== localFiles.length) {
        await localForage.setItem('files', files);
    }
    for (let collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime =
            (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }
        const fetchedFiles = (await getFiles(collection, lastSyncTime, DIFF_LIMIT)) ?? [];
        files.push(...fetchedFiles);
        var latestVersionFiles = new Map<string, File>();
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
    return {
        files: files.map((item) => ({
            ...item,
            w: window.innerWidth,
            h: window.innerHeight,
        })),
    };
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    limit: number
): Promise<File[]> => {
    try {
        const worker = await new CryptoWorker();
        const decryptedFiles: File[] = [];
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

            decryptedFiles.push(
                ...(await Promise.all(
                    resp.data.diff.map(async (file: File) => {
                        if (!file.isDeleted) {
                            file.key = await worker.decryptB64(
                                file.encryptedKey,
                                file.keyDecryptionNonce,
                                collection.key
                            );
                            file.metadata = await worker.decryptMetadata(file);
                        }
                        return file;
                    }) as Promise<File>[]
                ))
            );

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
        } while (resp.data.diff.length === limit);
        return decryptedFiles;
    } catch (e) {
        console.error('Get files failed', e);
        ErrorHandler(e);
    }
};

const removeDeletedCollectionFiles = async (
    collections: Collection[],
    files: File[]
) => {
    const syncedCollectionIds = new Set<number>();
    for (let collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

export const deleteFiles = async (
    filesToDelete: number[],
    clearSelection: Function,
    syncWithRemote: Function
) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        await HTTPService.post(
            `${ENDPOINT}/files/delete`,
            { fileIDs: filesToDelete },
            null,
            {
                'X-Auth-Token': token,
            }
        );
        clearSelection();
        syncWithRemote();
    } catch (e) {
        console.error('delete failed');
    }
};
