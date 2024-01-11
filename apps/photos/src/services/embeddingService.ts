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

const ENDPOINT = getEndpoint();

const DIFF_LIMIT = 500;

const EMBEDDINGS_TABLE_V1 = 'embeddings';
const EMBEDDINGS_TABLE = 'embeddings_v2';
const EMBEDDING_SYNC_TIME_TABLE = 'embedding_sync_time';

export const getAllLocalEmbeddings = async () => {
    const embeddings: Array<Embedding> =
        (await localForage.getItem<Embedding[]>(EMBEDDINGS_TABLE)) ?? [];
    if (!embeddings) {
        await localForage.removeItem(EMBEDDINGS_TABLE_V1);
        await localForage.setItem(EMBEDDINGS_TABLE, []);
        await localForage.setItem(EMBEDDING_SYNC_TIME_TABLE, 0);
        return [];
    }
    return embeddings;
};

export const getLocalEmbeddings = async (model: Model) => {
    const embeddings = await getAllLocalEmbeddings();
    return embeddings.filter((embedding) => embedding.model === model);
};

const getEmbeddingSyncTime = async () => {
    return (await localForage.getItem<number>(EMBEDDING_SYNC_TIME_TABLE)) ?? 0;
};

export const syncEmbeddings = async (model: Model = Model.ONNX_CLIP) => {
    try {
        let embeddings = await getAllLocalEmbeddings();
        const localFiles = await getAllLocalFiles();
        const hiddenAlbums = await getLocalCollections('hidden');
        const localTrashFiles = await getLocalTrashedFiles();
        const fileIdToKeyMap = new Map<number, string>();
        [...localFiles, ...localTrashFiles].forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        addLogLine(`Syncing embeddings localCount: ${embeddings.length}`);
        let sinceTime = await getEmbeddingSyncTime();
        addLogLine(`Syncing embeddings sinceTime: ${sinceTime}`);
        let response: GetEmbeddingDiffResponse;
        do {
            response = await getEmbeddingsDiff(sinceTime, model);
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
                        const worker = await ComlinkCryptoWorker.getInstance();
                        const fileKey = fileIdToKeyMap.get(embedding.fileID);
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
                            const hasHiddenAlbums = hiddenAlbums?.length > 0;
                            info = {
                                hasHiddenAlbums,
                            };
                        }
                        logError(e, 'decryptEmbedding failed for file', info);
                    }
                })
            );
            embeddings = getLatestVersionEmbeddings([
                ...embeddings,
                ...newEmbeddings,
            ]);
            if (response.diff.length) {
                sinceTime = response.diff.slice(-1)[0].updatedAt;
            }
            await localForage.setItem(EMBEDDINGS_TABLE, embeddings);
            await localForage.setItem(EMBEDDING_SYNC_TIME_TABLE, sinceTime);
            addLogLine(
                `Syncing embeddings syncedEmbeddingsCount: ${embeddings.length}`
            );
        } while (response.diff.length === DIFF_LIMIT);
        void cleanupDeletedEmbeddings();
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

export const cleanupDeletedEmbeddings = async () => {
    const files = await getAllLocalFiles();
    const trashedFiles = await getLocalTrashedFiles();
    const activeFileIds = new Set<number>();
    [...files, ...trashedFiles].forEach((file) => {
        activeFileIds.add(file.id);
    });
    const embeddings = await getAllLocalEmbeddings();

    const remainingEmbeddings = embeddings.filter((embedding) =>
        activeFileIds.has(embedding.fileID)
    );
    if (embeddings.length !== remainingEmbeddings.length) {
        addLogLine(
            `cleanupDeletedEmbeddings embeddingsCount: ${embeddings.length} remainingEmbeddingsCount: ${remainingEmbeddings.length}`
        );
        await localForage.setItem(EMBEDDINGS_TABLE, remainingEmbeddings);
    }
};
