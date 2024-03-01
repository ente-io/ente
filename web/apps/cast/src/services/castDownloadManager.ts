import { EnteFile } from "types/file";
import {
    createTypedObjectURL,
    generateStreamFromArrayBuffer,
    getRenderableFileURL,
} from "utils/file";

import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getCastFileURL, getCastThumbnailURL } from "@ente/shared/network/api";
import { logError } from "@ente/shared/sentry";
import { CACHES } from "constants/cache";
import { FILE_TYPE } from "constants/file";
import { LimitedCache } from "types/cache";
import ComlinkCryptoWorker from "utils/comlink/ComlinkCryptoWorker";
import { CacheStorageService } from "./cache/cacheStorageService";

class CastDownloadManager {
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
                CACHES.THUMBS,
            );
            return thumbnailCache;
        } catch (e) {
            return null;
            // ignore
        }
    }

    public async getCachedThumbnail(
        file: EnteFile,
        thumbnailCache?: LimitedCache,
    ) {
        try {
            if (!thumbnailCache) {
                thumbnailCache = await this.getThumbnailCache();
            }
            const cacheResp: Response = await thumbnailCache?.match(
                file.id.toString(),
            );

            if (cacheResp) {
                return URL.createObjectURL(await cacheResp.blob());
            }
            return null;
        } catch (e) {
            logError(e, "failed to get cached thumbnail");
            throw e;
        }
    }

    public async getThumbnail(file: EnteFile, castToken: string) {
        try {
            if (!this.thumbnailObjectURLPromise.has(file.id)) {
                const downloadPromise = async () => {
                    const thumbnailCache = await this.getThumbnailCache();
                    const cachedThumb = await this.getCachedThumbnail(
                        file,
                        thumbnailCache,
                    );
                    if (cachedThumb) {
                        return cachedThumb;
                    }

                    const thumb = await this.downloadThumb(castToken, file);
                    const thumbBlob = new Blob([thumb]);
                    try {
                        await thumbnailCache?.put(
                            file.id.toString(),
                            new Response(thumbBlob),
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
            logError(e, "get castDownloadManager preview Failed");
            throw e;
        }
    }

    private downloadThumb = async (castToken: string, file: EnteFile) => {
        const resp = await HTTPService.get(
            getCastThumbnailURL(file.id),
            null,
            {
                "X-Cast-Access-Token": castToken,
            },
            { responseType: "arraybuffer" },
        );
        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const decrypted = await cryptoWorker.decryptThumbnail(
            new Uint8Array(resp.data),
            await cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key,
        );
        return decrypted;
    };

    getFile = async (file: EnteFile, castToken: string, forPreview = false) => {
        const fileKey = forPreview ? `${file.id}_preview` : `${file.id}`;
        try {
            const getFilePromise = async () => {
                const fileStream = await this.downloadFile(castToken, file);
                const fileBlob = await new Response(fileStream).blob();
                if (forPreview) {
                    return await getRenderableFileURL(file, fileBlob);
                } else {
                    const fileURL = await createTypedObjectURL(
                        fileBlob,
                        file.metadata.title,
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
            logError(e, "castDownloadManager failed to get file");
            throw e;
        }
    };

    public async getCachedOriginalFile(file: EnteFile) {
        return await this.fileObjectURLPromise.get(file.id.toString());
    }

    async downloadFile(castToken: string, file: EnteFile) {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const onDownloadProgress = this.trackDownloadProgress(file.id);

        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getCastFileURL(file.id),
                null,
                {
                    "X-Cast-Access-Token": castToken,
                },
                { responseType: "arraybuffer" },
            );
            if (typeof resp.data === "undefined") {
                throw Error(CustomError.REQUEST_FAILED);
            }
            const decrypted = await cryptoWorker.decryptFile(
                new Uint8Array(resp.data),
                await cryptoWorker.fromB64(file.file.decryptionHeader),
                file.key,
            );
            return generateStreamFromArrayBuffer(decrypted);
        }
        const resp = await fetch(getCastFileURL(file.id), {
            headers: {
                "X-Cast-Access-Token": castToken,
            },
        });
        const reader = resp.body.getReader();

        const contentLength = +resp.headers.get("Content-Length");
        let downloadedBytes = 0;

        const stream = new ReadableStream({
            async start(controller) {
                const decryptionHeader = await cryptoWorker.fromB64(
                    file.file.decryptionHeader,
                );
                const fileKey = await cryptoWorker.fromB64(file.key);
                const { pullState, decryptionChunkSize } =
                    await cryptoWorker.initChunkDecryption(
                        decryptionHeader,
                        fileKey,
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
                                data.byteLength + value.byteLength,
                            );
                            buffer.set(new Uint8Array(data), 0);
                            buffer.set(new Uint8Array(value), data.byteLength);
                            if (buffer.length > decryptionChunkSize) {
                                const fileData = buffer.slice(
                                    0,
                                    decryptionChunkSize,
                                );
                                const { decryptedData } =
                                    await cryptoWorker.decryptFileChunk(
                                        fileData,
                                        pullState,
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
                                        pullState,
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
                    Math.round((event.loaded * 100) / event.total),
                );
            }
            this.progressUpdater(new Map(this.fileDownloadProgress));
        };
    };
}

export default new CastDownloadManager();
