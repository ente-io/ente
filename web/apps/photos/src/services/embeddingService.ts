import type { EmbeddingModel } from "@/new/photos/services/embedding";
import { getAllLocalFiles } from "@/new/photos/services/files";
import { EnteFile } from "@/new/photos/types/file";
import { inWorker } from "@/next/env";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import { workerBridge } from "@/next/worker/worker-bridge";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import type {
    Embedding,
    EncryptedEmbedding,
    GetEmbeddingDiffResponse,
    PutEmbeddingRequest,
} from "types/embedding";
import { getLocalCollections } from "./collectionService";
import type { FaceIndex } from "./face/types";
import { getLocalTrashedFiles } from "./trashService";

type FileML = FaceIndex & {
    updatedAt: number;
};
const DIFF_LIMIT = 500;

/** Local storage key suffix for embedding sync times */
const embeddingSyncTimeLSKeySuffix = "embedding_sync_time";
/** Local storage key for CLIP embeddings. */
const clipEmbeddingsLSKey = "embeddings_v2";
const FILE_EMBEDING_TABLE = "file_embeddings";

/** Return all CLIP embeddings that we have available locally. */
export const localCLIPEmbeddings = async () =>
    (await storedCLIPEmbeddings()).filter(({ model }) => model === "onnx-clip");

const storedCLIPEmbeddings = async () => {
    const embeddings: Array<Embedding> =
        await localForage.getItem<Embedding[]>(clipEmbeddingsLSKey);
    if (!embeddings) {
        // Migrate
        await localForage.removeItem("embeddings");
        await localForage.removeItem("embedding_sync_time");
        await localForage.setItem(clipEmbeddingsLSKey, []);
        return [];
    }
    return embeddings;
};

export const getFileMLEmbeddings = async (): Promise<FileML[]> => {
    const embeddings: Array<FileML> =
        await localForage.getItem<FileML[]>(FILE_EMBEDING_TABLE);
    if (!embeddings) {
        return [];
    }
    return embeddings;
};

const getModelEmbeddingSyncTime = async (model: EmbeddingModel) => {
    return (
        (await localForage.getItem<number>(
            `${model}-${embeddingSyncTimeLSKeySuffix}`,
        )) ?? 0
    );
};

const setModelEmbeddingSyncTime = async (
    model: EmbeddingModel,
    time: number,
) => {
    await localForage.setItem(`${model}-${embeddingSyncTimeLSKeySuffix}`, time);
};

/**
 * Fetch new CLIP embeddings with the server and save them locally. Also prune
 * local embeddings for any files no longer exist locally.
 */
export const syncCLIPEmbeddings = async () => {
    const model: EmbeddingModel = "onnx-clip";
    try {
        let allEmbeddings = await storedCLIPEmbeddings();
        const localFiles = await getAllLocalFiles();
        const hiddenAlbums = await getLocalCollections("hidden");
        const localTrashFiles = await getLocalTrashedFiles();
        const fileIdToKeyMap = new Map<number, string>();
        const allLocalFiles = [...localFiles, ...localTrashFiles];
        allLocalFiles.forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        await cleanupDeletedEmbeddings(
            allLocalFiles,
            allEmbeddings,
            clipEmbeddingsLSKey,
        );
        log.info(`Syncing embeddings localCount: ${allEmbeddings.length}`);

        let modelLastSinceTime = await getModelEmbeddingSyncTime(model);
        log.info(
            `Syncing ${model} model's embeddings sinceTime: ${modelLastSinceTime}`,
        );
        let response: GetEmbeddingDiffResponse;
        do {
            response = await getEmbeddingsDiff(modelLastSinceTime, model);
            if (!response.diff?.length) {
                return;
            }
            // Note: in rare cases we might get a diff entry for an embedding
            // corresponding to a file which has been deleted (but whose
            // embedding is enqueued for deletion). Client should expect such a
            // scenario (all it has to do is just ignore them).
            const newEmbeddings = await Promise.all(
                response.diff.map(async (embedding) => {
                    try {
                        const {
                            encryptedEmbedding,
                            decryptionHeader,
                            ...rest
                        } = embedding;
                        const worker = await ComlinkCryptoWorker.getInstance();
                        const fileKey = fileIdToKeyMap.get(embedding.fileID);
                        if (!fileKey) {
                            throw Error(CustomError.FILE_NOT_FOUND);
                        }
                        const decryptedData = await worker.decryptEmbedding(
                            encryptedEmbedding,
                            decryptionHeader,
                            fileIdToKeyMap.get(embedding.fileID),
                        );

                        return {
                            ...rest,
                            embedding: decryptedData,
                        } as Embedding;
                    } catch (e) {
                        let hasHiddenAlbums = false;
                        if (e.message === CustomError.FILE_NOT_FOUND) {
                            hasHiddenAlbums = hiddenAlbums?.length > 0;
                        }
                        log.error(
                            `decryptEmbedding failed for file (hasHiddenAlbums: ${hasHiddenAlbums})`,
                            e,
                        );
                    }
                }),
            );
            allEmbeddings = getLatestVersionEmbeddings([
                ...allEmbeddings,
                ...newEmbeddings,
            ]);
            modelLastSinceTime = response.diff.reduce(
                (max, { updatedAt }) => Math.max(max, updatedAt),
                modelLastSinceTime,
            );
            await localForage.setItem(clipEmbeddingsLSKey, allEmbeddings);
            await setModelEmbeddingSyncTime(model, modelLastSinceTime);
            log.info(
                `Syncing embeddings syncedEmbeddingsCount: ${allEmbeddings.length}`,
            );
        } while (response.diff.length > 0);
    } catch (e) {
        log.error("Sync embeddings failed", e);
    }
};

export const syncFaceEmbeddings = async () => {
    const model: EmbeddingModel = "file-ml-clip-face";
    try {
        let allEmbeddings: FileML[] = await getFileMLEmbeddings();
        const localFiles = await getAllLocalFiles();
        const hiddenAlbums = await getLocalCollections("hidden");
        const localTrashFiles = await getLocalTrashedFiles();
        const fileIdToKeyMap = new Map<number, string>();
        const allLocalFiles = [...localFiles, ...localTrashFiles];
        allLocalFiles.forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        await cleanupDeletedEmbeddings(
            allLocalFiles,
            allEmbeddings,
            FILE_EMBEDING_TABLE,
        );
        log.info(`Syncing embeddings localCount: ${allEmbeddings.length}`);

        let modelLastSinceTime = await getModelEmbeddingSyncTime(model);
        log.info(
            `Syncing ${model} model's embeddings sinceTime: ${modelLastSinceTime}`,
        );
        let response: GetEmbeddingDiffResponse;
        do {
            response = await getEmbeddingsDiff(modelLastSinceTime, model);
            if (!response.diff?.length) {
                return;
            }
            const newEmbeddings = await Promise.all(
                response.diff.map(async (embedding) => {
                    try {
                        const worker = await ComlinkCryptoWorker.getInstance();
                        const fileKey = fileIdToKeyMap.get(embedding.fileID);
                        if (!fileKey) {
                            throw Error(CustomError.FILE_NOT_FOUND);
                        }
                        const decryptedData = await worker.decryptMetadata(
                            embedding.encryptedEmbedding,
                            embedding.decryptionHeader,
                            fileIdToKeyMap.get(embedding.fileID),
                        );

                        return {
                            ...decryptedData,
                            updatedAt: embedding.updatedAt,
                        } as unknown as FileML;
                    } catch (e) {
                        let hasHiddenAlbums = false;
                        if (e.message === CustomError.FILE_NOT_FOUND) {
                            hasHiddenAlbums = hiddenAlbums?.length > 0;
                        }
                        log.error(
                            `decryptEmbedding failed for file (hasHiddenAlbums: ${hasHiddenAlbums})`,
                            e,
                        );
                    }
                }),
            );
            allEmbeddings = getLatestVersionFileEmbeddings([
                ...allEmbeddings,
                ...newEmbeddings,
            ]);
            modelLastSinceTime = response.diff.reduce(
                (max, { updatedAt }) => Math.max(max, updatedAt),
                modelLastSinceTime,
            );
            await localForage.setItem(FILE_EMBEDING_TABLE, allEmbeddings);
            await setModelEmbeddingSyncTime(model, modelLastSinceTime);
            log.info(
                `Syncing embeddings syncedEmbeddingsCount: ${allEmbeddings.length}`,
            );
        } while (response.diff.length > 0);
    } catch (e) {
        log.error("Sync embeddings failed", e);
    }
};

const getLatestVersionEmbeddings = (embeddings: Embedding[]) => {
    const latestVersionEntities = new Map<number, Embedding>();
    embeddings.forEach((embedding) => {
        if (!embedding?.fileID) {
            return;
        }
        const existingEmbeddings = latestVersionEntities.get(embedding.fileID);
        if (
            !existingEmbeddings ||
            existingEmbeddings.updatedAt < embedding.updatedAt
        ) {
            latestVersionEntities.set(embedding.fileID, embedding);
        }
    });
    return Array.from(latestVersionEntities.values());
};

const getLatestVersionFileEmbeddings = (embeddings: FileML[]) => {
    const latestVersionEntities = new Map<number, FileML>();
    embeddings.forEach((embedding) => {
        if (!embedding?.fileID) {
            return;
        }
        const existingEmbeddings = latestVersionEntities.get(embedding.fileID);
        if (
            !existingEmbeddings ||
            existingEmbeddings.updatedAt < embedding.updatedAt
        ) {
            latestVersionEntities.set(embedding.fileID, embedding);
        }
    });
    return Array.from(latestVersionEntities.values());
};

export const getEmbeddingsDiff = async (
    sinceTime: number,
    model: EmbeddingModel,
): Promise<GetEmbeddingDiffResponse> => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const response = await HTTPService.get(
            await apiURL("/embeddings/diff"),
            {
                sinceTime,
                limit: DIFF_LIMIT,
                model,
            },
            {
                "X-Auth-Token": token,
            },
        );
        return await response.data;
    } catch (e) {
        log.error("get embeddings diff failed", e);
        throw e;
    }
};

export const putEmbedding = async (
    putEmbeddingReq: PutEmbeddingRequest,
): Promise<EncryptedEmbedding> => {
    try {
        const token = inWorker()
            ? await workerBridge.getAuthToken()
            : getToken();
        if (!token) {
            log.info("putEmbedding failed: token not found");
            throw Error(CustomError.TOKEN_MISSING);
        }
        const resp = await HTTPService.put(
            await apiURL("/embeddings"),
            putEmbeddingReq,
            null,
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data;
    } catch (e) {
        log.error("put embedding failed", e);
        throw e;
    }
};

export const cleanupDeletedEmbeddings = async (
    allLocalFiles: EnteFile[],
    allLocalEmbeddings: Embedding[] | FileML[],
    tableName: string,
) => {
    const activeFileIds = new Set<number>();
    allLocalFiles.forEach((file) => {
        activeFileIds.add(file.id);
    });

    const remainingEmbeddings = allLocalEmbeddings.filter((embedding) =>
        activeFileIds.has(embedding.fileID),
    );
    if (allLocalEmbeddings.length !== remainingEmbeddings.length) {
        log.info(
            `cleanupDeletedEmbeddings embeddingsCount: ${allLocalEmbeddings.length} remainingEmbeddingsCount: ${remainingEmbeddings.length}`,
        );
        await localForage.setItem(tableName, remainingEmbeddings);
    }
};
