import { getEndpoint } from 'utils/common/apiUtil';
import localForage from 'utils/storage/localForage';

import CryptoWorker from 'utils/crypto';
import { getToken } from 'utils/common/key';
import { ErrorHandler } from 'utils/common/errorUtil';
import { DataStream, MetadataObject } from './uploadService';
import { Collection } from './collectionService';
import HTTPService from './HTTPService';

const ENDPOINT = getEndpoint();
const DIFF_LIMIT: number = 250;

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
    const files: Array<File> = (await localForage.getItem<File[]>(FILES)) || [];
    return files;
};

export const syncFiles = async (collections: Collection[], setFiles: (files: File[]) => void) => {
    const localFiles = await getLocalFiles();
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    if (files.length !== localFiles.length) {
        await localForage.setItem('files', files);
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime = (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }
        const fetchedFiles = (await getFiles(collection, lastSyncTime, DIFF_LIMIT, files, setFiles)) ?? [];
        files.push(...fetchedFiles);
        const latestVersionFiles = new Map<string, File>();
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
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        for (const [_, file] of latestVersionFiles) {
            if (file.isDeleted) {
                continue;
            }
            files.push(file);
        }
        // sort according to modification time first
        files = files.sort((a, b) => {
            if (!b.metadata?.modificationTime) {
                return -1;
            }
            if (!a.metadata?.modificationTime) {
                return 1;
            } else {
                return b.metadata.modificationTime - a.metadata.modificationTime;
            }
        });

        // then sort according to creation time, maintaining ordering according to modification time for files with creation time
        files = files.map((file, index) => ({ index, file })).sort((a, b) => {
            let diff = b.file.metadata.creationTime - a.file.metadata.creationTime;
            if (diff === 0) {
                diff = a.index - b.index;
            }
            return diff;
        }).map((file) => file.file);
        await localForage.setItem('files', files);
        await localForage.setItem(
            `${collection.id}-time`,
            collection.updationTime,
        );
        setFiles(files.map((item) => ({
            ...item,
            w: window.innerWidth,
            h: window.innerHeight,
        })));
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
    limit: number,
    files: File[],
    setFiles: (files: File[]) => void,
): Promise<File[]> => {
    try {
        const worker = await new CryptoWorker();
        const decryptedFiles: File[] = [];
        let time = sinceTime ||
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
                    limit,
                },
                {
                    'X-Auth-Token': token,
                },
            );

            decryptedFiles.push(
                ...(await Promise.all(
                    resp.data.diff.map(async (file: File) => {
                        if (!file.isDeleted) {
                            file.key = await worker.decryptB64(
                                file.encryptedKey,
                                file.keyDecryptionNonce,
                                collection.key,
                            );
                            file.metadata = await worker.decryptMetadata(file);
                        }
                        return file;
                    }) as Promise<File>[],
                )),
            );

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setFiles([...(files || []), ...decryptedFiles].filter((item) => !item.isDeleted).sort(
                (a, b) => b.metadata.creationTime - a.metadata.creationTime,
            ));
        } while (resp.data.diff.length === limit);
        return decryptedFiles;
    } catch (e) {
        console.error('Get files failed', e.message);
        ErrorHandler(e);
    }
};

const removeDeletedCollectionFiles = async (
    collections: Collection[],
    files: File[],
) => {
    const syncedCollectionIds = new Set<number>();
    for (const collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

export const deleteFiles = async (
    filesToDelete: number[],
    clearSelection: Function,
    syncWithRemote: Function,
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
            },
        );
        clearSelection();
        syncWithRemote();
    } catch (e) {
        console.error('delete failed', e.message);
        throw e;
    }
};
