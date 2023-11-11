import {
    getPublicCollectionFileURL,
    getPublicCollectionThumbnailURL,
} from '@ente/shared/network/api';
import {
    generateStreamFromArrayBuffer,
    getRenderableFileURL,
    createTypedObjectURL,
} from 'utils/file';
import HTTPService from '@ente/shared/network/HTTPService';
import { EnteFile } from 'types/file';

import { logError } from '@ente/shared/sentry';
import { FILE_TYPE } from 'constants/file';
import { CustomError } from '@ente/shared/error';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { CACHES } from '@ente/shared/storage/cacheStorage/constants';
import { CacheStorageService } from '@ente/shared/storage/cacheStorage';
import { LimitedCache } from '@ente/shared/storage/cacheStorage/types';

class PublicCollectionDownloadManager {
    private fileObjectURLPromise = new Map<
        string,
        Promise<{ original: string[]; converted: string[] }>
    >();
    private thumbnailObjectURLPromise = new Map<number, Promise<string>>();

    private fileDownloadProgress = new Map<number, number>();

    private progressUpdater: (value: Map<number, number>) => void;

    setProgressUpdater(progressUpdater: (value: Map<number, number>) => void) {
        this.progressUpdater = progressUpdater;
    }

    private async getThumbnailCache() {
        try {
            const thumbnailCache = await CacheStorageService.open(
                CACHES.THUMBS
            );
            return thumbnailCache;
        } catch (e) {
            return null;
            // ignore
        }
    }

    public async getCachedThumbnail(
        file: EnteFile,
        thumbnailCache?: LimitedCache
    ) {
        try {
            if (!thumbnailCache) {
                thumbnailCache = await this.getThumbnailCache();
            }
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
        token: string,
        passwordToken: string
    ) {
        try {
            if (!token) {
                return null;
            }

            if (!this.thumbnailObjectURLPromise.has(file.id)) {
                const downloadPromise = async () => {
                    const thumbnailCache = await this.getThumbnailCache();
                    const cachedThumb = await this.getCachedThumbnail(
                        file,
                        thumbnailCache
                    );
                    if (cachedThumb) {
                        return cachedThumb;
                    }

                    const thumb = await this.downloadThumb(
                        token,
                        passwordToken,
                        file
                    );
                    const thumbBlob = new Blob([thumb]);
                    try {
                        await thumbnailCache?.put(
                            file.id.toString(),
                            new Response(thumbBlob)
                        );
                    } catch (e) {
                        // TODO: handle storage full exception.
                    }
                    return URL.createObjectURL(thumbBlob);
                };
                this.thumbnailObjectURLPromise.set(file.id, downloadPromise());
            }

            return await this.thumbnailObjectURLPromise.get(file.id);
        } catch (e) {
            this.thumbnailObjectURLPromise.delete(file.id);
            logError(e, 'get publicDownloadManger preview Failed');
            throw e;
        }
    }

    private downloadThumb = async (
        token: string,
        passwordToken: string,
        file: EnteFile
    ) => {
        const resp = await HTTPService.get(
            getPublicCollectionThumbnailURL(file.id),
            null,
            {
                'X-Auth-Access-Token': token,
                ...(passwordToken && {
                    'X-Auth-Access-Token-JWT': passwordToken,
                }),
            },
            { responseType: 'arraybuffer' }
        );
        if (typeof resp.data === 'undefined') {
            throw Error(CustomError.REQUEST_FAILED);
        }
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const decrypted = await cryptoWorker.decryptThumbnail(
            new Uint8Array(resp.data),
            await cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key
        );
        return decrypted;
    };

    getFile = async (
        file: EnteFile,
        token: string,
        passwordToken: string,
        forPreview = false
    ) => {
        const fileKey = forPreview ? `${file.id}_preview` : `${file.id}`;
        try {
            const getFilePromise = async () => {
                const fileStream = await this.downloadFile(
                    token,
                    passwordToken,
                    file
                );
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
            logError(e, 'public download manager Failed to get File');
            throw e;
        }
    };

    public async getCachedOriginalFile(file: EnteFile) {
        return await this.fileObjectURLPromise.get(file.id.toString());
    }

    async downloadFile(token: string, passwordToken: string, file: EnteFile) {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        if (!token) {
            return null;
        }
        const onDownloadProgress = this.trackDownloadProgress(file.id);

        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getPublicCollectionFileURL(file.id),
                null,
                {
                    'X-Auth-Access-Token': token,
                    ...(passwordToken && {
                        'X-Auth-Access-Token-JWT': passwordToken,
                        onDownloadProgress,
                    }),
                },
                { responseType: 'arraybuffer' }
            );
            if (typeof resp.data === 'undefined') {
                throw Error(CustomError.REQUEST_FAILED);
            }
            const decrypted = await cryptoWorker.decryptFile(
                new Uint8Array(resp.data),
                await cryptoWorker.fromB64(file.file.decryptionHeader),
                file.key
            );
            return generateStreamFromArrayBuffer(decrypted);
        }
        const resp = await fetch(getPublicCollectionFileURL(file.id), {
            headers: {
                'X-Auth-Access-Token': token,
                ...(passwordToken && {
                    'X-Auth-Access-Token-JWT': passwordToken,
                }),
            },
        });
        const reader = resp.body.getReader();

        const contentLength = +resp.headers.get('Content-Length');
        let downloadedBytes = 0;

        const stream = new ReadableStream({
            async start(controller) {
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
                function push() {
                    // "done" is a Boolean and value a "Uint8Array"
                    reader.read().then(async ({ done, value }) => {
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
                            buffer.set(new Uint8Array(value), data.byteLength);
                            if (buffer.length > decryptionChunkSize) {
                                const fileData = buffer.slice(
                                    0,
                                    decryptionChunkSize
                                );
                                const { decryptedData } =
                                    await cryptoWorker.decryptFileChunk(
                                        fileData,
                                        pullState
                                    );
                                controller.enqueue(decryptedData);
                                data = buffer.slice(decryptionChunkSize);
                            } else {
                                data = buffer;
                            }
                            push();
                        } else {
                            if (data) {
                                const { decryptedData } =
                                    await cryptoWorker.decryptFileChunk(
                                        data,
                                        pullState
                                    );
                                controller.enqueue(decryptedData);
                                data = null;
                            }
                            controller.close();
                        }
                    });
                }

                push();
            },
        });
        return stream;
    }

    trackDownloadProgress = (fileID: number) => {
        return (event: { loaded: number; total: number }) => {
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
}

export default new PublicCollectionDownloadManager();
