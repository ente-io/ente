import {
    generateStreamFromArrayBuffer,
    getRenderableFileURL,
} from 'utils/file';
import { EnteFile } from 'types/file';

import { logError } from '@ente/shared/sentry';
import { FILE_TYPE } from 'constants/file';
import { CustomError } from '@ente/shared/error';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { CacheStorageService } from '@ente/shared/storage/cacheStorage';
import { CACHES } from '@ente/shared/storage/cacheStorage/constants';
import { Remote } from 'comlink';
import { DedicatedCryptoWorker } from '@ente/shared/crypto/internal/crypto.worker';
import { LimitedCache } from '@ente/shared/storage/cacheStorage/types';
import { addLogLine } from '@ente/shared/logging';
import { APPS } from '@ente/shared/apps/constants';
import { PhotosDownloadClient } from './clients/photos';
import { PublicAlbumsDownloadClient } from './clients/publicAlbums';
import isElectron from 'is-electron';
import { isInternalUser } from 'utils/user';

export type LivePhotoSourceURL = {
    image: () => Promise<string>;
    video: () => Promise<string>;
};

export type LoadedLivePhotoSourceURL = {
    image: string;
    video: string;
};

export type SourceURLs = {
    url: string | LivePhotoSourceURL | LoadedLivePhotoSourceURL;
    isOriginal: boolean;
    isRenderable: boolean;
    type: 'normal' | 'livePhoto';
};

export type OnDownloadProgress = (event: {
    loaded: number;
    total: number;
}) => void;

export interface DownloadClient {
    updateTokens: (token: string, passwordToken?: string) => void;
    updateTimeout: (timeout: number) => void;
    downloadThumbnail: (
        file: EnteFile,
        timeout?: number
    ) => Promise<Uint8Array>;
    downloadFile: (
        file: EnteFile,
        onDownloadProgress: OnDownloadProgress
    ) => Promise<Uint8Array>;
    downloadFileStream: (file: EnteFile) => Promise<Response>;
}

const FILE_CACHE_LIMIT = 5 * 1024 * 1024 * 1024; // 5GB

class DownloadManagerImpl {
    private ready: boolean = false;
    private downloadClient: DownloadClient;
    private thumbnailCache?: LimitedCache;
    // disk cache is only available on electron
    private diskFileCache?: LimitedCache;
    private cryptoWorker: Remote<DedicatedCryptoWorker>;

    private fileObjectURLPromises = new Map<number, Promise<SourceURLs>>();
    private fileConversionPromises = new Map<number, Promise<SourceURLs>>();
    private thumbnailObjectURLPromises = new Map<number, Promise<string>>();

    private fileDownloadProgress = new Map<number, number>();

    private progressUpdater: (value: Map<number, number>) => void = () => {};

    async init(
        app: APPS,
        tokens?: { token: string; passwordToken?: string } | { token: string },
        timeout?: number
    ) {
        try {
            if (this.ready) {
                addLogLine('DownloadManager already initialized');
                return;
            }
            this.downloadClient = createDownloadClient(app, tokens, timeout);
            this.thumbnailCache = await openThumbnailCache();
            this.diskFileCache = isElectron() && (await openDiskFileCache());
            this.cryptoWorker = await ComlinkCryptoWorker.getInstance();
            this.ready = true;
        } catch (e) {
            logError(e, 'DownloadManager init failed');
            throw e;
        }
    }

    updateToken(token: string, passwordToken?: string) {
        this.downloadClient.updateTokens(token, passwordToken);
    }

    updateCryptoWorker(cryptoWorker: Remote<DedicatedCryptoWorker>) {
        this.cryptoWorker = cryptoWorker;
    }

    updateTimeout(timeout: number) {
        this.downloadClient.updateTimeout(timeout);
    }

    setProgressUpdater(progressUpdater: (value: Map<number, number>) => void) {
        this.progressUpdater = progressUpdater;
    }

    async reloadCaches() {
        this.thumbnailCache = await openThumbnailCache();
        this.diskFileCache = isElectron() && (await openDiskFileCache());
    }

    private async getCachedThumbnail(fileID: number) {
        try {
            const cacheResp: Response = await this.thumbnailCache?.match(
                fileID.toString()
            );

            if (cacheResp) {
                return new Uint8Array(await cacheResp.arrayBuffer());
            }
        } catch (e) {
            logError(e, 'failed to get cached thumbnail');
            throw e;
        }
    }
    private async getCachedFile(file: EnteFile): Promise<Response> {
        try {
            if (!this.diskFileCache) {
                return null;
            }
            const cacheResp: Response = await this.diskFileCache?.match(
                file.id.toString(),
                { sizeInBytes: file.info?.fileSize }
            );
            if (!cacheResp) {
                return null;
            }
        } catch (e) {
            logError(e, 'failed to get cached thumbnail');
            throw e;
        }
    }

    private downloadThumb = async (file: EnteFile) => {
        const encrypted = await this.downloadClient.downloadThumbnail(file);
        const decrypted = await this.cryptoWorker.decryptThumbnail(
            encrypted,
            await this.cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key
        );
        return decrypted;
    };

    async getThumbnail(file: EnteFile, localOnly = false) {
        try {
            if (!this.ready) {
                throw Error(CustomError.DOWNLOAD_MANAGER_NOT_READY);
            }
            const cachedThumb = await this.getCachedThumbnail(file.id);
            if (cachedThumb) {
                return cachedThumb;
            }
            if (localOnly) {
                return null;
            }
            const thumb = await this.downloadThumb(file);

            this.thumbnailCache
                ?.put(file.id.toString(), new Response(thumb))
                .catch((e) => {
                    logError(e, 'thumb cache put failed');
                    // TODO: handle storage full exception.
                });
            return thumb;
        } catch (e) {
            logError(e, 'getThumbnail failed');
            throw e;
        }
    }

    async getThumbnailForPreview(file: EnteFile, localOnly = false) {
        try {
            if (!this.ready) {
                throw Error(CustomError.DOWNLOAD_MANAGER_NOT_READY);
            }
            if (!this.thumbnailObjectURLPromises.has(file.id)) {
                const thumbPromise = this.getThumbnail(file, localOnly);
                const thumbURLPromise = thumbPromise.then(
                    (thumb) => thumb && URL.createObjectURL(new Blob([thumb]))
                );
                this.thumbnailObjectURLPromises.set(file.id, thumbURLPromise);
            }
            let thumb = await this.thumbnailObjectURLPromises.get(file.id);
            if (!thumb && !localOnly) {
                this.thumbnailObjectURLPromises.delete(file.id);
                thumb = await this.getThumbnailForPreview(file, localOnly);
            }
            return thumb;
        } catch (e) {
            this.thumbnailObjectURLPromises.delete(file.id);
            logError(e, 'get DownloadManager preview Failed');
            throw e;
        }
    }

    getFileForPreview = async (
        file: EnteFile,
        forceConvert = false
    ): Promise<SourceURLs> => {
        try {
            if (!this.ready) {
                throw Error(CustomError.DOWNLOAD_MANAGER_NOT_READY);
            }
            const getFileForPreviewPromise = async () => {
                const fileBlob = await new Response(
                    await this.getFile(file, true)
                ).blob();
                const { url: originalFileURL } =
                    await this.fileObjectURLPromises.get(file.id);

                const converted = await getRenderableFileURL(
                    file,
                    fileBlob,
                    originalFileURL as string,
                    forceConvert
                );
                return converted;
            };
            if (forceConvert || !this.fileConversionPromises.has(file.id)) {
                this.fileConversionPromises.set(
                    file.id,
                    getFileForPreviewPromise()
                );
            }
            const fileURLs = await this.fileConversionPromises.get(file.id);
            return fileURLs;
        } catch (e) {
            this.fileConversionPromises.delete(file.id);
            logError(e, 'download manager getFileForPreview Failed');
            throw e;
        }
    };

    async getFile(
        file: EnteFile,
        cacheInMemory = false
    ): Promise<ReadableStream<Uint8Array>> {
        try {
            if (!this.ready) {
                throw Error(CustomError.DOWNLOAD_MANAGER_NOT_READY);
            }
            const getFilePromise = async (): Promise<SourceURLs> => {
                const fileStream = await this.downloadFile(file);
                const fileBlob = await new Response(fileStream).blob();
                return {
                    url: URL.createObjectURL(fileBlob),
                    isOriginal: true,
                    isRenderable: false,
                    type: 'normal',
                };
            };
            if (!this.fileObjectURLPromises.has(file.id)) {
                if (!cacheInMemory) {
                    return await this.downloadFile(file);
                }
                this.fileObjectURLPromises.set(file.id, getFilePromise());
            }
            const fileURLs = await this.fileObjectURLPromises.get(file.id);
            if (fileURLs.isOriginal) {
                const fileStream = (await fetch(fileURLs.url as string)).body;
                return fileStream;
            } else {
                return await this.downloadFile(file);
            }
        } catch (e) {
            this.fileObjectURLPromises.delete(file.id);
            logError(e, 'download manager getFile Failed');
            throw e;
        }
    }

    private async downloadFile(
        file: EnteFile
    ): Promise<ReadableStream<Uint8Array>> {
        try {
            addLogLine(`download attempted for fileID:${file.id}`);
            const onDownloadProgress = this.trackDownloadProgress(
                file.id,
                file.info?.fileSize
            );
            if (
                file.metadata.fileType === FILE_TYPE.IMAGE ||
                file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
            ) {
                let encrypted = await this.getCachedFile(file);
                if (!encrypted) {
                    encrypted = new Response(
                        await this.downloadClient.downloadFile(
                            file,
                            onDownloadProgress
                        )
                    );
                    if (this.diskFileCache) {
                        this.diskFileCache
                            .put(file.id.toString(), encrypted.clone())
                            .catch((e) => {
                                logError(e, 'file cache put failed');
                                // TODO: handle storage full exception.
                            });
                    }
                }
                this.clearDownloadProgress(file.id);
                try {
                    const decrypted = await this.cryptoWorker.decryptFile(
                        new Uint8Array(await encrypted.arrayBuffer()),
                        await this.cryptoWorker.fromB64(
                            file.file.decryptionHeader
                        ),
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

            let resp: Response = await this.getCachedFile(file);
            if (!resp) {
                resp = await this.downloadClient.downloadFileStream(file);
                if (this.diskFileCache) {
                    this.diskFileCache
                        .put(file.id.toString(), resp.clone())
                        .catch((e) => {
                            logError(e, 'file cache put failed');
                        });
                }
            }
            const reader = resp.body.getReader();

            const contentLength = +resp.headers.get('Content-Length') ?? 0;
            let downloadedBytes = 0;

            const stream = new ReadableStream({
                start: async (controller) => {
                    try {
                        const decryptionHeader =
                            await this.cryptoWorker.fromB64(
                                file.file.decryptionHeader
                            );
                        const fileKey = await this.cryptoWorker.fromB64(
                            file.key
                        );
                        const { pullState, decryptionChunkSize } =
                            await this.cryptoWorker.initChunkDecryption(
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
                                                    await this.cryptoWorker.decryptFileChunk(
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
                                                    await this.cryptoWorker.decryptFileChunk(
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

const DownloadManager = new DownloadManagerImpl();

export default DownloadManager;

async function openThumbnailCache() {
    try {
        return await CacheStorageService.open(CACHES.THUMBS);
    } catch (e) {
        logError(e, 'Failed to open thumbnail cache');
        if (isInternalUser()) {
            throw e;
        } else {
            return null;
        }
    }
}

async function openDiskFileCache() {
    try {
        if (!isElectron()) {
            throw Error(CustomError.NOT_AVAILABLE_ON_WEB);
        }
        return await CacheStorageService.open(CACHES.FILES, FILE_CACHE_LIMIT);
    } catch (e) {
        logError(e, 'Failed to open file cache');
        if (isInternalUser()) {
            throw e;
        } else {
            return null;
        }
    }
}

function createDownloadClient(
    app: APPS,
    tokens?: { token: string; passwordToken?: string } | { token: string },
    timeout?: number
): DownloadClient {
    if (!timeout) {
        timeout = 300000; // 5 minute
    }
    if (app === APPS.ALBUMS) {
        if (!tokens) {
            tokens = { token: undefined, passwordToken: undefined };
        }
        const { token, passwordToken } = tokens as {
            token: string;
            passwordToken: string;
        };
        return new PublicAlbumsDownloadClient(token, passwordToken, timeout);
    } else {
        const { token } = tokens;
        return new PhotosDownloadClient(token, timeout);
    }
}
