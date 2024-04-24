import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import { openCache, type BlobCache } from "@/next/blob-cache";
import log from "@/next/log";
import { APPS } from "@ente/shared/apps/constants";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { isPlaybackPossible } from "@ente/shared/media/video-playback";
import { Remote } from "comlink";
import isElectron from "is-electron";
import * as ffmpegService from "services/ffmpeg";
import { EnteFile } from "types/file";
import { generateStreamFromArrayBuffer, getRenderableImage } from "utils/file";
import { PhotosDownloadClient } from "./clients/photos";
import { PublicAlbumsDownloadClient } from "./clients/publicAlbums";

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
    type: "normal" | "livePhoto";
};

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

    async init(
        app: APPS,
        tokens?: { token: string; passwordToken?: string } | { token: string },
    ) {
        if (this.ready) {
            log.info("DownloadManager already initialized");
            return;
        }
        this.downloadClient = createDownloadClient(app, tokens);
        try {
            this.thumbnailCache = await openCache("thumbs");
        } catch (e) {
            log.error(
                "Failed to open thumbnail cache, will continue without it",
                e,
            );
        }
        // TODO (MR): Revisit full file caching cf disk space usage
        // try {
        //     if (isElectron()) this.fileCache = await openCache("files");
        // } catch (e) {
        //     log.error("Failed to open file cache, will continue without it", e);
        // }
        this.cryptoWorker = await ComlinkCryptoWorker.getInstance();
        this.ready = true;
        eventBus.on(Events.LOGOUT, this.logoutHandler.bind(this), this);
    }

    private ensureInitialized() {
        if (!this.ready)
            throw new Error(
                "Attempting to use an uninitialized download manager",
            );
    }

    private async logoutHandler() {
        try {
            log.info("downloadManger logoutHandler started");
            this.ready = false;
            this.cryptoWorker = null;
            this.downloadClient = null;
            this.fileObjectURLPromises.clear();
            this.fileConversionPromises.clear();
            this.thumbnailObjectURLPromises.clear();
            this.fileDownloadProgress.clear();
            this.progressUpdater = () => {};
            log.info("downloadManager logoutHandler completed");
        } catch (e) {
            log.error("downloadManager logoutHandler failed", e);
        }
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
        const cached = await this.thumbnailCache.get(key);
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
                return generateStreamFromArrayBuffer(decrypted);
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
            this.fileCache?.put(cacheKey, await res.blob());
        }
        const reader = res.body.getReader();

        const contentLength = +res.headers.get("Content-Length") ?? 0;
        let downloadedBytes = 0;

        const stream = new ReadableStream({
            start: async (controller) => {
                try {
                    const decryptionHeader = await this.cryptoWorker.fromB64(
                        file.file.decryptionHeader,
                    );
                    const fileKey = await this.cryptoWorker.fromB64(file.key);
                    const { pullState, decryptionChunkSize } =
                        await this.cryptoWorker.initChunkDecryption(
                            decryptionHeader,
                            fileKey,
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
                                        data.byteLength + value.byteLength,
                                    );
                                    buffer.set(new Uint8Array(data), 0);
                                    buffer.set(
                                        new Uint8Array(value),
                                        data.byteLength,
                                    );
                                    if (buffer.length > decryptionChunkSize) {
                                        const fileData = buffer.slice(
                                            0,
                                            decryptionChunkSize,
                                        );
                                        try {
                                            const { decryptedData } =
                                                await this.cryptoWorker.decryptFileChunk(
                                                    fileData,
                                                    pullState,
                                                );
                                            controller.enqueue(decryptedData);
                                            data =
                                                buffer.slice(
                                                    decryptionChunkSize,
                                                );
                                        } catch (e) {
                                            if (
                                                e.message ===
                                                CustomError.PROCESSING_FAILED
                                            ) {
                                                log.error(
                                                    `Failed to process file ${file.id} from localID: ${file.metadata.localID} version: ${file.metadata.version} deviceFolder:${file.metadata.deviceFolder}`,
                                                    e,
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
                                                    pullState,
                                                );
                                            controller.enqueue(decryptedData);
                                            data = null;
                                        } catch (e) {
                                            if (
                                                e.message ===
                                                CustomError.PROCESSING_FAILED
                                            ) {
                                                log.error(
                                                    `Failed to process file ${file.id} from localID: ${file.metadata.localID} version: ${file.metadata.version} deviceFolder:${file.metadata.deviceFolder}`,
                                                    e,
                                                );
                                            }
                                            throw e;
                                        }
                                    }
                                    controller.close();
                                }
                            } catch (e) {
                                log.error("Failed to process file chunk", e);
                                controller.error(e);
                            }
                        });
                    };

                    push();
                } catch (e) {
                    log.error("Failed to process file stream", e);
                    controller.error(e);
                }
            },
        });

        return stream;
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

function createDownloadClient(
    app: APPS,
    tokens?: { token: string; passwordToken?: string } | { token: string },
): DownloadClient {
    const timeout = 300000; // 5 minute
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

async function getRenderableFileURL(
    file: EnteFile,
    fileBlob: Blob,
    originalFileURL: string,
    forceConvert: boolean,
): Promise<SourceURLs> {
    let srcURLs: SourceURLs["url"];
    switch (file.metadata.fileType) {
        case FILE_TYPE.IMAGE: {
            const convertedBlob = await getRenderableImage(
                file.metadata.title,
                fileBlob,
            );
            const convertedURL = getFileObjectURL(
                originalFileURL,
                fileBlob,
                convertedBlob,
            );
            srcURLs = convertedURL;
            break;
        }
        case FILE_TYPE.LIVE_PHOTO: {
            srcURLs = await getRenderableLivePhotoURL(
                file,
                fileBlob,
                forceConvert,
            );
            break;
        }
        case FILE_TYPE.VIDEO: {
            const convertedBlob = await getPlayableVideo(
                file.metadata.title,
                fileBlob,
                forceConvert,
            );
            const convertedURL = getFileObjectURL(
                originalFileURL,
                fileBlob,
                convertedBlob,
            );
            srcURLs = convertedURL;
            break;
        }
        default: {
            srcURLs = originalFileURL;
            break;
        }
    }

    let isOriginal: boolean;
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        isOriginal = false;
    } else {
        isOriginal = (srcURLs as string) === (originalFileURL as string);
    }

    return {
        url: srcURLs,
        isOriginal,
        isRenderable:
            file.metadata.fileType !== FILE_TYPE.LIVE_PHOTO && !!srcURLs,
        type:
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
                ? "livePhoto"
                : "normal",
    };
}

const getFileObjectURL = (
    originalFileURL: string,
    originalBlob: Blob,
    convertedBlob: Blob,
) => {
    const convertedURL = convertedBlob
        ? convertedBlob === originalBlob
            ? originalFileURL
            : URL.createObjectURL(convertedBlob)
        : null;
    return convertedURL;
};

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
            log.info(
                `video format not supported, converting it name: ${videoNameTitle}`,
            );
            const mp4ConvertedVideo = await ffmpegService.convertToMP4(
                new File([videoBlob], videoNameTitle),
            );
            log.info(`video successfully converted ${videoNameTitle}`);
            return new Blob([mp4ConvertedVideo]);
        }
    } catch (e) {
        log.error("video conversion failed", e);
        return null;
    }
}
