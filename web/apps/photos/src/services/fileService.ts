import { encryptMetadataJSON } from "@/base/crypto";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import type { Collection } from "@/media/collection";
import type { EncryptedMagicMetadata } from "@/media/file";
import {
    EncryptedEnteFile,
    EnteFile,
    FileWithUpdatedMagicMetadata,
    FileWithUpdatedPublicMagicMetadata,
    TrashRequest,
} from "@/media/file";
import { getLatestVersionFiles } from "@/new/photos/services/file";
import {
    clearCachedThumbnailsIfChanged,
    getLocalFiles,
    setLocalFiles,
} from "@/new/photos/services/files";
import { batch } from "@/utils/array";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import exportService from "services/export";
import { decryptFile } from "utils/file";
import {
    getCollectionLastSyncTime,
    REQUEST_BATCH_SIZE,
    setCollectionLastSyncTime,
} from "./collectionService";

/**
 * Fetch all files of the given {@link type}, belonging to the given
 * {@link collections}, from remote and update our local database.
 *
 * If this is the initial read, or if the count of files we have differs from
 * the state of the local database (these two are expected to be the same case),
 * then the {@link onResetFiles} callback is invoked to give the caller a chance
 * to bring its state up to speed.
 *
 * In addition to updating the local database, it also calls the provided
 * {@link onFetchFiles} callback with the latest decrypted files after each
 * batch the new and/or updated files are received from remote.
 */
export const syncFiles = async (
    type: "normal" | "hidden",
    collections: Collection[],
    onResetFiles: (fs: EnteFile[]) => void,
    onFetchFiles: (fs: EnteFile[]) => void,
) => {
    const localFiles = await getLocalFiles(type);
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    let didUpdateFiles = false;
    if (files.length !== localFiles.length) {
        await setLocalFiles(type, files);
        onResetFiles(files);
        didUpdateFiles = true;
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime = await getCollectionLastSyncTime(collection);
        if (collection.updationTime === lastSyncTime) {
            continue;
        }

        const newFiles = await getFiles(collection, lastSyncTime, onFetchFiles);
        await clearCachedThumbnailsIfChanged(localFiles, newFiles);
        files = getLatestVersionFiles([...files, ...newFiles]);
        await setLocalFiles(type, files);
        didUpdateFiles = true;
        setCollectionLastSyncTime(collection, collection.updationTime);
    }
    if (didUpdateFiles) exportService.onLocalFilesUpdated();
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    onFetchFiles: (fs: EnteFile[]) => void,
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
                await apiURL("/collections/v2/diff"),
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

            onFetchFiles(decryptedFiles);
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
                await apiURL("/files/trash"),
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
                await apiURL("/trash/delete"),
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

export interface UpdateMagicMetadataRequest {
    id: number;
    magicMetadata: EncryptedMagicMetadata;
}

export interface BulkUpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

export const updateFileMagicMetadata = async (
    fileWithUpdatedMagicMetadataList: FileWithUpdatedMagicMetadata[],
) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: BulkUpdateMagicMetadataRequest = { metadataList: [] };
    for (const {
        file,
        updatedMagicMetadata,
    } of fileWithUpdatedMagicMetadataList) {
        const { encryptedDataB64, decryptionHeaderB64 } =
            await encryptMetadataJSON({
                jsonValue: updatedMagicMetadata.data,
                keyB64: file.key,
            });
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatedMagicMetadata.version,
                count: updatedMagicMetadata.count,
                data: encryptedDataB64,
                header: decryptionHeaderB64,
            },
        });
    }
    await HTTPService.put(
        await apiURL("/files/magic-metadata"),
        reqBody,
        null,
        {
            "X-Auth-Token": token,
        },
    );
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
    for (const {
        file,
        updatedPublicMagicMetadata,
    } of fileWithUpdatedPublicMagicMetadataList) {
        const { encryptedDataB64, decryptionHeaderB64 } =
            await encryptMetadataJSON({
                jsonValue: updatedPublicMagicMetadata.data,
                keyB64: file.key,
            });
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: {
                version: updatedPublicMagicMetadata.version,
                count: updatedPublicMagicMetadata.count,
                data: encryptedDataB64,
                header: decryptionHeaderB64,
            },
        });
    }
    await HTTPService.put(
        await apiURL("/files/public-magic-metadata"),
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
