import { getToken } from 'utils/common/key';
import { getFileURL, getThumbnailURL } from 'utils/common/apiUtil';
import {
    generateStreamFromArrayBuffer,
    getRenderableFileURL,
    createTypedObjectURL,
} from 'utils/file';
import HTTPService from './HTTPService';
import { EnteFile } from 'types/file';

import { logError } from 'utils/sentry';
import { FILE_TYPE } from 'constants/file';
import { CustomError } from 'utils/error';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { CacheStorageService } from './cache/cacheStorageService';
import { CACHES } from 'constants/cache';
import { Remote } from 'comlink';
import { DedicatedCryptoWorker } from 'worker/crypto.worker';
import { LimitedCache } from 'types/cache';
import { retryAsyncFunction } from 'utils/network';
import { addLogLine } from 'utils/logging';

class DownloadManager {
    private fileObjectURLPromise = new Map<
        string,
        Promise<{ original: string[]; converted: string[] }>
    >();
    private thumbnailObjectURLPromise = new Map<number, Promise<string>>();

    private fileDownloadProgress = new Map<number, number>();

    private progressUpdater: (value: Map<number, number>) => void = () => {};

    private thumbnailCache: LimitedCache;

    setProgressUpdater(progressUpdater: (value: Map<number, number>) => void) {
        this.progressUpdater = progressUpdater;
    }

    private async getThumbnailCache() {
        try {
            if (!this.thumbnailCache) {
                this.thumbnailCache = await CacheStorageService.open(
                    CACHES.THUMBS
                );
            }
            return this.thumbnailCache;
        } catch (e) {
            return null;
            // ignore
        }
    }

    public async getCachedThumbnail(file: EnteFile) {
        try {
            const thumbnailCache = await this.getThumbnailCache();
            const cacheResp: Response = await thumbnailCache?.match(
                file.id.toString()
            );

            if (cacheResp) {
                return URL.createObjectURL(await cacheResp.blob());
            }
            return null;
        } catch (e) {
            logError(e, 'failed to get cached thumbnail');
            throw e;
        }
    }

    public async getThumbnail(
        file: EnteFile,
        tokenOverride?: string,
        usingWorker?: Remote<DedicatedCryptoWorker>,
        timeout?: number
    ) {
        try {
            const token = tokenOverride || getToken();
            if (!token) {
                return null;
            }
            if (!this.thumbnailObjectURLPromise.has(file.id)) {
                const downloadPromise = async () => {
                    const thumbnailCache = await this.getThumbnailCache();
                    const cachedThumb = await this.getCachedThumbnail(file);
                    if (cachedThumb) {
                        return cachedThumb;
                    }
                    const thumb = await this.downloadThumb(
                        token,
                        file,
                        usingWorker,
                        timeout
                    );
                    const thumbBlob = new Blob([thumb]);

                    thumbnailCache
                        ?.put(file.id.toString(), new Response(thumbBlob))
                        .catch((e) => {
                            logError(e, 'cache put failed');
                            // TODO: handle storage full exception.
                        });
                    return URL.createObjectURL(thumbBlob);
                };
                this.thumbnailObjectURLPromise.set(file.id, downloadPromise());
            }

            return await this.thumbnailObjectURLPromise.get(file.id);
        } catch (e) {
            this.thumbnailObjectURLPromise.delete(file.id);
            logError(e, 'get DownloadManager preview Failed');
            throw e;
        }
    }

    downloadThumb = async (
        token: string,
        file: EnteFile,
        usingWorker?: Remote<DedicatedCryptoWorker>,
        timeout?: number
    ) => {
        const resp = await HTTPService.get(
            getThumbnailURL(file.id),
            null,
            { 'X-Auth-Token': token },
            { responseType: 'arraybuffer', timeout }
        );
        if (typeof resp.data === 'undefined') {
            throw Error(CustomError.REQUEST_FAILED);
        }
        const cryptoWorker =
            usingWorker || (await ComlinkCryptoWorker.getInstance());
        const decrypted = await cryptoWorker.decryptThumbnail(
            new Uint8Array(resp.data),
            await cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key
        );
        return decrypted;
    };

    getFile = async (file: EnteFile, forPreview = false) => {
        const fileKey = forPreview ? `${file.id}_preview` : `${file.id}`;
        try {
            const getFilePromise = async () => {
                const fileStream = await this.downloadFile(file);
                const fileBlob = await new Response(fileStream).blob();
                if (forPreview) {
                    return await getRenderableFileURL(file, fileBlob);
                } else {
                    const fileURL = await createTypedObjectURL(
                        fileBlob,
                        file.metadata.title
                    );
                    return { converted: [fileURL], original: [fileURL] };
                }
            };
            if (!this.fileObjectURLPromise.get(fileKey)) {
                this.fileObjectURLPromise.set(fileKey, getFilePromise());
            }
            const fileURLs = await this.fileObjectURLPromise.get(fileKey);
            return fileURLs;
        } catch (e) {
            this.fileObjectURLPromise.delete(fileKey);
            logError(e, 'download manager Failed to get File');
            throw e;
        }
    };

    public async getCachedOriginalFile(file: EnteFile) {
        return (await this.fileObjectURLPromise.get(file.id.toString()))
            ?.original;
    }

    async downloadFile(
        file: EnteFile,
        tokenOverride?: string,
        usingWorker?: Remote<DedicatedCryptoWorker>,
        timeout?: number
    ) {
        try {
            const cryptoWorker =
                usingWorker || (await ComlinkCryptoWorker.getInstance());
            const token = tokenOverride || getToken();
            if (!token) {
                return null;
            }
            const onDownloadProgress = this.trackDownloadProgress(
                file.id,
                file.info?.fileSize
            );
            if (
                file.metadata.fileType === FILE_TYPE.IMAGE ||
                file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
            ) {
                const resp = await retryAsyncFunction(() =>
                    HTTPService.get(
                        getFileURL(file.id),
                        null,
                        { 'X-Auth-Token': token },
                        {
                            responseType: 'arraybuffer',
                            timeout,
                            onDownloadProgress,
                        }
                    )
                );
                this.clearDownloadProgress(file.id);
                if (typeof resp.data === 'undefined') {
                    throw Error(CustomError.REQUEST_FAILED);
                }
                try {
                    const decrypted = await cryptoWorker.decryptFile(
                        new Uint8Array(resp.data),
                        await cryptoWorker.fromB64(file.file.decryptionHeader),
                        file.key
                    );
                    return generateStreamFromArrayBuffer(decrypted);
                } catch (e) {
                    if (e.message === CustomError.PROCESSING_FAILED) {
                        logError(e, 'Failed to process file', {
                            fileID: file.id,
                            fromMobile:
                                !!file.metadata.localID ||
                                !!file.metadata.deviceFolder ||
                                !!file.metadata.version,
                        });
                        addLogLine(
                            `Failed to process file with fileID:${file.id}, localID: ${file.metadata.localID}, version: ${file.metadata.version}, deviceFolder:${file.metadata.deviceFolder} with error: ${e.message}`
                        );
                    }
                    throw e;
                }
            }
            const resp = await retryAsyncFunction(() =>
                fetch(getFileURL(file.id), {
                    headers: {
                        'X-Auth-Token': token,
                    },
                })
            );
            const reader = resp.body.getReader();

            const contentLength = +resp.headers.get('Content-Length') ?? 0;
            let downloadedBytes = 0;

            const stream = new ReadableStream({
                async start(controller) {
                    try {
                        const decryptionHeader = await cryptoWorker.fromB64(
                            file.file.decryptionHeader
                        );
                        const fileKey = await cryptoWorker.fromB64(file.key);
                        const { pullState, decryptionChunkSize } =
                            await cryptoWorker.initChunkDecryption(
                                decryptionHeader,
                                fileKey
                            );
                        let data = new Uint8Array();
                        // The following function handles each data chunk
                        const push = () => {
                            // "done" is a Boolean and value a "Uint8Array"
                            reader.read().then(async ({ done, value }) => {
                                try {
                                    // Is there more data to read?
                                    if (!done) {
                                        downloadedBytes += value.byteLength;
                                        onDownloadProgress({
                                            loaded: downloadedBytes,
                                            total: contentLength,
                                        });
                                        const buffer = new Uint8Array(
                                            data.byteLength + value.byteLength
                                        );
                                        buffer.set(new Uint8Array(data), 0);
                                        buffer.set(
                                            new Uint8Array(value),
                                            data.byteLength
                                        );
                                        if (
                                            buffer.length > decryptionChunkSize
                                        ) {
                                            const fileData = buffer.slice(
                                                0,
                                                decryptionChunkSize
                                            );
                                            try {
                                                const { decryptedData } =
                                                    await cryptoWorker.decryptFileChunk(
                                                        fileData,
                                                        pullState
                                                    );
                                                controller.enqueue(
                                                    decryptedData
                                                );
                                                data =
                                                    buffer.slice(
                                                        decryptionChunkSize
                                                    );
                                            } catch (e) {
                                                if (
                                                    e.message ===
                                                    CustomError.PROCESSING_FAILED
                                                ) {
                                                    logError(
                                                        e,
                                                        'Failed to process file',
                                                        {
                                                            fileID: file.id,
                                                            fromMobile:
                                                                !!file.metadata
                                                                    .localID ||
                                                                !!file.metadata
                                                                    .deviceFolder ||
                                                                !!file.metadata
                                                                    .version,
                                                        }
                                                    );
                                                    addLogLine(
                                                        `Failed to process file ${file.id} from localID: ${file.metadata.localID} version: ${file.metadata.version} deviceFolder:${file.metadata.deviceFolder} with error: ${e.message}`
                                                    );
                                                }
                                                throw e;
                                            }
                                        } else {
                                            data = buffer;
                                        }
                                        push();
                                    } else {
                                        if (data) {
                                            try {
                                                const { decryptedData } =
                                                    await cryptoWorker.decryptFileChunk(
                                                        data,
                                                        pullState
                                                    );
                                                controller.enqueue(
                                                    decryptedData
                                                );
                                                data = null;
                                            } catch (e) {
                                                if (
                                                    e.message ===
                                                    CustomError.PROCESSING_FAILED
                                                ) {
                                                    logError(
                                                        e,
                                                        'Failed to process file',
                                                        {
                                                            fileID: file.id,
                                                            fromMobile:
                                                                !!file.metadata
                                                                    .localID ||
                                                                !!file.metadata
                                                                    .deviceFolder ||
                                                                !!file.metadata
                                                                    .version,
                                                        }
                                                    );
                                                    addLogLine(
                                                        `Failed to process file ${file.id} from localID: ${file.metadata.localID} version: ${file.metadata.version} deviceFolder:${file.metadata.deviceFolder} with error: ${e.message}`
                                                    );
                                                }
                                                throw e;
                                            }
                                        }
                                        controller.close();
                                    }
                                } catch (e) {
                                    logError(e, 'Failed to process file chunk');
                                    controller.error(e);
                                }
                            });
                        };

                        push();
                    } catch (e) {
                        logError(e, 'Failed to process file stream');
                        controller.error(e);
                    }
                },
            });
            return stream;
        } catch (e) {
            logError(e, 'Failed to download file');
            throw e;
        }
    }

    trackDownloadProgress = (fileID: number, fileSize: number) => {
        return (event: { loaded: number; total: number }) => {
            if (isNaN(event.total) || event.total === 0) {
                if (!fileSize) {
                    return;
                }
                event.total = fileSize;
            }
            if (event.loaded === event.total) {
                this.fileDownloadProgress.delete(fileID);
            } else {
                this.fileDownloadProgress.set(
                    fileID,
                    Math.round((event.loaded * 100) / event.total)
                );
            }
            this.progressUpdater(new Map(this.fileDownloadProgress));
        };
    };

    clearDownloadProgress = (fileID: number) => {
        this.fileDownloadProgress.delete(fileID);
        this.progressUpdater(new Map(this.fileDownloadProgress));
    };
}

export default new DownloadManager();
