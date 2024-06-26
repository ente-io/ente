import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import {
    EnteFile,
    type LivePhotoSourceURL,
    type SourceURLs,
} from "@/new/photos/types/file";
import { blobCache, type BlobCache } from "@/next/blob-cache";
import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import { isPlaybackPossible } from "@ente/shared/media/video-playback";
import type { Remote } from "comlink";
import isElectron from "is-electron";
import * as ffmpeg from "services/ffmpeg";
import { getRenderableImage } from "utils/file";
import { PhotosDownloadClient } from "./clients/photos";
import { PublicAlbumsDownloadClient } from "./clients/publicAlbums";

export type OnDownloadProgress = (event: {
    loaded: number;
    total: number;
}) => void;

export interface DownloadClient {
    updateTokens: (token: string, passwordToken?: string) => void;
    downloadThumbnail: (
        file: EnteFile,
        timeout?: number,
    ) => Promise<Uint8Array>;
    downloadFile: (
        file: EnteFile,
        onDownloadProgress: OnDownloadProgress,
    ) => Promise<Uint8Array>;
    downloadFileStream: (file: EnteFile) => Promise<Response>;
}

class DownloadManagerImpl {
    private ready: boolean = false;
    private downloadClient: DownloadClient;
    /** Local cache for thumbnails. Might not be available. */
    private thumbnailCache?: BlobCache;
    /**
     * Local cache for the files themselves.
     *
     * Only available when we're running in the desktop app.
     */
    private fileCache?: BlobCache;
    private cryptoWorker: Remote<DedicatedCryptoWorker>;

    private fileObjectURLPromises = new Map<number, Promise<SourceURLs>>();
    private fileConversionPromises = new Map<number, Promise<SourceURLs>>();
    private thumbnailObjectURLPromises = new Map<number, Promise<string>>();

    private fileDownloadProgress = new Map<number, number>();

    private progressUpdater: (value: Map<number, number>) => void = () => {};

    async init(token?: string) {
        if (this.ready) {
            log.info("DownloadManager already initialized");
            return;
        }
        this.downloadClient = createDownloadClient(token);
        try {
            this.thumbnailCache = await blobCache("thumbs");
        } catch (e) {
            log.error(
                "Failed to open thumbnail cache, will continue without it",
                e,
            );
        }
        // TODO (MR): Revisit full file caching cf disk space usage
        // try {
        //     if (isElectron()) this.fileCache = await cache("files");
        // } catch (e) {
        //     log.error("Failed to open file cache, will continue without it", e);
        // }
        this.cryptoWorker = await ComlinkCryptoWorker.getInstance();
        this.ready = true;
    }

    private ensureInitialized() {
        if (!this.ready)
            throw new Error(
                "Attempting to use an uninitialized download manager",
            );
    }

    async logout() {
        this.ready = false;
        this.cryptoWorker = null;
        this.downloadClient = null;
        this.fileObjectURLPromises.clear();
        this.fileConversionPromises.clear();
        this.thumbnailObjectURLPromises.clear();
        this.fileDownloadProgress.clear();
        this.progressUpdater = () => {};
    }

    updateToken(token: string, passwordToken?: string) {
        this.downloadClient.updateTokens(token, passwordToken);
    }

    updateCryptoWorker(cryptoWorker: Remote<DedicatedCryptoWorker>) {
        this.cryptoWorker = cryptoWorker;
    }

    setProgressUpdater(progressUpdater: (value: Map<number, number>) => void) {
        this.progressUpdater = progressUpdater;
    }

    private downloadThumb = async (file: EnteFile) => {
        const encrypted = await this.downloadClient.downloadThumbnail(file);
        const decrypted = await this.cryptoWorker.decryptThumbnail(
            encrypted,
            await this.cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key,
        );
        return decrypted;
    };

    async getThumbnail(file: EnteFile, localOnly = false) {
        this.ensureInitialized();

        const key = file.id.toString();
        const cached = await this.thumbnailCache?.get(key);
        if (cached) return new Uint8Array(await cached.arrayBuffer());
        if (localOnly) return null;

        const thumb = await this.downloadThumb(file);
        this.thumbnailCache?.put(key, new Blob([thumb]));
        return thumb;
    }

    async getThumbnailForPreview(file: EnteFile, localOnly = false) {
        this.ensureInitialized();
        try {
            if (!this.thumbnailObjectURLPromises.has(file.id)) {
                const thumbPromise = this.getThumbnail(file, localOnly);
                const thumbURLPromise = thumbPromise.then(
                    (thumb) => thumb && URL.createObjectURL(new Blob([thumb])),
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
            log.error("get DownloadManager preview Failed", e);
            throw e;
        }
    }

    getFileForPreview = async (
        file: EnteFile,
        forceConvert = false,
    ): Promise<SourceURLs> => {
        this.ensureInitialized();
        try {
            const getFileForPreviewPromise = async () => {
                const fileBlob = await new Response(
                    await this.getFile(file, true),
                ).blob();
                const { url: originalFileURL } =
                    await this.fileObjectURLPromises.get(file.id);

                const converted = await getRenderableFileURL(
                    file,
                    fileBlob,
                    originalFileURL as string,
                    forceConvert,
                );
                return converted;
            };
            if (forceConvert || !this.fileConversionPromises.has(file.id)) {
                this.fileConversionPromises.set(
                    file.id,
                    getFileForPreviewPromise(),
                );
            }
            const fileURLs = await this.fileConversionPromises.get(file.id);
            return fileURLs;
        } catch (e) {
            this.fileConversionPromises.delete(file.id);
            log.error("download manager getFileForPreview Failed", e);
            throw e;
        }
    };

    async getFile(
        file: EnteFile,
        cacheInMemory = false,
    ): Promise<ReadableStream<Uint8Array>> {
        this.ensureInitialized();
        try {
            const getFilePromise = async (): Promise<SourceURLs> => {
                const fileStream = await this.downloadFile(file);
                const fileBlob = await new Response(fileStream).blob();
                return {
                    url: URL.createObjectURL(fileBlob),
                    isOriginal: true,
                    isRenderable: false,
                    type: "normal",
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
            log.error("download manager getFile Failed", e);
            throw e;
        }
    }

    private async downloadFile(
        file: EnteFile,
    ): Promise<ReadableStream<Uint8Array>> {
        log.info(`download attempted for file id ${file.id}`);

        const onDownloadProgress = this.trackDownloadProgress(
            file.id,
            file.info?.fileSize,
        );

        const cacheKey = file.id.toString();

        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const cachedBlob = await this.fileCache?.get(cacheKey);
            let encryptedArrayBuffer = await cachedBlob?.arrayBuffer();
            if (!encryptedArrayBuffer) {
                const array = await this.downloadClient.downloadFile(
                    file,
                    onDownloadProgress,
                );
                encryptedArrayBuffer = array.buffer;
                this.fileCache?.put(cacheKey, new Blob([encryptedArrayBuffer]));
            }
            this.clearDownloadProgress(file.id);
            try {
                const decrypted = await this.cryptoWorker.decryptFile(
                    new Uint8Array(encryptedArrayBuffer),
                    await this.cryptoWorker.fromB64(file.file.decryptionHeader),
                    file.key,
                );
                return new Response(decrypted).body;
            } catch (e) {
                if (e.message === CustomError.PROCESSING_FAILED) {
                    log.error(
                        `Failed to process file with fileID:${file.id}, localID: ${file.metadata.localID}, version: ${file.metadata.version}, deviceFolder:${file.metadata.deviceFolder}`,
                        e,
                    );
                }
                throw e;
            }
        }

        const cachedBlob = await this.fileCache?.get(cacheKey);
        let res: Response;
        if (cachedBlob) res = new Response(cachedBlob);
        else {
            res = await this.downloadClient.downloadFileStream(file);
            // We don't have a files cache currently, so this was already a
            // no-op. But even if we had a cache, this seems sus, because
            // res.blob() will read the stream and I'd think then trying to do
            // the subsequent read of the stream again below won't work.

            // this.fileCache?.put(cacheKey, await res.blob());
        }
        const reader = res.body.getReader();

        const contentLength = +res.headers.get("Content-Length") ?? 0;
        let downloadedBytes = 0;

        const decryptionHeader = await this.cryptoWorker.fromB64(
            file.file.decryptionHeader,
        );
        const fileKey = await this.cryptoWorker.fromB64(file.key);
        const { pullState, decryptionChunkSize } =
            await this.cryptoWorker.initChunkDecryption(
                decryptionHeader,
                fileKey,
            );

        let leftoverBytes = new Uint8Array();

        return new ReadableStream({
            pull: async (controller) => {
                // Each time pull is called, we want to enqueue at least once.
                let didEnqueue = false;
                do {
                    // done is a boolean and value is an Uint8Array. When done
                    // is true value will be empty.
                    const { done, value } = await reader.read();

                    let data: Uint8Array;
                    if (done) {
                        data = leftoverBytes;
                    } else {
                        downloadedBytes += value.length;
                        onDownloadProgress({
                            loaded: downloadedBytes,
                            total: contentLength,
                        });

                        data = new Uint8Array(
                            leftoverBytes.length + value.length,
                        );
                        data.set(new Uint8Array(leftoverBytes), 0);
                        data.set(new Uint8Array(value), leftoverBytes.length);
                    }

                    // data.length might be a multiple of decryptionChunkSize,
                    // and we might need multiple iterations to drain it all.
                    while (data.length >= decryptionChunkSize) {
                        const { decryptedData } =
                            await this.cryptoWorker.decryptFileChunk(
                                data.slice(0, decryptionChunkSize),
                                pullState,
                            );
                        controller.enqueue(decryptedData);
                        didEnqueue = true;
                        data = data.slice(decryptionChunkSize);
                    }

                    if (done) {
                        // Send off the remaining bytes without waiting for a
                        // full chunk, no more bytes are going to come.
                        if (data.length) {
                            const { decryptedData } =
                                await this.cryptoWorker.decryptFileChunk(
                                    data,
                                    pullState,
                                );
                            controller.enqueue(decryptedData);
                        }
                        // Don't loop again even if we didn't enqueue.
                        didEnqueue = true;
                        controller.close();
                    } else {
                        // Save it for the next pull.
                        leftoverBytes = data;
                    }
                } while (!didEnqueue);
            },
        });
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
                    Math.round((event.loaded * 100) / event.total),
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

const createDownloadClient = (token: string): DownloadClient => {
    const timeout = 300000; // 5 minute
    if (token) {
        return new PhotosDownloadClient(token, timeout);
    } else {
        return new PublicAlbumsDownloadClient(timeout);
    }
};

async function getRenderableFileURL(
    file: EnteFile,
    fileBlob: Blob,
    originalFileURL: string,
    forceConvert: boolean,
): Promise<SourceURLs> {
    const existingOrNewObjectURL = (convertedBlob: Blob) =>
        convertedBlob
            ? convertedBlob === fileBlob
                ? originalFileURL
                : URL.createObjectURL(convertedBlob)
            : undefined;

    let url: SourceURLs["url"];
    let isOriginal: boolean;
    let isRenderable: boolean;
    let type: SourceURLs["type"] = "normal";
    let mimeType: string | undefined;

    switch (file.metadata.fileType) {
        case FILE_TYPE.IMAGE: {
            const convertedBlob = await getRenderableImage(
                file.metadata.title,
                fileBlob,
            );
            const convertedURL = existingOrNewObjectURL(convertedBlob);
            url = convertedURL;
            isOriginal = convertedURL === originalFileURL;
            isRenderable = !!convertedURL;
            mimeType = convertedBlob?.type;
            break;
        }
        case FILE_TYPE.LIVE_PHOTO: {
            url = await getRenderableLivePhotoURL(file, fileBlob, forceConvert);
            isOriginal = false;
            isRenderable = false;
            type = "livePhoto";
            break;
        }
        case FILE_TYPE.VIDEO: {
            const convertedBlob = await getPlayableVideo(
                file.metadata.title,
                fileBlob,
                forceConvert,
            );
            const convertedURL = existingOrNewObjectURL(convertedBlob);
            url = convertedURL;
            isOriginal = convertedURL === originalFileURL;
            isRenderable = !!convertedURL;
            mimeType = convertedBlob?.type;
            break;
        }
        default: {
            url = originalFileURL;
            isOriginal = true;
            isRenderable = false;
            break;
        }
    }

    return { url, isOriginal, isRenderable, type, mimeType };
}

async function getRenderableLivePhotoURL(
    file: EnteFile,
    fileBlob: Blob,
    forceConvert: boolean,
): Promise<LivePhotoSourceURL> {
    const livePhoto = await decodeLivePhoto(file.metadata.title, fileBlob);

    const getRenderableLivePhotoImageURL = async () => {
        try {
            const imageBlob = new Blob([livePhoto.imageData]);
            const convertedImageBlob = await getRenderableImage(
                livePhoto.imageFileName,
                imageBlob,
            );

            return URL.createObjectURL(convertedImageBlob);
        } catch (e) {
            //ignore and return null
            return null;
        }
    };

    const getRenderableLivePhotoVideoURL = async () => {
        try {
            const videoBlob = new Blob([livePhoto.videoData]);
            const convertedVideoBlob = await getPlayableVideo(
                livePhoto.videoFileName,
                videoBlob,
                forceConvert,
                true,
            );
            return URL.createObjectURL(convertedVideoBlob);
        } catch (e) {
            //ignore and return null
            return null;
        }
    };

    return {
        image: getRenderableLivePhotoImageURL,
        video: getRenderableLivePhotoVideoURL,
    };
}

async function getPlayableVideo(
    videoNameTitle: string,
    videoBlob: Blob,
    forceConvert = false,
    runOnWeb = false,
) {
    try {
        const isPlayable = await isPlaybackPossible(
            URL.createObjectURL(videoBlob),
        );
        if (isPlayable && !forceConvert) {
            return videoBlob;
        } else {
            if (!forceConvert && !runOnWeb && !isElectron()) {
                return null;
            }
            log.info(`Converting video ${videoNameTitle} to mp4`);
            const convertedVideoData = await ffmpeg.convertToMP4(videoBlob);
            return new Blob([convertedVideoData], { type: "video/mp4" });
        }
    } catch (e) {
        log.error("Video conversion failed", e);
        return null;
    }
}
