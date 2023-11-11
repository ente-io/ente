import {
    Embedding,
    EncryptedEmbedding,
    GetEmbeddingDiffResponse,
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

const ENDPOINT = getEndpoint();

const DIFF_LIMIT = 500;

const EMBEDDINGS_TABLE = 'embeddings';
const EMBEDDING_SYNC_TIME_TABLE = 'embedding_sync_time';

export const getLocalEmbeddings = async () => {
    const embeddings: Array<Embedding> =
        (await localForage.getItem<Embedding[]>(EMBEDDINGS_TABLE)) || [];
    return embeddings;
};

const getEmbeddingSyncTime = async () => {
    return (await localForage.getItem<number>(EMBEDDING_SYNC_TIME_TABLE)) ?? 0;
};

export const getLatestEmbeddings = async () => {
    await syncEmbeddings();
    const embeddings = await getLocalEmbeddings();
    return embeddings;
};

export const syncEmbeddings = async () => {
    try {
        let embeddings = await getLocalEmbeddings();
        const localFiles = await getAllLocalFiles();
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
            response = await getEmbeddingsDiff(sinceTime);
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
                            throw Error('File key not found');
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
                        logError(e, 'decryptEmbedding failed for file');
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
                `Syncing embeddings syncedEmbeddingsCount: ${newEmbeddings.length}`
            );
        } while (response.diff.length === DIFF_LIMIT);
        void cleanupDeletedEmbeddings();
    } catch (e) {
        logError(e, 'Sync embeddings failed');
    }
};

export const getEmbeddingsDiff = async (
    sinceTime: number
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
    const embeddings = await getLocalEmbeddings();

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
