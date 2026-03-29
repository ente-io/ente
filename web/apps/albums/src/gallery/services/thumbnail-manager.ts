import { blobCache, type BlobCache } from "ente-base/blob-cache";
import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    publicRequestHeaders,
    retryEnsuringHTTPOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import log from "ente-base/log";
import { customAPIOrigin } from "ente-base/origins";
import { ensureAuthToken } from "ente-base/token";
import type { EnteFile } from "ente-media/file";
import {
    getPublicAlbumsCredentials,
    setPublicAlbumsCredentials,
} from "./public-albums-credentials";
import { decryptThumbnailBlobBytes } from "./thumbnail-crypto";

class ThumbnailManager {
    private thumbnailCache: BlobCache | null | undefined;
    private thumbnailURLPromises = new Map<number, Promise<string | undefined>>();

    get publicAlbumsCredentials() {
        return getPublicAlbumsCredentials();
    }

    setPublicAlbumsCredentials(
        credentials: PublicAlbumsCredentials | undefined,
    ) {
        setPublicAlbumsCredentials(credentials);
    }

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

        let thumb: string | undefined;
        try {
            thumb = await this.thumbnailURLPromises.get(file.id);
        } catch (e) {
            this.thumbnailURLPromises.delete(file.id);
            throw e;
        }

        if (cachedOnly) return thumb;

        if (!thumb) {
            this.thumbnailURLPromises.delete(file.id);
            thumb = await this.renderableThumbnailURL(file);
        }
        return thumb;
    }

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
        const encryptedData = await wrapErrors(() =>
            this._downloadThumbnail(file),
        );
        const decryptionHeader = file.thumbnail.decryptionHeader;
        return decryptThumbnailBlobBytes(
            { encryptedData, decryptionHeader },
            file.key,
        );
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
}

export const thumbnailManager = new ThumbnailManager();

class NetworkThumbnailError extends Error {
    error: unknown;

    constructor(e: unknown) {
        super(
            `NetworkThumbnailError: ${e instanceof Error ? e.message : String(e)}`,
        );

        if (Error.captureStackTrace)
            Error.captureStackTrace(this, NetworkThumbnailError);

        this.error = e;
    }
}

const wrapErrors = <T>(op: () => Promise<T>) =>
    op().catch((e: unknown) => {
        throw new NetworkThumbnailError(e);
    });

const photos_downloadThumbnail = async (file: EnteFile) => {
    const customOrigin = await customAPIOrigin();

    const getThumbnail = async () => {
        if (customOrigin) {
            const token = await ensureAuthToken();
            const params = new URLSearchParams({ token });
            return fetch(
                `${customOrigin}/files/preview/${file.id}?${params.toString()}`,
                { headers: publicRequestHeaders() },
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

const publicAlbums_downloadThumbnail = async (
    file: EnteFile,
    credentials: PublicAlbumsCredentials,
) => {
    const customOrigin = await customAPIOrigin();

    const getThumbnail = async () => {
        if (customOrigin) {
            const { accessToken, accessTokenJWT } = credentials;
            const params = new URLSearchParams({
                accessToken,
                ...(accessTokenJWT && { accessTokenJWT }),
            });
            return fetch(
                `${customOrigin}/public-collection/files/preview/${file.id}?${params.toString()}`,
                { headers: publicRequestHeaders() },
            );
        } else {
            return fetch(
                `https://public-albums.ente.io/preview/?fileID=${file.id}`,
                {
                    headers:
                        authenticatedPublicAlbumsRequestHeaders(credentials),
                },
            );
        }
    };

    const res = await retryEnsuringHTTPOk(getThumbnail);
    return new Uint8Array(await res.arrayBuffer());
};
