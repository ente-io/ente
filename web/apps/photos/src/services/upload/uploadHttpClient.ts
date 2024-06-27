import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { apiURL, uploaderOrigin } from "@/next/origins";
import { wait } from "@/utils/promise";
import { CustomError, handleUploadError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { MultipartUploadURLs, UploadFile, UploadURL } from "./uploadService";

const MAX_URL_REQUESTS = 50;

class UploadHttpClient {
    private uploadURLFetchInProgress = null;

    async uploadFile(uploadFile: UploadFile): Promise<EnteFile> {
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const url = await apiURL("/files");
            const response = await retryHTTPCall(
                () =>
                    HTTPService.post(url, uploadFile, null, {
                        "X-Auth-Token": token,
                    }),
                handleUploadError,
            );
            return response.data;
        } catch (e) {
            log.error("upload Files Failed", e);
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
                        await apiURL("/files/upload-urls"),
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
            log.error("fetch upload-url failed ", e);
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
                await apiURL("/files/multipart-upload-urls"),
                {
                    count,
                },
                { "X-Auth-Token": token },
            );

            return response.data["urls"];
        } catch (e) {
            log.error("fetch multipart-upload-url failed", e);
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
                log.error("putFile to dataStore failed ", e);
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
            const origin = await uploaderOrigin();
            await retryHTTPCall(() =>
                HTTPService.put(
                    `${origin}/file-upload`,
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
                log.error("putFile to dataStore failed ", e);
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
                    log.error("putFile in parts failed", err);
                    throw err;
                }
                return resp;
            }, handleUploadError);
            return response.headers.etag as string;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                log.error("put filePart failed", e);
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
            const origin = await uploaderOrigin();
            const response = await retryHTTPCall(async () => {
                const resp = await HTTPService.put(
                    `${origin}/multipart-upload`,
                    filePart,
                    null,
                    {
                        "UPLOAD-URL": partUploadURL,
                    },
                    progressTracker,
                );
                if (!resp?.data?.etag) {
                    const err = Error(CustomError.ETAG_MISSING);
                    log.error("putFile in parts failed", err);
                    throw err;
                }
                return resp;
            });
            return response.data.etag as string;
        } catch (e) {
            if (e.message !== CustomError.UPLOAD_CANCELLED) {
                log.error("put filePart failed", e);
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
            log.error("put file in parts failed", e);
            throw e;
        }
    }

    async completeMultipartUploadV2(completeURL: string, reqBody: any) {
        try {
            const origin = await uploaderOrigin();
            await retryHTTPCall(() =>
                HTTPService.post(
                    `${origin}/multipart-complete`,
                    reqBody,
                    null,
                    {
                        "content-type": "text/xml",
                        "UPLOAD-URL": completeURL,
                    },
                ),
            );
        } catch (e) {
            log.error("put file in parts failed", e);
            throw e;
        }
    }
}

export default new UploadHttpClient();

const retrySleepTimeInMilliSeconds = [2000, 5000, 10000];

export async function retryHTTPCall(
    func: () => Promise<any>,
    checkForBreakingError?: (error) => void,
): Promise<any> {
    const retrier = async (
        func: () => Promise<any>,
        attemptNumber: number = 0,
    ) => {
        try {
            const resp = await func();
            return resp;
        } catch (e) {
            if (checkForBreakingError) {
                checkForBreakingError(e);
            }
            if (attemptNumber < retrySleepTimeInMilliSeconds.length) {
                await wait(retrySleepTimeInMilliSeconds[attemptNumber]);
                return await retrier(func, attemptNumber + 1);
            } else {
                throw e;
            }
        }
    };
    return await retrier(func);
}
