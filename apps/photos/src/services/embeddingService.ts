import {
    Embedding,
    EncryptedEmbedding,
    GetEmbeddingDiffResponse,
    Model,
    PutEmbeddingRequest,
} from 'types/embedding';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { getEndpoint } from '@ente/shared/network/api';
import { addLogLine } from '@ente/shared/logging';
import { logError } from '@ente/shared/sentry';
import localForage from '@ente/shared/storage/localForage';
import { getAllLocalFiles } from './fileService';
import HTTPService from '@ente/shared/network/HTTPService';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { getLatestVersionEmbeddings } from 'utils/embedding';
import { getLocalTrashedFiles } from './trashService';
import { getLocalCollections } from './collectionService';
import { CustomError } from '@ente/shared/error';
import { EnteFile } from 'types/file';

const ENDPOINT = getEndpoint();

const DIFF_LIMIT = 500;

const EMBEDDINGS_TABLE_V1 = 'embeddings';
const EMBEDDINGS_TABLE = 'embeddings_v2';
const EMBEDDING_SYNC_TIME_TABLE = 'embedding_sync_time';

export const getAllLocalEmbeddings = async () => {
    const embeddings: Array<Embedding> = await localForage.getItem<Embedding[]>(
        EMBEDDINGS_TABLE
    );
    if (!embeddings) {
        await localForage.removeItem(EMBEDDINGS_TABLE_V1);
        await localForage.removeItem(EMBEDDING_SYNC_TIME_TABLE);
        await localForage.setItem(EMBEDDINGS_TABLE, []);
        return [];
    }
    return embeddings;
};

export const getLocalEmbeddings = async (model: Model) => {
    const embeddings = await getAllLocalEmbeddings();
    return embeddings.filter((embedding) => embedding.model === model);
};

const getModelEmbeddingSyncTime = async (model: Model) => {
    return (
        (await localForage.getItem<number>(
            `${model}-${EMBEDDING_SYNC_TIME_TABLE}`
        )) ?? 0
    );
};

const setModelEmbeddingSyncTime = async (model: Model, time: number) => {
    await localForage.setItem(`${model}-${EMBEDDING_SYNC_TIME_TABLE}`, time);
};

export const syncEmbeddings = async (models: Model[] = [Model.ONNX_CLIP]) => {
    try {
        let allEmbeddings = await getAllLocalEmbeddings();
        const localFiles = await getAllLocalFiles();
        const hiddenAlbums = await getLocalCollections('hidden');
        const localTrashFiles = await getLocalTrashedFiles();
        const fileIdToKeyMap = new Map<number, string>();
        const allLocalFiles = [...localFiles, ...localTrashFiles];
        allLocalFiles.forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        await cleanupDeletedEmbeddings(allLocalFiles, allEmbeddings);
        addLogLine(`Syncing embeddings localCount: ${allEmbeddings.length}`);
        for (const model of models) {
            let modelLastSinceTime = await getModelEmbeddingSyncTime(model);
            addLogLine(
                `Syncing ${model} model's embeddings sinceTime: ${modelLastSinceTime}`
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
                                embedding.fileID
                            );
                            if (!fileKey) {
                                throw Error(CustomError.FILE_NOT_FOUND);
                            }
                            const decryptedData = await worker.decryptEmbedding(
                                encryptedEmbedding,
                                decryptionHeader,
                                fileIdToKeyMap.get(embedding.fileID)
                            );

                            return {
                                ...rest,
                                embedding: decryptedData,
                            } as Embedding;
                        } catch (e) {
                            let info: Record<string, unknown>;
                            if (e.message === CustomError.FILE_NOT_FOUND) {
                                const hasHiddenAlbums =
                                    hiddenAlbums?.length > 0;
                                info = {
                                    hasHiddenAlbums,
                                };
                            }
                            logError(
                                e,
                                'decryptEmbedding failed for file',
                                info
                            );
                        }
                    })
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
                addLogLine(
                    `Syncing embeddings syncedEmbeddingsCount: ${allEmbeddings.length}`
                );
            } while (response.diff.length === DIFF_LIMIT);
        }
    } catch (e) {
        logError(e, 'Sync embeddings failed');
    }
};

export const getEmbeddingsDiff = async (
    sinceTime: number,
    model: Model
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
                'X-Auth-Token': token,
            }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'get embeddings diff failed');
        throw e;
    }
};

export const putEmbedding = async (
    putEmbeddingReq: PutEmbeddingRequest
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
                'X-Auth-Token': token,
            }
        );
        return resp.data;
    } catch (e) {
        logError(e, 'put embedding failed');
        throw e;
    }
};

export const cleanupDeletedEmbeddings = async (
    allLocalFiles: EnteFile[],
    allLocalEmbeddings: Embedding[]
) => {
    const activeFileIds = new Set<number>();
    allLocalFiles.forEach((file) => {
        activeFileIds.add(file.id);
    });

    const remainingEmbeddings = allLocalEmbeddings.filter((embedding) =>
        activeFileIds.has(embedding.fileID)
    );
    if (allLocalEmbeddings.length !== remainingEmbeddings.length) {
        addLogLine(
            `cleanupDeletedEmbeddings embeddingsCount: ${allLocalEmbeddings.length} remainingEmbeddingsCount: ${remainingEmbeddings.length}`
        );
        await localForage.setItem(EMBEDDINGS_TABLE, remainingEmbeddings);
    }
};
