import { getEndpoint } from "utils/common/apiUtil";
import HTTPService from "./HTTPService";
import * as Comlink from "comlink";

const decryptMetadata: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/decryptMetadata.worker.js", { type: 'module' }));
const decryptThumbnail: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/decryptThumbnail.worker.js", { type: 'module' }));

const ENDPOINT = getEndpoint();

export interface decryptionParams {
    encryptedKey: string;
    keyDecryptionNonce: string;
    header: string;
    nonce: string;
};
export interface fileData {
    id: number;
    file: {
        decryptionParams: decryptionParams;
    },
    thumbnail: {
        decryptionParams: decryptionParams;
    },
    metadata: {
        currentTime: number;
        modificationTime: number;
        latitude: number;
        longitude: number;
        title: string;
        deviceFolder: string;
    };
    src: string,
    w: number,
    h: number,
    data?: string;
};

const getFileMetaDataUsingWorker = (data: any, key: string) => {
    return decryptMetadata({ data, key });
}

const getFileUsingWorker = (data: any, key: string) => {
    return decryptThumbnail({ data, key });
}

export const getFiles = async (sinceTime: string, token: string, limit: string, key: string) => {
    const resp = await HTTPService.get(`${ENDPOINT}/encrypted-files/diff`, {
        sinceTime, token, limit,
    });

    const promises: Promise<fileData>[] = resp.data.diff.map((data) => getFileMetaDataUsingWorker(data, key));
    const decrypted = await Promise.all(promises);

    return decrypted;
}

export const getPreview = async (token: string, data: fileData, key: string) => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/encrypted-files/preview/${data.id}`,
        { token }, null, { responseType: 'arraybuffer' },
    );
    const decrypted: any = await getFileUsingWorker({
        ...data,
        file: resp.data,
    }, key);
    const url = URL.createObjectURL(new Blob([decrypted.data]));
    return url;
}
