// TODO: Remove this override
/* eslint-disable @typescript-eslint/no-empty-function */

import { isDesktop } from "@/base/app";
import { blobCache, type BlobCache } from "@/base/blob-cache";
import { sharedCryptoWorker } from "@/base/crypto";
import { type CryptoWorker } from "@/base/crypto/worker";
import log from "@/base/log";
import { customAPIOrigin } from "@/base/origins";
import { FileType } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import * as ffmpeg from "@/new/photos/services/ffmpeg";
import type {
    EnteFile,
    LivePhotoSourceURL,
    SourceURLs,
} from "@/new/photos/types/file";
import { renderableImageBlob } from "@/new/photos/utils/file";
import { ensure } from "@/utils/ensure";
import { CustomError } from "@ente/shared/error";
import { isPlaybackPossible } from "@ente/shared/media/video-playback";
import HTTPService from "@ente/shared/network/HTTPService";
import { retryAsyncFunction } from "@ente/shared/utils";

export type OnDownloadProgress = (event: {
    loaded: number;
    total: number;
}) => void;

interface DownloadClient {
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
    private ready = false;
    private downloadClient: DownloadClient | undefined;
    /** Local cache for thumbnails. Might not be available. */
    private thumbnailCache?: BlobCache;
    /**
     * Local cache for the files themselves.
     *
     * Only available when we're running in the desktop app.
     */
    private fileCache?: BlobCache;
    private cryptoWorker: CryptoWorker | undefined;

    private fileObjectURLPromises = new Map<number, Promise<SourceURLs>>();
    private fileConversionPromises = new Map<number, Promise<SourceURLs>>();
    private thumbnailObjectURLPromises = new Map<
        number,
        Promise<string | undefined>
    >();

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
        this.cryptoWorker = await sharedCryptoWorker();
        this.ready = true;
    }

    private ensureInitialized() {
        if (!this.ready)
            throw new Error(
                "Attempting to use an uninitialized download manager",
            );

        return {
            downloadClient: ensure(this.downloadClient),
            cryptoWorker: ensure(this.cryptoWorker),
        };
    }

    logout() {
        this.ready = false;
        this.cryptoWorker = undefined;
        this.downloadClient = undefined;
        this.fileObjectURLPromises.clear();
        this.fileConversionPromises.clear();
        this.thumbnailObjectURLPromises.clear();
        this.fileDownloadProgress.clear();
        this.progressUpdater = () => {};
    }

    updateToken(token: string, passwordToken?: string) {
        const { downloadClient } = this.ensureInitialized();
        downloadClient.updateTokens(token, passwordToken);
    }

    setProgressUpdater(progressUpdater: (value: Map<number, number>) => void) {
        this.progressUpdater = progressUpdater;
    }

    private downloadThumb = async (file: EnteFile) => {
        const { downloadClient, cryptoWorker } = this.ensureInitialized();

        const encryptedData = await downloadClient.downloadThumbnail(file);
        const decryptionHeader = file.thumbnail.decryptionHeader;
        return cryptoWorker.decryptThumbnail(
            { encryptedData, decryptionHeader },
            file.key,
        );
    };

    async getThumbnail(file: EnteFile, localOnly = false) {
        this.ensureInitialized();

        const key = file.id.toString();
        const cached = await this.thumbnailCache?.get(key);
        if (cached) return new Uint8Array(await cached.arrayBuffer());
        if (localOnly) return undefined;

        const thumb = await this.downloadThumb(file);
        await this.thumbnailCache?.put(key, new Blob([thumb]));
        return thumb;
    }

    async getThumbnailForPreview(
        file: EnteFile,
        localOnly = false,
    ): Promise<string | undefined> {
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
    ): Promise<SourceURLs | undefined> => {
        this.ensureInitialized();
        try {
            const getFileForPreviewPromise = async () => {
                const fileBlob = await new Response(
                    await this.getFile(file, true),
                ).blob();
                // TODO: Is this ensure valid?
                // The existing code was already dereferencing, so it shouldn't
                // affect behaviour.
                const { url: originalFileURL } = ensure(
                    await this.fileObjectURLPromises.get(file.id),
                );

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
    ): Promise<ReadableStream<Uint8Array> | null> {
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
            // TODO: Is this ensure valid?
            // The existing code was already dereferencing, so it shouldn't
            // affect behaviour.
            const fileURLs = ensure(
                await this.fileObjectURLPromises.get(file.id),
            );
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
    ): Promise<ReadableStream<Uint8Array> | null> {
        const { downloadClient, cryptoWorker } = this.ensureInitialized();

        log.info(`download attempted for file id ${file.id}`);

        const onDownloadProgress = this.trackDownloadProgress(
            file.id,
            // TODO: Is info supposed to be optional though?
            file.info?.fileSize ?? 0,
        );

        const cacheKey = file.id.toString();

        if (
            file.metadata.fileType === FileType.image ||
            file.metadata.fileType === FileType.livePhoto
        ) {
            const cachedBlob = await this.fileCache?.get(cacheKey);
            let encryptedArrayBuffer = await cachedBlob?.arrayBuffer();
            if (!encryptedArrayBuffer) {
                const array = await downloadClient.downloadFile(
                    file,
                    onDownloadProgress,
                );
                encryptedArrayBuffer = array.buffer;
                await this.fileCache?.put(
                    cacheKey,
                    new Blob([encryptedArrayBuffer]),
                );
            }
            this.clearDownloadProgress(file.id);
            try {
                const decrypted = await cryptoWorker.decryptFile(
                    new Uint8Array(encryptedArrayBuffer),
                    await cryptoWorker.fromB64(file.file.decryptionHeader),
                    file.key,
                );
                return new Response(decrypted).body;
            } catch (e) {
                if (
                    e instanceof Error &&
                    e.message == CustomError.PROCESSING_FAILED
                ) {
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
            res = await downloadClient.downloadFileStream(file);
            // We don't have a files cache currently, so this was already a
            // no-op. But even if we had a cache, this seems sus, because
            // res.blob() will read the stream and I'd think then trying to do
            // the subsequent read of the stream again below won't work.

            // this.fileCache?.put(cacheKey, await res.blob());
        }
        const body = res.body;
        if (!body) return null;
        const reader = body.getReader();

        const contentLength =
            parseInt(res.headers.get("Content-Length") ?? "") || 0;
        let downloadedBytes = 0;

        const decryptionHeader = await cryptoWorker.fromB64(
            file.file.decryptionHeader,
        );
        const fileKey = await cryptoWorker.fromB64(file.key);
        const { pullState, decryptionChunkSize } =
            await cryptoWorker.initChunkDecryption(decryptionHeader, fileKey);

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
                            await cryptoWorker.decryptFileChunk(
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
                                await cryptoWorker.decryptFileChunk(
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

const createDownloadClient = (token: string | undefined): DownloadClient => {
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
    const existingOrNewObjectURL = (convertedBlob: Blob | null | undefined) =>
        convertedBlob
            ? convertedBlob === fileBlob
                ? originalFileURL
                : URL.createObjectURL(convertedBlob)
            : undefined;

    let url: SourceURLs["url"] | undefined;
    let isOriginal: boolean;
    let isRenderable: boolean;
    let type: SourceURLs["type"] = "normal";
    let mimeType: string | undefined;

    switch (file.metadata.fileType) {
        case FileType.image: {
            const convertedBlob = await renderableImageBlob(
                file.metadata.title,
                fileBlob,
            );
            const convertedURL = existingOrNewObjectURL(convertedBlob);
            url = convertedURL;
            isOriginal = convertedURL === originalFileURL;
            isRenderable = !!convertedURL;
            mimeType = convertedBlob.type;
            break;
        }
        case FileType.livePhoto: {
            url = await getRenderableLivePhotoURL(file, fileBlob, forceConvert);
            isOriginal = false;
            isRenderable = false;
            type = "livePhoto";
            break;
        }
        case FileType.video: {
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

    // TODO: Can we remove this ensure and reflect it in the types?
    return { url: ensure(url), isOriginal, isRenderable, type, mimeType };
}

async function getRenderableLivePhotoURL(
    file: EnteFile,
    fileBlob: Blob,
    forceConvert: boolean,
): Promise<LivePhotoSourceURL | undefined> {
    const livePhoto = await decodeLivePhoto(file.metadata.title, fileBlob);

    const getRenderableLivePhotoImageURL = async () => {
        try {
            const imageBlob = new Blob([livePhoto.imageData]);
            return URL.createObjectURL(
                await renderableImageBlob(livePhoto.imageFileName, imageBlob),
            );
        } catch (e) {
            //ignore and return null
            return undefined;
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
            if (!convertedVideoBlob) return undefined;
            return URL.createObjectURL(convertedVideoBlob);
        } catch (e) {
            //ignore and return null
            return undefined;
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
            if (!forceConvert && !runOnWeb && !isDesktop) {
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

class PhotosDownloadClient implements DownloadClient {
    constructor(
        private token: string,
        private timeout: number,
    ) {}

    updateTokens(token: string) {
        this.token = token;
    }

    async downloadThumbnail(file: EnteFile): Promise<Uint8Array> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getThumbnail = () => {
            const opts = { responseType: "arraybuffer", timeout: this.timeout };
            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return HTTPService.get(
                    `${customOrigin}/files/preview/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://thumbnails.ente.io/?fileID=${file.id}`,
                    undefined,
                    { "X-Auth-Token": token },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getThumbnail);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        // TODO: Remove this cast (it won't be needed when we migrate this from
        // axios to fetch).
        return new Uint8Array(resp.data as ArrayBuffer);
    }

    async downloadFile(
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ): Promise<Uint8Array> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            const opts = {
                responseType: "arraybuffer",
                timeout: this.timeout,
                onDownloadProgress,
            };

            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return HTTPService.get(
                    `${customOrigin}/files/download/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://files.ente.io/?fileID=${file.id}`,
                    undefined,
                    { "X-Auth-Token": token },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getFile);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        // TODO: Remove this cast (it won't be needed when we migrate this from
        // axios to fetch).
        return new Uint8Array(resp.data as ArrayBuffer);
    }

    async downloadFileStream(file: EnteFile): Promise<Response> {
        const token = this.token;
        if (!token) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // [Note: Passing credentials for self-hosted file fetches]
        //
        // Fetching files (or thumbnails) in the default self-hosted Ente
        // configuration involves a redirection:
        //
        // 1. The browser makes a HTTP GET to a museum with credentials. Museum
        //    inspects the credentials, in this case the auth token, and if
        //    they're valid, returns a HTTP 307 redirect to the pre-signed S3
        //    URL that to the file in the configured S3 bucket.
        //
        // 2. The browser follows the redirect to get the actual file. The URL
        //    is pre-signed, i.e. already has all credentials needed to prove to
        //    the S3 object storage that it should serve this response.
        //
        // For the first step normally we'd pass the auth the token via the
        // "X-Auth-Token" HTTP header. In this case though, that would be
        // problematic because the browser preserves the request headers when it
        // follows the HTTP 307 redirect, and the "X-Auth-Token" header also
        // gets sent to the redirected S3 request made in second step.
        //
        // To avoid this, we pass the token as a query parameter. Generally this
        // is not a good idea, but in this case (a) the URL is not a user
        // visible one and (b) even if it gets logged, it'll be in the
        // self-hosters own service.
        //
        // Note that Ente's own servers don't have these concerns because we use
        // a slightly different flow involving a proxy instead of directly
        // connecting to the S3 storage.
        //
        // 1. The web browser makes a HTTP GET request to a proxy passing it the
        //    credentials in the "X-Auth-Token".
        //
        // 2. The proxy then does both the original steps: (a). Use the
        //    credentials to get the pre signed URL, and (b) fetch that pre
        //    signed URL and stream back the response.

        const getFile = () => {
            if (customOrigin) {
                const params = new URLSearchParams({ token });
                return fetch(
                    `${customOrigin}/files/download/${file.id}?${params.toString()}`,
                );
            } else {
                return fetch(`https://files.ente.io/?fileID=${file.id}`, {
                    headers: {
                        "X-Auth-Token": token,
                    },
                });
            }
        };

        return retryAsyncFunction(getFile);
    }
}

class PublicAlbumsDownloadClient implements DownloadClient {
    private token: string | undefined;
    private passwordToken: string | undefined;

    constructor(private timeout: number) {}

    updateTokens(token: string, passwordToken?: string) {
        this.token = token;
        this.passwordToken = passwordToken;
    }

    downloadThumbnail = async (file: EnteFile) => {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);
        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getThumbnail = () => {
            const opts = {
                responseType: "arraybuffer",
            };

            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return HTTPService.get(
                    `${customOrigin}/public-collection/files/preview/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://public-albums.ente.io/preview/?fileID=${file.id}`,
                    undefined,
                    {
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT && {
                            "X-Auth-Access-Token-JWT": accessTokenJWT,
                        }),
                    },
                    opts,
                );
            }
        };

        const resp = await getThumbnail();
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        // TODO: Remove this cast (it won't be needed when we migrate this from
        // axios to fetch).
        return new Uint8Array(resp.data as ArrayBuffer);
    };

    downloadFile = async (
        file: EnteFile,
        onDownloadProgress: (event: { loaded: number; total: number }) => void,
    ) => {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            const opts = {
                responseType: "arraybuffer",
                timeout: this.timeout,
                onDownloadProgress,
            };

            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return HTTPService.get(
                    `${customOrigin}/public-collection/files/download/${file.id}?${params.toString()}`,
                    undefined,
                    undefined,
                    opts,
                );
            } else {
                return HTTPService.get(
                    `https://public-albums.ente.io/download/?fileID=${file.id}`,
                    undefined,
                    {
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT && {
                            "X-Auth-Access-Token-JWT": accessTokenJWT,
                        }),
                    },
                    opts,
                );
            }
        };

        const resp = await retryAsyncFunction(getFile);
        if (resp.data === undefined) throw Error(CustomError.REQUEST_FAILED);
        // TODO: Remove this cast (it won't be needed when we migrate this from
        // axios to fetch).
        return new Uint8Array(resp.data as ArrayBuffer);
    };

    async downloadFileStream(file: EnteFile): Promise<Response> {
        const accessToken = this.token;
        const accessTokenJWT = this.passwordToken;
        if (!accessToken) throw Error(CustomError.TOKEN_MISSING);

        const customOrigin = await customAPIOrigin();

        // See: [Note: Passing credentials for self-hosted file fetches]
        const getFile = () => {
            if (customOrigin) {
                const params = new URLSearchParams({
                    accessToken,
                    ...(accessTokenJWT && { accessTokenJWT }),
                });
                return fetch(
                    `${customOrigin}/public-collection/files/download/${file.id}?${params.toString()}`,
                );
            } else {
                return fetch(
                    `https://public-albums.ente.io/download/?fileID=${file.id}`,
                    {
                        headers: {
                            "X-Auth-Access-Token": accessToken,
                            ...(accessTokenJWT && {
                                "X-Auth-Access-Token-JWT": accessTokenJWT,
                            }),
                        },
                    },
                );
            }
        };

        return retryAsyncFunction(getFile);
    }
}
