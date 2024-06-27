import { getLocalFiles, setLocalFiles } from "@/new/photos/services/files";
import {
    EncryptedEnteFile,
    EnteFile,
    FileWithUpdatedMagicMetadata,
    FileWithUpdatedPublicMagicMetadata,
    TrashRequest,
} from "@/new/photos/types/file";
import { BulkUpdateMagicMetadataRequest } from "@/new/photos/types/magicMetadata";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { REQUEST_BATCH_SIZE } from "constants/api";
import { Collection } from "types/collection";
import { SetFiles } from "types/gallery";
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
