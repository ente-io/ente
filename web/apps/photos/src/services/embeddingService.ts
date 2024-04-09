import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import type {
    Embedding,
    EmbeddingModel,
    EncryptedEmbedding,
    GetEmbeddingDiffResponse,
    PutEmbeddingRequest,
} from "types/embedding";
import { EnteFile } from "types/file";
import { getLatestVersionEmbeddings } from "utils/embedding";
import { getLocalCollections } from "./collectionService";
import { getAllLocalFiles } from "./fileService";
import { getLocalTrashedFiles } from "./trashService";

const ENDPOINT = getEndpoint();

const DIFF_LIMIT = 500;

const EMBEDDINGS_TABLE_V1 = "embeddings";
const EMBEDDINGS_TABLE = "embeddings_v2";
const EMBEDDING_SYNC_TIME_TABLE = "embedding_sync_time";

export const getAllLocalEmbeddings = async () => {
    const embeddings: Array<Embedding> =
        await localForage.getItem<Embedding[]>(EMBEDDINGS_TABLE);
    if (!embeddings) {
        await localForage.removeItem(EMBEDDINGS_TABLE_V1);
        await localForage.removeItem(EMBEDDING_SYNC_TIME_TABLE);
        await localForage.setItem(EMBEDDINGS_TABLE, []);
        return [];
    }
    return embeddings;
};

export const getLocalEmbeddings = async () => {
    const embeddings = await getAllLocalEmbeddings();
    return embeddings.filter((embedding) => embedding.model === "onnx-clip");
};

const getModelEmbeddingSyncTime = async (model: EmbeddingModel) => {
    return (
        (await localForage.getItem<number>(
            `${model}-${EMBEDDING_SYNC_TIME_TABLE}`,
        )) ?? 0
    );
};

const setModelEmbeddingSyncTime = async (
    model: EmbeddingModel,
    time: number,
) => {
    await localForage.setItem(`${model}-${EMBEDDING_SYNC_TIME_TABLE}`, time);
};

export const syncEmbeddings = async () => {
    const models: EmbeddingModel[] = ["onnx-clip"];
    try {
        let allEmbeddings = await getAllLocalEmbeddings();
        const localFiles = await getAllLocalFiles();
        const hiddenAlbums = await getLocalCollections("hidden");
        const localTrashFiles = await getLocalTrashedFiles();
        const fileIdToKeyMap = new Map<number, string>();
        const allLocalFiles = [...localFiles, ...localTrashFiles];
        allLocalFiles.forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        await cleanupDeletedEmbeddings(allLocalFiles, allEmbeddings);
        log.info(`Syncing embeddings localCount: ${allEmbeddings.length}`);
        for (const model of models) {
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
                            const {
                                encryptedEmbedding,
                                decryptionHeader,
                                ...rest
                            } = embedding;
                            const worker =
                                await ComlinkCryptoWorker.getInstance();
                            const fileKey = fileIdToKeyMap.get(
                                embedding.fileID,
                            );
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
                if (response.diff.length) {
                    modelLastSinceTime = response.diff.slice(-1)[0].updatedAt;
                }
                await localForage.setItem(EMBEDDINGS_TABLE, allEmbeddings);
                await setModelEmbeddingSyncTime(model, modelLastSinceTime);
                log.info(
                    `Syncing embeddings syncedEmbeddingsCount: ${allEmbeddings.length}`,
                );
            } while (response.diff.length === DIFF_LIMIT);
        }
    } catch (e) {
        log.error("Sync embeddings failed", e);
    }
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
            `${ENDPOINT}/embeddings/diff`,
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
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.put(
            `${ENDPOINT}/embeddings`,
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
    allLocalEmbeddings: Embedding[],
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
        await localForage.setItem(EMBEDDINGS_TABLE, remainingEmbeddings);
    }
};
