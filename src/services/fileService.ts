import aescrypt from "utils/aescrypt";
import { getEndpoint } from "utils/common/apiUtil";
import { decrypt } from "utils/crypto/aes";
import { strToUint8 } from "utils/crypto/common";
import HTTPService from "./HTTPService";

const ENDPOINT = getEndpoint();

export interface fileData {
    id: number;
    metadata: {
        currentTime: number;
        modificationTime: number;
        latitude: number;
        longitude: number;
        title: string;
        deviceFolder: string;
    };
    encryptedPassword: string;
    encryptedPasswordIV: string;
    file?: string;
};

const getFileDataUsingWorker = (data: any, key: string) => {
    return new Promise((resolve) => {
        const worker = new Worker('worker/decryptMetadata.worker.js', { type: 'module' });
        const onWorkerMessage = (event) => resolve(event.data);
        worker.addEventListener('message', onWorkerMessage);
        worker.postMessage({ data, key });
    });
}

const getFileUsingWorker = (data: any, key: string) => {
    return new Promise((resolve) => {
        const worker = new Worker('worker/decryptFile.worker.js', { type: 'module' });
        const onWorkerMessage = (event) => resolve(event.data);
        worker.addEventListener('message', onWorkerMessage);
        worker.postMessage({ data, key });
    });
}

export const getFiles = async (sinceTime: string, token: string, limit: string, key: string) => {
    const resp = await HTTPService.get(`${ENDPOINT}/encrypted-files/diff`, {
        sinceTime, token, limit,
    });

    const promises: Promise<fileData>[] = resp.data.diff.map((data) => getFileDataUsingWorker(data, key));
    const decrypted = await Promise.all(promises);

    return decrypted;
}

export const getPreview = async (token: string, data: fileData, key: string) => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/encrypted-files/preview/${data.id}`,
        { token }, null, { responseType: 'arraybuffer' },
    );
    const decrypted = await getFileUsingWorker({
        ...data,
        file: resp.data,
    }, key);
    const url = URL.createObjectURL(new Blob([decrypted.file]));
    return url;
}
