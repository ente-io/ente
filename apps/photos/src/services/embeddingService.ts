import { Embedding, GetEmbeddingDiffResponse } from 'types/embedding';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { getEndpoint } from 'utils/common/apiUtil';
import { addLogLine } from 'utils/logging';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import { getLocalFiles } from './fileService';
import HTTPService from './HTTPService';
import { getToken } from 'utils/common/key';

const ENDPOINT = getEndpoint();

const DIFF_LIMIT = 500;

const EMBEDDINGS_TABLE = 'embeddings';
const EMBEDDING_SYNC_TIME_TABLE = 'embedding_sync_time';

const getLocalEmbeddings = async () => {
    const entities: Array<Embedding> =
        (await localForage.getItem<Embedding[]>(EMBEDDINGS_TABLE)) || [];
    return entities;
};

const getEmbeddingSyncTime = async () => {
    return (await localForage.getItem<number>(EMBEDDING_SYNC_TIME_TABLE)) ?? 0;
};

export const getLatestEmbeddings = async () => {
    try {
        await runEmbeddingsSync();
        return await getLocalEmbeddings();
    } catch (e) {
        logError(e, 'failed to get latest embeddings');
        throw e;
    }
};

let syncInProgress: Promise<void> = null;

export const runEmbeddingsSync = async () => {
    if (syncInProgress) {
        return syncInProgress;
    }
    syncInProgress = syncEmbeddings();
    return syncInProgress;
};

const syncEmbeddings = async () => {
    try {
        if (syncInProgress) {
            return syncInProgress;
        }
        let embeddings = await getLocalEmbeddings();
        const localFiles = await getLocalFiles();
        const fileIdToKeyMap = new Map<number, string>();
        localFiles.forEach((file) => {
            fileIdToKeyMap.set(file.id, file.key);
        });
        addLogLine(`Syncing embeddings localCount: ${embeddings.length}`);
        let sinceTime = await getEmbeddingSyncTime();
        addLogLine(`Syncing embeddings sinceTime: ${sinceTime}`);
        let response: GetEmbeddingDiffResponse;
        do {
            response = await getEmbeddingsDiff(sinceTime);
            if (response.diff?.length) {
                return;
            }
            const newEmbeddings = await Promise.all(
                response.diff.map(async (embedding) => {
                    const { encryptedEmbedding, decryptionHeader, ...rest } =
                        embedding;
                    const worker = await ComlinkCryptoWorker.getInstance();
                    const decryptedData = await worker.decryptEmbedding(
                        encryptedEmbedding,
                        decryptionHeader,
                        fileIdToKeyMap.get(embedding.fileID)
                    );

                    return {
                        ...rest,
                        embedding: decryptedData,
                    } as Embedding;
                })
            );
            embeddings = [...embeddings, ...newEmbeddings];
            if (response.diff.length) {
                sinceTime = response.diff.slice(-1)[0].updatedAt;
            }
            await localForage.setItem(EMBEDDINGS_TABLE, newEmbeddings);
            await localForage.setItem(EMBEDDING_SYNC_TIME_TABLE, sinceTime);
            addLogLine(
                `Syncing embeddings syncedEmbeddingsCount: ${newEmbeddings.length}`
            );
        } while (response.diff.length === DIFF_LIMIT);
    } catch (e) {
        logError(e, 'Sync embeddings failed');
    } finally {
        syncInProgress = null;
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
