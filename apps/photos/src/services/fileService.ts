import { getEndpoint } from 'utils/common/apiUtil';
import localForage from 'utils/storage/localForage';

import { getToken } from 'utils/common/key';
import { Collection } from 'types/collection';
import HTTPService from './HTTPService';
import { logError } from 'utils/sentry';
import {
    decryptFile,
    getLatestVersionFiles,
    mergeMetadata,
    sortFiles,
} from 'utils/file';
import { eventBus, Events } from './events';
import { EnteFile, EncryptedEnteFile, TrashRequest } from 'types/file';
import { SetFiles } from 'types/gallery';
import { BulkUpdateMagicMetadataRequest } from 'types/magicMetadata';
import { addLogLine } from 'utils/logging';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import {
    getCollectionLastSyncTime,
    setCollectionLastSyncTime,
} from './collectionService';
import { REQUEST_BATCH_SIZE } from 'constants/api';
import { batch } from 'utils/common';

const ENDPOINT = getEndpoint();
const FILES_TABLE = 'files';
const HIDDEN_FILES_TABLE = 'hidden-files';

export const getLocalFiles = async () => {
    const files: Array<EnteFile> =
        (await localForage.getItem<EnteFile[]>(FILES_TABLE)) || [];
    return files;
};

export const getLocalHiddenFiles = async () => {
    const files: Array<EnteFile> =
        (await localForage.getItem<EnteFile[]>(HIDDEN_FILES_TABLE)) || [];
    return files;
};

const setLocalFiles = async (files: EnteFile[]) => {
    try {
        await localForage.setItem(FILES_TABLE, files);
        try {
            eventBus.emit(Events.LOCAL_FILES_UPDATED);
        } catch (e) {
            logError(e, 'Error in localFileUpdated handlers');
        }
    } catch (e1) {
        try {
            const storageEstimate = await navigator.storage.estimate();
            logError(e1, 'failed to save files to indexedDB', {
                storageEstimate,
            });
            addLogLine(`storage estimate ${JSON.stringify(storageEstimate)}`);
        } catch (e2) {
            logError(e1, 'failed to save files to indexedDB');
            logError(e2, 'failed to get storage stats');
        }
        throw e1;
    }
};

const setLocalHiddenFiles = async (files: EnteFile[]) => {
    try {
        await localForage.setItem(HIDDEN_FILES_TABLE, files);
    } catch (e1) {
        try {
            const storageEstimate = await navigator.storage.estimate();
            logError(e1, 'failed to save files to indexedDB', {
                storageEstimate,
            });
            addLogLine(`storage estimate ${JSON.stringify(storageEstimate)}`);
        } catch (e2) {
            logError(e1, 'failed to save files to indexedDB');
            logError(e2, 'failed to get storage stats');
        }
        throw e1;
    }
};

export const syncHiddenFiles = async (
    collections: Collection[],
    setFiles: SetFiles
) => {
    return await syncFilesHelper(collections, setFiles, 'hidden');
};

export const syncFiles = async (
    collections: Collection[],
    setFiles: SetFiles
) => {
    return await syncFilesHelper(collections, setFiles, 'normal');
};

const syncFilesHelper = async (
    collections: Collection[],
    setFiles: SetFiles,
    type: 'normal' | 'hidden'
) => {
    const localFiles =
        type === 'normal' ? await getLocalFiles() : await getLocalHiddenFiles();
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    if (files.length !== localFiles.length) {
        type === 'normal'
            ? await setLocalFiles(files)
            : await setLocalHiddenFiles(files);
        setFiles(sortFiles(mergeMetadata(files)));
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime = await getCollectionLastSyncTime(collection);
        if (collection.updationTime === lastSyncTime) {
            continue;
        }

        const newFiles = await getFiles(collection, lastSyncTime, setFiles);
        files = getLatestVersionFiles([...files, ...newFiles]);
        type === 'normal'
            ? await setLocalFiles(files)
            : await setLocalHiddenFiles(files);
        setCollectionLastSyncTime(collection, collection.updationTime);
    }
    return files;
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    setFiles: SetFiles
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                `${ENDPOINT}/collections/v2/diff`,
                {
                    collectionID: collection.id,
                    sinceTime: time,
                },
                {
                    'X-Auth-Token': token,
                }
            );

            const newDecryptedFilesBatch = await Promise.all(
                resp.data.diff.map(async (file: EncryptedEnteFile) => {
                    if (!file.isDeleted) {
                        return await decryptFile(file, collection.key);
                    } else {
                        return file;
                    }
                }) as Promise<EnteFile>[]
            );
            decryptedFiles = [...decryptedFiles, ...newDecryptedFilesBatch];

            setFiles((files) =>
                sortFiles(
                    mergeMetadata(
                        getLatestVersionFiles([
                            ...(files || []),
                            ...decryptedFiles,
                        ])
                    )
                )
            );
            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        logError(e, 'Get files failed');
        throw e;
    }
};

const removeDeletedCollectionFiles = async (
    collections: Collection[],
    files: EnteFile[]
) => {
    const syncedCollectionIds = new Set<number>();
    for (const collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

export const trashFiles = async (filesToTrash: EnteFile[]) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const batchedFilesToTrash = batch(filesToTrash, REQUEST_BATCH_SIZE);
        for (const batch of batchedFilesToTrash) {
            const trashRequest: TrashRequest = {
                items: batch.map((file) => ({
                    fileID: file.id,
                    collectionID: file.collectionID,
                })),
            };
            await HTTPService.post(
                `${ENDPOINT}/files/trash`,
                trashRequest,
                null,
                {
                    'X-Auth-Token': token,
                }
            );
        }
    } catch (e) {
        logError(e, 'trash file failed');
        throw e;
    }
};

export const deleteFromTrash = async (filesToDelete: number[]) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const batchedFilesToDelete = batch(filesToDelete, REQUEST_BATCH_SIZE);

        for (const batch of batchedFilesToDelete) {
            await HTTPService.post(
                `${ENDPOINT}/trash/delete`,
                { fileIDs: batch },
                null,
                {
                    'X-Auth-Token': token,
                }
            );
        }
    } catch (e) {
        logError(e, 'deleteFromTrash failed');
        throw e;
    }
};

export const updateFileMagicMetadata = async (files: EnteFile[]) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    for (const file of files) {
        const { file: encryptedMagicMetadata } =
            await cryptoWorker.encryptMetadata(
                file.magicMetadata.data,
                file.key
            );
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: file.magicMetadata.version,
                count: file.magicMetadata.count,
                data: encryptedMagicMetadata.encryptedData,
                header: encryptedMagicMetadata.decryptionHeader,
            },
        });
    }
    await HTTPService.put(`${ENDPOINT}/files/magic-metadata`, reqBody, null, {
        'X-Auth-Token': token,
    });
    return files.map(
        (file): EnteFile => ({
            ...file,
            magicMetadata: {
                ...file.magicMetadata,
                version: file.magicMetadata.version + 1,
            },
        })
    );
};

export const updateFilePublicMagicMetadata = async (files: EnteFile[]) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    for (const file of files) {
        const { file: encryptedPubMagicMetadata } =
            await cryptoWorker.encryptMetadata(
                file.pubMagicMetadata.data,
                file.key
            );
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: file.pubMagicMetadata.version,
                count: file.pubMagicMetadata.count,
                data: encryptedPubMagicMetadata.encryptedData,
                header: encryptedPubMagicMetadata.decryptionHeader,
            },
        });
    }
    await HTTPService.put(
        `${ENDPOINT}/files/public-magic-metadata`,
        reqBody,
        null,
        {
            'X-Auth-Token': token,
        }
    );
    return files.map(
        (file): EnteFile => ({
            ...file,
            pubMagicMetadata: {
                ...file.pubMagicMetadata,
                version: file.pubMagicMetadata.version + 1,
            },
        })
    );
};
