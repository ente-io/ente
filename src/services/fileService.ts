import { getEndpoint } from "utils/common/apiUtil";
import HTTPService from "./HTTPService";

const ENDPOINT = getEndpoint();

export interface fileData {
    id: number;
    metadata: {
        currentTimestamp: number,
    },
};

const getFileDataUsingWorker = (data: any, key: string) => {
    return new Promise((resolve) => {
        const worker = new Worker('worker/decrypt.worker.js', { type: 'module' });
        const onWorkerMessage = (event) => resolve(event.data);
        worker.addEventListener('message', onWorkerMessage);
        worker.postMessage({ data, key });
    });
}

export const getFiles = async (sinceTimestamp: string, token: string, limit: string, key: string) => {
    const resp = await HTTPService.get(`${ENDPOINT}/encrypted-files/diff`, {
        sinceTimestamp, token, limit,
    });

    const promises: Promise<fileData>[] = resp.data.diff.map((data) => getFileDataUsingWorker(data, key));
    console.time('Metadata Parsing');
    const decrypted = await Promise.all(promises);
    console.timeEnd('Metadata Parsing');

    return decrypted;
}
