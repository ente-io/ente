import { CustomError, handleUploadError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint, getUploadEndpoint } from "@ente/shared/network/api";
import { logError } from "@ente/shared/sentry";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { EnteFile } from "types/file";
import { MultipartUploadURLs, UploadFile, UploadURL } from "types/upload";
import { retryHTTPCall } from "utils/upload/uploadRetrier";

const ENDPOINT = getEndpoint();
const UPLOAD_ENDPOINT = getUploadEndpoint();

const MAX_URL_REQUESTS = 50;

class UploadHttpClient {
    private uploadURLFetchInProgress = null;

    async uploadFile(uploadFile: UploadFile): Promise<EnteFile> {
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const response = await retryHTTPCall(
                () =>
                    HTTPService.post(`${ENDPOINT}/files`, uploadFile, null, {
                        "X-Auth-Token": token,
                    }),
                handleUploadError,
            );
            return response.data;
        } catch (e) {
            logError(e, "upload Files Failed");
            throw e;
        }
    }

    async fetchUploadURLs(count: number, urlStore: UploadURL[]): Promise<void> {
        try {
            if (!this.uploadURLFetchInProgress) {
                try {
                    const token = getToken();
                    if (!token) {
                        return;
                    }
                    this.uploadURLFetchInProgress = HTTPService.get(
                        `${ENDPOINT}/files/upload-urls`,
                        {
                            count: Math.min(MAX_URL_REQUESTS, count * 2),
                        },
                        { "X-Auth-Token": token },
                    );
                    const response = await this.uploadURLFetchInProgress;
                    for (const url of response.data["urls"]) {
                        urlStore.push(url);
                    }
                } finally {
                    this.uploadURLFetchInProgress = null;
                }
            }
            return this.uploadURLFetchInProgress;
        } catch (e) {
            logError(e, "fetch upload-url failed ");
            throw e;
        }
    }

    async fetchMultipartUploadURLs(
        count: number,
    ): Promise<MultipartUploadURLs> {
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const response = await HTTPService.get(
                `${ENDPOINT}/files/multipart-upload-urls`,
                {
                    count,
                },
                { "X-Auth-Token": token },
            );

            return response.data["urls"];
        } catch (e) {
            logError(e, "fetch multipart-upload-url failed");
            throw e;
        }
    }

    async putFile(
        fileUploadURL: UploadURL,
        file: Uint8Array,
        progressTracker,
    ): Promise<string> {
        try {
            await retryHTTPCall(
                () =>
                    HTTPService.put(
                        fileUploadURL.url,
                        file,
                        null,
                        null,
                        progressTracker,
                    ),
                handleUploadError,
            );
            return fileUploadURL.objectKey;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, "putFile to dataStore failed ");
            }
            throw e;
        }
    }

    async putFileV2(
        fileUploadURL: UploadURL,
        file: Uint8Array,
        progressTracker,
    ): Promise<string> {
        try {
            await retryHTTPCall(() =>
                HTTPService.put(
                    `${UPLOAD_ENDPOINT}/file-upload`,
                    file,
                    null,
                    {
                        "UPLOAD-URL": fileUploadURL.url,
                    },
                    progressTracker,
                ),
            );
            return fileUploadURL.objectKey;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, "putFile to dataStore failed ");
            }
            throw e;
        }
    }

    async putFilePart(
        partUploadURL: string,
        filePart: Uint8Array,
        progressTracker,
    ) {
        try {
            const response = await retryHTTPCall(async () => {
                const resp = await HTTPService.put(
                    partUploadURL,
                    filePart,
                    null,
                    null,
                    progressTracker,
                );
                if (!resp?.headers?.etag) {
                    const err = Error(CustomError.ETAG_MISSING);
                    logError(err, "putFile in parts failed");
                    throw err;
                }
                return resp;
            }, handleUploadError);
            return response.headers.etag as string;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, "put filePart failed");
            }
            throw e;
        }
    }

    async putFilePartV2(
        partUploadURL: string,
        filePart: Uint8Array,
        progressTracker,
    ) {
        try {
            const response = await retryHTTPCall(async () => {
                const resp = await HTTPService.put(
                    `${UPLOAD_ENDPOINT}/multipart-upload`,
                    filePart,
                    null,
                    {
                        "UPLOAD-URL": partUploadURL,
                    },
                    progressTracker,
                );
                if (!resp?.data?.etag) {
                    const err = Error(CustomError.ETAG_MISSING);
                    logError(err, "putFile in parts failed");
                    throw err;
                }
                return resp;
            });
            return response.data.etag as string;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                logError(e, "put filePart failed");
            }
            throw e;
        }
    }

    async completeMultipartUpload(completeURL: string, reqBody: any) {
        try {
            await retryHTTPCall(() =>
                HTTPService.post(completeURL, reqBody, null, {
                    "content-type": "text/xml",
                }),
            );
        } catch (e) {
            logError(e, "put file in parts failed");
            throw e;
        }
    }

    async completeMultipartUploadV2(completeURL: string, reqBody: any) {
        try {
            await retryHTTPCall(() =>
                HTTPService.post(
                    `${UPLOAD_ENDPOINT}/multipart-complete`,
                    reqBody,
                    null,
                    {
                        "content-type": "text/xml",
                        "UPLOAD-URL": completeURL,
                    },
                ),
            );
        } catch (e) {
            logError(e, "put file in parts failed");
            throw e;
        }
    }
}

export default new UploadHttpClient();
