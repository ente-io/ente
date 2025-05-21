// TODO: Audit this file
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    ensureOk,
    publicRequestHeaders,
    retryAsyncOperation,
    retryEnsuringHTTPOk,
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
 * Information about an individual part of a multipart upload that has been
 * uploaded to the remote (S3 or proxy).
 *
 * See: [Note: Multipart uploads].
 */
interface MultipartCompletedPart {
    /**
     * The part number (1-indexed).
     *
     * The part number indicates the sequential ordering where this part belongs
     * in the overall file's data.
     *
     * The part number must start at 1 and the part numbers that get passed to
     * {@link createMultipartUploadRequestBody} must be consecutive.
     */
    partNumber: number;
    /**
     * The part "ETag".
     *
     * This is the Entity tag (retrieved as the "ETag" response header) returned
     * by remote when the part was uploaded.
     */
    etag: string;
}

/**
 * Construct an XML string of the format expected as the request body for
 * {@link _completeMultipartUpload} or {@link _completeMultipartUploadViaProxy}.
 *
 * @param parts Information about the parts that were uploaded.
 */
export const createMultipartUploadRequestBody = (
    parts: MultipartCompletedPart[],
): string => {
    // To avoid introducing a dependency on a XML library, we construct the
    // requisite XML by hand.
    //
    // Example:
    //
    //     <CompleteMultipartUpload>
    //         <Part>
    //             <PartNumber>1</PartNumber>
    //             <ETag>"1b3e6cdb1270c0b664076f109a7137c1"</ETag>
    //         </Part>
    //         <Part>
    //             <PartNumber>2</PartNumber>
    //             <ETag>"6049d6384a9e65694c833a3aca6584fd"</ETag>
    //         </Part>
    //         <Part>
    //             <PartNumber>3</PartNumber>
    //             <ETag>"331747eae8068f03b844e6f28cc0ed23"</ETag>
    //         </Part>
    //     </CompleteMultipartUpload>
    //
    //
    // Spec:
    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    //
    //     <CompleteMultipartUpload>
    //        <Part>
    //           <PartNumber>integer</PartNumber>
    //           <ETag>string</ETag>
    //        </Part>
    //        ...
    //     </CompleteMultipartUpload>
    //
    // Note that in the example given on the spec page, the etag strings are quoted:
    //
    //     <CompleteMultipartUpload>
    //        <Part>
    //           <PartNumber>1</PartNumber>
    //           <ETag>"a54357aff0632cce46d942af68356b38"</ETag>
    //        </Part>
    //        ...
    //     </CompleteMultipartUpload>
    //
    // No extra quotes need to be added, the etag values we get from remote
    // already quoted, we just need to pass them verbatim.

    const result = "";
    return result;
};

/**
 * Complete a multipart upload by reporting information about all the uploaded
 * parts to the provided {@link completionURL}.
 *
 * @param completionURL A presigned URL to which the final status of the
 * uploaded parts should be reported to.
 *
 * @param reqBody A XML string containing information about the parts which were
 * uploaded.
 *
 * [Note: Multipart uploads]
 *
 * Multipart uploads are a mechanism to upload large files onto an remote
 * storage bucket by breaking it into smaller chunks / "parts", uploading each
 * part separately, and then reporting the consolidated information of all the
 * uploaded parts to a URL that marks the upload as complete on remote.
 *
 * This allows greater resilience since uploads of individual parts can be
 * retried independently without failing the entire upload on transient network
 * issues. This also helps self hosters, since often cloud providers have limits
 * to the size of single requests that they'll allow through (e.g. the
 * Cloudflare free plan currently has a 100 MB request size limit).
 *
 * The flow is implemented in two ways:
 *
 * a. The normal way, where each requests is made to a remote S3 bucket directly
 *    using the presigned URL.
 *
 * b. Using workers, where the requests are proxied via a worker near to the
 *    user's network to speed the requests up.
 *
 * See the documentation of {@link shouldDisableCFUploadProxy} for more details
 * about the via-worker flow.
 *
 * In both cases, the overall flow is roughly like the following:
 *
 * 1. Obtain multiple presigned URLs from remote (museum). The specific API call
 *    will be different (because of the different authentication mechanisms)
 *    when we're running in the context of the photos app and when we're running
 *    in the context of the public albums app.
 *
 * 2. Break the file to be uploaded into parts, and upload each part using a PUT
 *    request to one of the presigned URLs we got in step 1. There are two
 *    variants of this - one where we directly upload to the remote (S3), and
 *    one where we go via a worker.
 *
 * 3. Once all the parts have been uploaded, send a consolidated report of all
 *    the uploaded parts (the step 2's) to remote via another presigned
 *    "completion URL" that we also got in step 1. Like step 2, there are 2
 *    variants of this - one where we directly tell the remote (S3), and one
 *    where we report via a worker.
 */
export const _completeMultipartUpload = async (
    completionURL: string,
    reqBody: string,
) =>
    retryEnsuringHTTPOk(() =>
        fetch(completionURL, {
            method: "POST",
            headers: { ...publicRequestHeaders(), "Content-Type": "text/xml" },
            body: reqBody,
        }),
    );

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
