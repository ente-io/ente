// TODO: Audit this file
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    ensureOk,
    retryAsyncOperation,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import log from "ente-base/log";
import { apiURL, uploaderOrigin } from "ente-base/origins";
import { type EnteFile } from "ente-media/file";
import { CustomError, handleUploadError } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";
import { z } from "zod";
import type { MultipartUploadURLs, UploadFile } from "./upload-service";

/**
 * A pre-signed URL alongwith the associated object key.
 */
const ObjectUploadURL = z.object({
    /** A pre-signed URL that can be used to upload data to S3. */
    objectKey: z.string(),
    /** The objectKey with which remote will refer to this object. */
    url: z.string(),
});

export type ObjectUploadURL = z.infer<typeof ObjectUploadURL>;

const ObjectUploadURLResponse = z.object({ urls: ObjectUploadURL.array() });

/**
 * Lowest layer for file upload related HTTP operations when we're running in
 * the context of the photos app.
 */
export class PhotosUploadHTTPClient {
    async uploadFile(uploadFile: UploadFile): Promise<EnteFile> {
        try {
            const url = await apiURL("/files");
            const headers = await authenticatedRequestHeaders();
            const response = await retryAsyncOperation(
                () =>
                    HTTPService.post(
                        url,
                        uploadFile,
                        // @ts-ignore
                        null,
                        headers,
                    ),
                handleUploadError,
            );
            return response.data;
        } catch (e) {
            log.error("upload Files Failed", e);
            throw e;
        }
    }

    /**
     * Fetch a fresh list of URLs from remote that can be used to upload files
     * and thumbnails to.
     *
     * @param countHint An approximate number of files that we're expecting to
     * upload.
     *
     * @returns A list of pre-signed object URLs that can be used to upload data
     * to the S3 bucket.
     */
    async fetchUploadURLs(countHint: number) {
        const count = Math.min(50, countHint * 2).toString();
        const params = new URLSearchParams({ count });
        const url = await apiURL("/files/upload-urls");
        const res = await fetch(`${url}?${params.toString()}`, {
            headers: await authenticatedRequestHeaders(),
        });
        ensureOk(res);
        return ObjectUploadURLResponse.parse(await res.json()).urls;
    }

    async fetchMultipartUploadURLs(
        count: number,
    ): Promise<MultipartUploadURLs> {
        try {
            const response = await HTTPService.get(
                await apiURL("/files/multipart-upload-urls"),
                { count },
                await authenticatedRequestHeaders(),
            );

            return response.data.urls;
        } catch (e) {
            log.error("fetch multipart-upload-url failed", e);
            throw e;
        }
    }

    async putFile(
        fileUploadURL: ObjectUploadURL,
        file: Uint8Array,
        progressTracker: unknown,
    ): Promise<string> {
        try {
            await retryAsyncOperation(
                () =>
                    HTTPService.put(
                        fileUploadURL.url,
                        file,
                        // @ts-ignore
                        null,
                        null,
                        progressTracker,
                    ),
                handleUploadError,
            );
            return fileUploadURL.objectKey;
        } catch (e) {
            if (
                !(
                    e instanceof Error &&
                    e.message == CustomError.UPLOAD_CANCELLED
                )
            ) {
                log.error("putFile to dataStore failed ", e);
            }
            throw e;
        }
    }

    async putFileV2(
        fileUploadURL: ObjectUploadURL,
        file: Uint8Array,
        progressTracker: unknown,
    ): Promise<string> {
        try {
            const origin = await uploaderOrigin();
            await retryAsyncOperation(() =>
                HTTPService.put(
                    `${origin}/file-upload`,
                    file,
                    // @ts-ignore
                    null,
                    { "UPLOAD-URL": fileUploadURL.url },
                    progressTracker,
                ),
            );
            return fileUploadURL.objectKey;
        } catch (e) {
            if (
                !(
                    e instanceof Error &&
                    e.message == CustomError.UPLOAD_CANCELLED
                )
            ) {
                log.error("putFile to dataStore failed ", e);
            }
            throw e;
        }
    }

    async putFilePart(
        partUploadURL: string,
        filePart: Uint8Array,
        progressTracker: unknown,
    ) {
        try {
            const response = await retryAsyncOperation(async () => {
                const resp = await HTTPService.put(
                    partUploadURL,
                    filePart,
                    // @ts-ignore
                    null,
                    null,
                    progressTracker,
                );
                // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
                if (!resp?.headers?.etag) {
                    const err = Error(CustomError.ETAG_MISSING);
                    log.error("putFile in parts failed", err);
                    throw err;
                }
                return resp;
            }, handleUploadError);
            return response.headers.etag as string;
        } catch (e) {
            if (
                !(
                    e instanceof Error &&
                    e.message == CustomError.UPLOAD_CANCELLED
                )
            ) {
                log.error("put filePart failed", e);
            }
            throw e;
        }
    }

    async putFilePartV2(
        partUploadURL: string,
        filePart: Uint8Array,
        progressTracker: unknown,
    ) {
        try {
            const origin = await uploaderOrigin();
            const response = await retryAsyncOperation(async () => {
                const resp = await HTTPService.put(
                    `${origin}/multipart-upload`,
                    filePart,
                    // @ts-ignore
                    null,
                    { "UPLOAD-URL": partUploadURL },
                    progressTracker,
                );
                // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
                if (!resp?.data?.etag) {
                    const err = Error(CustomError.ETAG_MISSING);
                    log.error("putFile in parts failed", err);
                    throw err;
                }
                return resp;
            });
            return response.data.etag as string;
        } catch (e) {
            if (
                !(
                    e instanceof Error &&
                    e.message == CustomError.UPLOAD_CANCELLED
                )
            ) {
                log.error("put filePart failed", e);
            }
            throw e;
        }
    }

    async completeMultipartUpload(completeURL: string, reqBody: unknown) {
        try {
            await retryAsyncOperation(() =>
                // @ts-ignore
                HTTPService.post(completeURL, reqBody, null, {
                    "content-type": "text/xml",
                }),
            );
        } catch (e) {
            log.error("put file in parts failed", e);
            throw e;
        }
    }

    async completeMultipartUploadV2(completeURL: string, reqBody: unknown) {
        try {
            const origin = await uploaderOrigin();
            await retryAsyncOperation(() =>
                HTTPService.post(
                    `${origin}/multipart-complete`,
                    reqBody,
                    // @ts-ignore
                    null,
                    { "content-type": "text/xml", "UPLOAD-URL": completeURL },
                ),
            );
        } catch (e) {
            log.error("put file in parts failed", e);
            throw e;
        }
    }
}

/**
 * Lowest layer for file upload related HTTP operations when we're running in
 * the context of the public albums app.
 */
export class PublicAlbumsUploadHTTPClient {
    async uploadFile(
        uploadFile: UploadFile,
        credentials: PublicAlbumsCredentials,
    ): Promise<EnteFile> {
        try {
            const url = await apiURL("/public-collection/file");
            const response = await retryAsyncOperation(
                () =>
                    HTTPService.post(
                        url,
                        uploadFile,
                        // @ts-ignore
                        null,
                        authenticatedPublicAlbumsRequestHeaders(credentials),
                    ),
                handleUploadError,
            );
            return response.data;
        } catch (e) {
            log.error("upload public File Failed", e);
            throw e;
        }
    }

    /**
     * Sibling of {@link fetchUploadURLs} for public albums.
     */
    async fetchUploadURLs(
        countHint: number,
        credentials: PublicAlbumsCredentials,
    ) {
        const count = Math.min(50, countHint * 2).toString();
        const params = new URLSearchParams({ count });
        const url = await apiURL("/public-collection/upload-urls");
        const res = await fetch(`${url}?${params.toString()}`, {
            headers: authenticatedPublicAlbumsRequestHeaders(credentials),
        });
        ensureOk(res);
        return ObjectUploadURLResponse.parse(await res.json()).urls;
    }

    async fetchMultipartUploadURLs(
        count: number,
        credentials: PublicAlbumsCredentials,
    ): Promise<MultipartUploadURLs> {
        try {
            const response = await HTTPService.get(
                await apiURL("/public-collection/multipart-upload-urls"),
                { count },
                authenticatedPublicAlbumsRequestHeaders(credentials),
            );
            return response.data.urls;
        } catch (e) {
            log.error("fetch public multipart-upload-url failed", e);
            throw e;
        }
    }
}
