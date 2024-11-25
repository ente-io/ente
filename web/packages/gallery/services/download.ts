import { isDesktop } from "@/base/app";
import { blobCache, type BlobCache } from "@/base/blob-cache";
import {
    decryptStreamBytes,
    decryptStreamChunk,
    decryptThumbnail,
    initChunkDecryption,
} from "@/base/crypto";
import {
    authenticatedRequestHeaders,
    clientPackageHeader,
    retryEnsuringHTTPOk,
} from "@/base/http";
import { ensureAuthToken } from "@/base/local-user";
import log from "@/base/log";
import { customAPIOrigin } from "@/base/origins";
import {
    playableVideoBlob,
    renderableImageBlob,
} from "@/gallery/utils/convert";
import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";

export interface LivePhotoSourceURL {
    image: () => Promise<string | undefined>;
    video: () => Promise<string | undefined>;
}

export interface LoadedLivePhotoSourceURL {
    image: string;
    video: string;
}

export interface SourceURLs {
    url: string | LivePhotoSourceURL | LoadedLivePhotoSourceURL;
    type: "normal" | "livePhoto";
    /**
     * `true` if there is potential conversion that can still be applied.
     *
     * See: [Note: Forcing conversion of playable videos]
     */
    canForceConvert?: boolean;
    /**
     * Best effort attempt at obtaining the MIME type.
     *
     * It will only be present for images generally, which is also the only
     * scenario where it is needed currently (by the image editor).
     *
     * Known cases where it is missing:
     *
     * - Live photos (these have a different code path for obtaining the URL).
     * - A video that is passes the isPlayable test in the browser.
     */
    mimeType?: string;
}

/**
 * A class that tracks the state of in-progress downloads and conversions,
 * including caching them for subsequent retrieval if appropriate.
 *
 * External code can use it via its singleton instance, {@link downloadManager}.
 * The class will initialize itself on first use, however {@link logout} should
 * be called on logout to reset its internal state.
 */
class DownloadManager {
    /**
     * Credentials that should be used to download files when we're in the
     * context of the public albums app.
     */
    private publicAlbumsCredentials: PublicAlbumsCredentials | undefined;
    /**
     * Local cache for thumbnail blobs.
     *
     * `undefined` indicates that the cache has not yet been initialized. It is
     * also possible that the cache might not be available, in which case it'd
     * be set to `null`.
     */
    private thumbnailCache: BlobCache | null | undefined;
    /**
     * An in-memory cache for an object URL to a file's thumbnail.
     *
     * This object URL can be directly used to render the thumbnail (e.g. in an
     * img tag). The entries are keyed by the file ID.
     */
    private thumbnailURLPromises = new Map<
        number,
        Promise<string | undefined>
    >();
    /**
     * An in-memory cache for an object URL to a file's original data.
     *
     * Unlike {@link thumbnailURLPromises}, there is no guarantee that the
     * browser will be able to render the original file (e.g. it might be in an
     * unsupported format). If a renderable URL is needed for the file,
     * {@link renderableFileData} should be used instead.
     *
     * The entries are keyed by the file ID.
     */
    private fileURLPromises = new Map<number, Promise<string>>();
    private fileConversionPromises = new Map<number, Promise<SourceURLs>>();

    /**
     * A map from file ID to the progress (0-100%) of its active download (if
     * any).
     *
     * [Note: Tracking active file download progress in the UI]
     *
     * The download manager maintains a map of download progress for all files
     * which are being downloaded in a streaming manner (which is currently only
     * videos). The UI can observe this by using {@link useSyncExternalStore} in
     * combination with the {@link fileDownloadProgressSubscribe} and
     * {@link fileDownloadProgressSnapshot} methods of the download manager.
     */
    private fileDownloadProgress = new Map<number, number>();
    private fileDownloadProgressListeners: (() => void)[] = [];

    private async initThumbnailCacheIfNeeded() {
        if (this.thumbnailCache === undefined) {
            try {
                this.thumbnailCache = await blobCache("thumbs");
            } catch (e) {
                this.thumbnailCache = null;
                log.error(
                    "Failed to open thumbnail cache, will continue without it",
                    e,
                );
            }
        }
    }

    /**
     * Reset the internal state of the download manager.
     */
    logout() {
        this.publicAlbumsCredentials = undefined;
        this.thumbnailURLPromises.clear();
        this.fileURLPromises.clear();
        this.fileConversionPromises.clear();
        this.fileDownloadProgress.clear();
        this.fileDownloadProgressListeners = [];
    }

    /**
     * Set the credentials that should be used for download files when we're
     * running in the context of the public albums app.
     */
    setPublicAlbumsCredentials(
        token: string,
        passwordToken: string | undefined,
    ) {
        this.publicAlbumsCredentials = {
            accessToken: token,
            accessTokenJWT: passwordToken,
        };
    }

    /**
     * See: [Note: Tracking active file download progress in the UI]
     */
    fileDownloadProgressSubscribe(onChange: () => void) {
        this.fileDownloadProgressListeners.push(onChange);
        return () => {
            this.fileDownloadProgressListeners =
                this.fileDownloadProgressListeners.filter((l) => l != onChange);
        };
    }

    /**
     * See: [Note: Tracking active file download progress in the UI]
     */
    fileDownloadProgressSnapshot() {
        return this.fileDownloadProgress;
    }

    private setFileDownloadProgress(progress: Map<number, number>) {
        this.fileDownloadProgress = progress;
        this.fileDownloadProgressListeners.forEach((l) => l());
    }

    /**
     * Resolves with an URL that points to the file's thumbnail.
     *
     * The thumbnail will be downloaded if needed (unless {@link cachedOnly} is
     * true). It will also be cached for subsequent fetches.
     *
     * The optional {@link cachedOnly} parameter can be set to indicate that
     * this is being called as part of a scroll, so the downloader should not
     * attempt to download the file but should instead fulfill the request from
     * the disk cache. This avoids an unbounded flurry of requests on scroll,
     * only downloading when the position has quiescized.
     *
     * The returned URL is actually an object URL, but it should not be revoked
     * since the download manager caches it for future use.
     */
    async renderableThumbnailURL(
        file: EnteFile,
        cachedOnly = false,
    ): Promise<string | undefined> {
        if (!this.thumbnailURLPromises.has(file.id)) {
            const url = this.thumbnailData(file, cachedOnly).then((data) =>
                data ? URL.createObjectURL(new Blob([data])) : undefined,
            );
            this.thumbnailURLPromises.set(file.id, url);
        }

        let thumb = await this.thumbnailURLPromises.get(file.id);
        if (cachedOnly) return thumb;

        if (!thumb) {
            this.thumbnailURLPromises.delete(file.id);
            thumb = await this.renderableThumbnailURL(file);
        }
        return thumb;
    }

    /**
     * Returns the thumbnail data for a file, downloading it if needed.
     *
     * The data is cached on disk for subsequent fetches.
     *
     * @param file The {@link EnteFile} whose thumbnail we want.
     *
     * @param cachedOnly If true, then the thumbnail is not downloaded if it is
     * not already present in the disk cache.
     *
     * @returns The bytes of the thumbnail, as a {@link Uint8Array}. This method
     * can return `undefined` iff the thumbnail is not already cached, and
     * {@link cachedOnly} is set to `true`.
     */
    async thumbnailData(file: EnteFile, cachedOnly = false) {
        await this.initThumbnailCacheIfNeeded();

        const key = file.id.toString();
        const cached = await this.thumbnailCache?.get(key);
        if (cached) return new Uint8Array(await cached.arrayBuffer());
        if (cachedOnly) return undefined;

        const thumb = await this.downloadThumbnail(file);
        await this.thumbnailCache?.put(key, new Blob([thumb]));
        return thumb;
    }

    private downloadThumbnail = async (file: EnteFile) => {
        const encryptedData = await this._downloadThumbnail(file);
        const decryptionHeader = file.thumbnail.decryptionHeader;
        return decryptThumbnail({ encryptedData, decryptionHeader }, file.key);
    };

    private async _downloadThumbnail(file: EnteFile) {
        if (this.publicAlbumsCredentials) {
            return publicAlbums_downloadThumbnail(
                file,
                this.publicAlbumsCredentials,
            );
        } else {
            return photos_downloadThumbnail(file);
        }
    }

    /**
     * The `forceConvert` option is true when the user presses the "Convert"
     * button. See: [Note: Forcing conversion of playable videos].
     */
    getFileForPreview = async (
        file: EnteFile,
        opts?: { forceConvert?: boolean },
    ): Promise<SourceURLs | undefined> => {
        try {
            const forceConvert = opts?.forceConvert ?? false;
            const getFileForPreviewPromise = async () => {
                const originalFileURL =
                    await this.fileURLDownloadAndCacheIfNeeded(file);
                const res = await fetch(originalFileURL);
                const fileBlob = await res.blob();
                const converted = await getRenderableFileURL(
                    file,
                    fileBlob,
                    originalFileURL,
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

    /**
     * Return a blob to the file's contents, downloading it needed.
     *
     * This is a convenience abstraction over {@link fileStream} that converts
     * it into a {@link Blob}.
     */
    async fileBlob(file: EnteFile) {
        return this.fileStream(file).then((s) => new Response(s).blob());
    }

    /**
     * Return an stream to the file's contents, downloading it needed.
     *
     * Note that the results are not cached in-memory. That is, while the
     * request may be served from the existing item in the in-memory cache, if
     * it is not found and a download is required, that result will not be
     * cached for subsequent use.
     *
     * @param file The {@link EnteFile} whose data we want.
     */
    async fileStream(
        file: EnteFile,
    ): Promise<ReadableStream<Uint8Array> | null> {
        const cachedURL = this.fileURLPromises.get(file.id);
        if (cachedURL) {
            try {
                const url = await cachedURL;
                const res = await fetch(url);
                return res.body;
            } catch (e) {
                log.warn("Failed to use cached object URL", e);
                this.fileURLPromises.delete(file.id);
            }
        }

        return this.downloadFile(file);
    }

    /**
     * A private variant of {@link fileStream} that also caches the results.
     */
    private async fileURLDownloadAndCacheIfNeeded(file: EnteFile) {
        const cachedURL = this.fileURLPromises.get(file.id);
        if (cachedURL) return cachedURL;

        const url = this.downloadFile(file)
            .then((stream) => new Response(stream).blob())
            .then((blob) => URL.createObjectURL(blob));
        this.fileURLPromises.set(file.id, url);

        try {
            return await url;
        } catch (e) {
            this.fileURLPromises.delete(file.id);
            throw e;
        }
    }

    private async downloadFile(
        file: EnteFile,
    ): Promise<ReadableStream<Uint8Array> | null> {
        log.info(`download attempted for file id ${file.id}`);

        const res = await this._downloadFile(file);

        if (
            file.metadata.fileType === FileType.image ||
            file.metadata.fileType === FileType.livePhoto
        ) {
            const encryptedData = new Uint8Array(await res.arrayBuffer());

            const decrypted = await decryptStreamBytes(
                {
                    encryptedData,
                    decryptionHeader: file.file.decryptionHeader,
                },
                file.key,
            );
            return new Response(decrypted).body;
        }

        const body = res.body;
        if (!body) return null;
        const reader = body.getReader();

        const onDownloadProgress = this.trackDownloadProgress(
            file.id,
            // TODO: Is info supposed to be optional though?
            file.info?.fileSize ?? 0,
        );

        const contentLength =
            parseInt(res.headers.get("Content-Length") ?? "") || 0;
        let downloadedBytes = 0;

        const { pullState, decryptionChunkSize } = await initChunkDecryption(
            file.file.decryptionHeader,
            file.key,
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
                        const decryptedData = await decryptStreamChunk(
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
                            const decryptedData = await decryptStreamChunk(
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

    private async _downloadFile(file: EnteFile) {
        if (this.publicAlbumsCredentials) {
            return publicAlbums_downloadFile(
                file,
                this.publicAlbumsCredentials,
            );
        } else {
            return photos_downloadFile(file);
        }
    }

    private trackDownloadProgress(fileID: number, fileSize: number) {
        return (event: { loaded: number; total: number }) => {
            if (isNaN(event.total) || event.total === 0) {
                if (!fileSize) {
                    return;
                }
                event.total = fileSize;
            }
            const progress = new Map(this.fileDownloadProgress);
            if (event.loaded === event.total) {
                progress.delete(fileID);
            } else {
                progress.set(
                    fileID,
                    Math.round((event.loaded * 100) / event.total),
                );
            }
            this.setFileDownloadProgress(progress);
        };
    }
}

/**
 * Singleton instance of {@link DownloadManager}.
 */
export const downloadManager = new DownloadManager();

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
    let type: SourceURLs["type"] = "normal";
    let mimeType: string | undefined;
    let canForceConvert = false;

    const fileName = file.metadata.title;
    switch (file.metadata.fileType) {
        case FileType.image: {
            const convertedBlob = await renderableImageBlob(fileName, fileBlob);
            const convertedURL = existingOrNewObjectURL(convertedBlob);
            url = convertedURL;
            mimeType = convertedBlob.type;
            break;
        }
        case FileType.livePhoto: {
            url = await getRenderableLivePhotoURL(file, fileBlob);
            type = "livePhoto";
            break;
        }
        case FileType.video: {
            const convertedBlob = await playableVideoBlob(
                fileName,
                fileBlob,
                forceConvert,
            );
            const convertedURL = existingOrNewObjectURL(convertedBlob);
            url = convertedURL;
            mimeType = convertedBlob?.type;

            const isOriginal = convertedURL === originalFileURL;
            const isRenderable = !!convertedURL;
            canForceConvert =
                isDesktop && !forceConvert && isOriginal && isRenderable;

            break;
        }
        default: {
            url = originalFileURL;
            break;
        }
    }

    // TODO: Can we remove this non-null assertion and reflect it in the types?
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return {
        url: url!,
        type,
        mimeType,
        canForceConvert,
    };
}

async function getRenderableLivePhotoURL(
    file: EnteFile,
    fileBlob: Blob,
): Promise<LivePhotoSourceURL | undefined> {
    const livePhoto = await decodeLivePhoto(file.metadata.title, fileBlob);

    const getRenderableLivePhotoImageURL = async () => {
        try {
            const imageBlob = new Blob([livePhoto.imageData]);
            return URL.createObjectURL(
                await renderableImageBlob(livePhoto.imageFileName, imageBlob),
            );
        } catch {
            //ignore and return null
            return undefined;
        }
    };

    const getRenderableLivePhotoVideoURL = async () => {
        try {
            const videoBlob = new Blob([livePhoto.videoData]);
            const convertedVideoBlob = await playableVideoBlob(
                livePhoto.videoFileName,
                videoBlob,
                false,
            );
            if (!convertedVideoBlob) return undefined;
            return URL.createObjectURL(convertedVideoBlob);
        } catch {
            //ignore and return null
            return undefined;
        }
    };

    return {
        image: getRenderableLivePhotoImageURL,
        video: getRenderableLivePhotoVideoURL,
    };
}

/**
 * The various photos_* functions are used for the actual downloads when
 * we're running in the context of the the photos app.
 */
const photos_downloadThumbnail = async (file: EnteFile) => {
    const customOrigin = await customAPIOrigin();

    const getThumbnail = async () => {
        if (customOrigin) {
            // See: [Note: Passing credentials for self-hosted file fetches]
            const token = await ensureAuthToken();
            const params = new URLSearchParams({ token });
            return fetch(
                `${customOrigin}/files/preview/${file.id}?${params.toString()}`,
                {
                    headers: clientPackageHeader(),
                },
            );
        } else {
            return fetch(`https://thumbnails.ente.io/?fileID=${file.id}`, {
                headers: await authenticatedRequestHeaders(),
            });
        }
    };

    const res = await retryEnsuringHTTPOk(getThumbnail);
    return new Uint8Array(await res.arrayBuffer());
};

const photos_downloadFile = async (file: EnteFile): Promise<Response> => {
    const customOrigin = await customAPIOrigin();

    // [Note: Passing credentials for self-hosted file fetches]
    //
    // Fetching files (or thumbnails) in the default self-hosted Ente
    // configuration involves a redirection:
    //
    // 1. The browser makes a HTTP GET to a museum with credentials. Museum
    //    inspects the credentials, in this case the auth token, and if they're
    //    valid, returns a HTTP 307 redirect to the pre-signed S3 URL that to
    //    the file in the configured S3 bucket.
    //
    // 2. The browser follows the redirect to get the actual file. The URL is
    //    pre-signed, i.e. already has all credentials needed to prove to the S3
    //    object storage that it should serve this response.
    //
    // For the first step normally we'd pass the auth the token via the
    // "X-Auth-Token" HTTP header. In this case though, that would be
    // problematic because the browser preserves the request headers when it
    // follows the HTTP 307 redirect, and the "X-Auth-Token" header also gets
    // sent to the redirected S3 request made in second step.
    //
    // To avoid this, we pass the token as a query parameter. Generally this is
    // not a good idea, but in this case (a) the URL is not a user visible one
    // and (b) even if it gets logged, it'll be in the self-hosters own service.
    //
    // Note that Ente's own servers don't have these concerns because we use a
    // slightly different flow involving a proxy instead of directly connecting
    // to the S3 storage.
    //
    // 1. The web browser makes a HTTP GET request to a proxy passing it the
    //    credentials in the "X-Auth-Token".
    //
    // 2. The proxy then does both the original steps: (a). Use the credentials
    //    to get the pre signed URL, and (b) fetch that pre signed URL and
    //    stream back the response.

    const getFile = async () => {
        if (customOrigin) {
            const token = await ensureAuthToken();
            const params = new URLSearchParams({ token });
            return fetch(
                `${customOrigin}/files/download/${file.id}?${params.toString()}`,
                {
                    headers: clientPackageHeader(),
                },
            );
        } else {
            return fetch(`https://files.ente.io/?fileID=${file.id}`, {
                headers: await authenticatedRequestHeaders(),
            });
        }
    };

    return retryEnsuringHTTPOk(getFile);
};

interface PublicAlbumsCredentials {
    accessToken: string;
    accessTokenJWT: string | undefined;
}

/**
 * The various publicAlbums_* functions are used for the actual downloads when
 * we're running in the context of the the public albums app.
 */
const publicAlbums_downloadThumbnail = async (
    file: EnteFile,
    { accessToken, accessTokenJWT }: PublicAlbumsCredentials,
) => {
    const customOrigin = await customAPIOrigin();

    const getThumbnail = async () => {
        if (customOrigin) {
            // See: [Note: Passing credentials for self-hosted file fetches]
            const params = new URLSearchParams({
                accessToken,
                ...(accessTokenJWT ? { accessTokenJWT } : {}),
            });
            return fetch(
                `${customOrigin}/public-collection/files/preview/${file.id}?${params.toString()}`,
                {
                    headers: clientPackageHeader(),
                },
            );
        } else {
            return fetch(
                `https://public-albums.ente.io/preview/?fileID=${file.id}`,
                {
                    headers: {
                        ...clientPackageHeader(),
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT
                            ? { "X-Auth-Access-Token-JWT": accessTokenJWT }
                            : {}),
                    },
                },
            );
        }
    };

    const res = await retryEnsuringHTTPOk(getThumbnail);
    return new Uint8Array(await res.arrayBuffer());
};

const publicAlbums_downloadFile = async (
    file: EnteFile,
    { accessToken, accessTokenJWT }: PublicAlbumsCredentials,
) => {
    const customOrigin = await customAPIOrigin();

    // See: [Note: Passing credentials for self-hosted file fetches]
    const getFile = () => {
        if (customOrigin) {
            const params = new URLSearchParams({
                accessToken,
                ...(accessTokenJWT ? { accessTokenJWT } : {}),
            });
            return fetch(
                `${customOrigin}/public-collection/files/download/${file.id}?${params.toString()}`,
            );
        } else {
            return fetch(
                `https://public-albums.ente.io/download/?fileID=${file.id}`,
                {
                    headers: {
                        ...clientPackageHeader(),
                        "X-Auth-Access-Token": accessToken,
                        ...(accessTokenJWT
                            ? { "X-Auth-Access-Token-JWT": accessTokenJWT }
                            : {}),
                    },
                },
            );
        }
    };

    return retryEnsuringHTTPOk(getFile);
};
