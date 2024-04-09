import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { Events, eventBus } from "@ente/shared/events";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { REQUEST_BATCH_SIZE } from "constants/api";
import { Collection } from "types/collection";
import {
    EncryptedEnteFile,
    EnteFile,
    FileWithUpdatedMagicMetadata,
    FileWithUpdatedPublicMagicMetadata,
    TrashRequest,
} from "types/file";
import { SetFiles } from "types/gallery";
import { BulkUpdateMagicMetadataRequest } from "types/magicMetadata";
import { batch } from "utils/common";
import {
    decryptFile,
    getLatestVersionFiles,
    mergeMetadata,
    sortFiles,
} from "utils/file";
import {
    getCollectionLastSyncTime,
    setCollectionLastSyncTime,
} from "./collectionService";

const ENDPOINT = getEndpoint();
const FILES_TABLE = "files";
const HIDDEN_FILES_TABLE = "hidden-files";

export const getLocalFiles = async (type: "normal" | "hidden" = "normal") => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    const files: Array<EnteFile> =
        (await localForage.getItem<EnteFile[]>(tableName)) || [];
    return files;
};

const setLocalFiles = async (type: "normal" | "hidden", files: EnteFile[]) => {
    try {
        const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
        await localForage.setItem(tableName, files);
        try {
            eventBus.emit(Events.LOCAL_FILES_UPDATED);
        } catch (e) {
            log.error("Error in localFileUpdated handlers", e);
        }
    } catch (e1) {
        try {
            const storageEstimate = await navigator.storage.estimate();
            log.error(
                `failed to save files to indexedDB (storageEstimate was ${storageEstimate}`,
                e1,
            );
            log.info(`storage estimate ${JSON.stringify(storageEstimate)}`);
        } catch (e2) {
            log.error("failed to save files to indexedDB", e1);
            log.error("failed to get storage stats", e2);
        }
        throw e1;
    }
};

export const getAllLocalFiles = async () => {
    const normalFiles = await getLocalFiles("normal");
    const hiddenFiles = await getLocalFiles("hidden");
    return [...normalFiles, ...hiddenFiles];
};

export const syncFiles = async (
    type: "normal" | "hidden",
    collections: Collection[],
    setFiles: SetFiles,
) => {
    const localFiles = await getLocalFiles(type);
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    if (files.length !== localFiles.length) {
        await setLocalFiles(type, files);
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
        await setLocalFiles(type, files);
        setCollectionLastSyncTime(collection, collection.updationTime);
    }
    return files;
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    setFiles: SetFiles,
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
                    "X-Auth-Token": token,
                },
            );

            const newDecryptedFilesBatch = await Promise.all(
                resp.data.diff.map(async (file: EncryptedEnteFile) => {
                    if (!file.isDeleted) {
                        return await decryptFile(file, collection.key);
                    } else {
                        return file;
                    }
                }) as Promise<EnteFile>[],
            );
            decryptedFiles = [...decryptedFiles, ...newDecryptedFilesBatch];

            setFiles((files) =>
                sortFiles(
                    mergeMetadata(
                        getLatestVersionFiles([
                            ...(files || []),
                            ...decryptedFiles,
                        ]),
                    ),
                ),
            );
            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get files failed", e);
        throw e;
    }
};

const removeDeletedCollectionFiles = async (
    collections: Collection[],
    files: EnteFile[],
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
                    "X-Auth-Token": token,
                },
            );
        }
    } catch (e) {
        log.error("trash file failed", e);
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
                    "X-Auth-Token": token,
                },
            );
        }
    } catch (e) {
        log.error("deleteFromTrash failed", e);
        throw e;
    }
};

export const updateFileMagicMetadata = async (
    fileWithUpdatedMagicMetadataList: FileWithUpdatedMagicMetadata[],
) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    for (const {
        file,
        updatedMagicMetadata,
    } of fileWithUpdatedMagicMetadataList) {
        const { file: encryptedMagicMetadata } =
            await cryptoWorker.encryptMetadata(
                updatedMagicMetadata.data,
                file.key,
            );
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatedMagicMetadata.version,
                count: updatedMagicMetadata.count,
                data: encryptedMagicMetadata.encryptedData,
                header: encryptedMagicMetadata.decryptionHeader,
            },
        });
    }
    await HTTPService.put(`${ENDPOINT}/files/magic-metadata`, reqBody, null, {
        "X-Auth-Token": token,
    });
    return fileWithUpdatedMagicMetadataList.map(
        ({ file, updatedMagicMetadata }): EnteFile => ({
            ...file,
            magicMetadata: {
                ...updatedMagicMetadata,
                version: updatedMagicMetadata.version + 1,
            },
        }),
    );
};

export const updateFilePublicMagicMetadata = async (
    fileWithUpdatedPublicMagicMetadataList: FileWithUpdatedPublicMagicMetadata[],
): Promise<EnteFile[]> => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    for (const {
        file,
        updatedPublicMagicMetadata: updatePublicMagicMetadata,
    } of fileWithUpdatedPublicMagicMetadataList) {
        const { file: encryptedPubMagicMetadata } =
            await cryptoWorker.encryptMetadata(
                updatePublicMagicMetadata.data,
                file.key,
            );
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatePublicMagicMetadata.version,
                count: updatePublicMagicMetadata.count,
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
            "X-Auth-Token": token,
        },
    );
    return fileWithUpdatedPublicMagicMetadataList.map(
        ({ file, updatedPublicMagicMetadata }): EnteFile => ({
            ...file,
            pubMagicMetadata: {
                ...updatedPublicMagicMetadata,
                version: updatedPublicMagicMetadata.version + 1,
            },
        }),
    );
};
