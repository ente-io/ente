import {
    Embedding,
    EncryptedEmbedding,
    GetEmbeddingDiffResponse,
    PutEmbeddingRequest,
} from 'types/embedding';
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

export const getLocalEmbeddings = async () => {
    const embeddings: Array<Embedding> =
        (await localForage.getItem<Embedding[]>(EMBEDDINGS_TABLE)) || [];
    return embeddings;
};

const getEmbeddingSyncTime = async () => {
    return (await localForage.getItem<number>(EMBEDDING_SYNC_TIME_TABLE)) ?? 0;
};

export const syncEmbeddings = async () => {
    try {
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
            if (!response.diff?.length) {
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
