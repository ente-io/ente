import HTTPService from 'services/HTTPService';
import { retryAsyncFunction } from 'utils/common';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import { CHUNKS_COMBINED_FOR_UPLOAD, MultipartUploadURLs, RANDOM_PERCENTAGE_PROGRESS_FOR_PUT, UploadFile } from './uploadService';
import * as convert from 'xml-js';
import { File } from '../fileService';

const ENDPOINT = getEndpoint();
const MAX_URL_REQUESTS = 50;


export interface UploadURL {
    url: string;
    objectKey: string;
}
class NetworkClient {
    private uploadURLFetchInProgress=null;

    async uploadFile(uploadFile: UploadFile):Promise<File> {
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const response = await retryAsyncFunction(()=>HTTPService.post(
                `${ENDPOINT}/files`,
                uploadFile,
                null,
                {
                    'X-Auth-Token': token,
                },
            ));
            return response.data;
        } catch (e) {
            logError(e, 'upload Files Failed');
            throw e;
        }
    }

    async fetchUploadURLs(count:number, urlStore:UploadURL[]): Promise<void> {
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
                            count: Math.min(
                                MAX_URL_REQUESTS,
                                count * 2,
                            ),
                        },
                        { 'X-Auth-Token': token },
                    );
                    const response = await this.uploadURLFetchInProgress;
                    urlStore.push(...response.data['urls']);
                } finally {
                    this.uploadURLFetchInProgress = null;
                }
            }
            return this.uploadURLFetchInProgress;
        } catch (e) {
            logError(e, 'fetch upload-url failed ');
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
                { 'X-Auth-Token': token },
            );

            return response.data['urls'];
        } catch (e) {
            logError(e, 'fetch multipart-upload-url failed');
            throw e;
        }
    }

    async putFile(
        fileUploadURL: UploadURL,
        file: Uint8Array,
        progressTracker:()=>any,
    ): Promise<string> {
        try {
            console.log(fileUploadURL, file);
            await retryAsyncFunction(()=>
                HTTPService.put(
                    fileUploadURL.url,
                    file,
                    null,
                    null,
                    progressTracker(),
                ),
            );
            return fileUploadURL.objectKey;
        } catch (e) {
            logError(e, 'putFile to dataStore failed ');
            throw e;
        }
    }

    async putFileInParts(
        multipartUploadURLs: MultipartUploadURLs,
        file: ReadableStream<Uint8Array>,
        filename: string,
        uploadPartCount: number,
        trackUploadProgress,
    ) {
        try {
            const streamEncryptedFileReader = file.getReader();
            const percentPerPart = Math.round(
                RANDOM_PERCENTAGE_PROGRESS_FOR_PUT() / uploadPartCount,
            );
            const resParts = [];
            for (const [
                index,
                fileUploadURL,
            ] of multipartUploadURLs.partURLs.entries()) {
                const combinedChunks = [];
                for (let i = 0; i < CHUNKS_COMBINED_FOR_UPLOAD; i++) {
                    const { done, value: chunk } =
                    await streamEncryptedFileReader.read();
                    if (done) {
                        break;
                    }
                    for (let index = 0; index < chunk.length; index++) {
                        combinedChunks.push(chunk[index]);
                    }
                }
                const uploadChunk = Uint8Array.from(combinedChunks);
                const response=await retryAsyncFunction(async ()=>{
                    const resp =await HTTPService.put(
                        fileUploadURL,
                        uploadChunk,
                        null,
                        null,
                        trackUploadProgress(filename, percentPerPart, index),
                    );
                    if (!resp?.headers?.etag) {
                        const err=Error('no header/etag present in response body');
                        logError(err);
                        throw err;
                    }
                    return resp;
                });
                resParts.push({
                    PartNumber: index + 1,
                    ETag: response.headers.etag,
                });
            }
            const options = { compact: true, ignoreComment: true, spaces: 4 };
            const body = convert.js2xml(
                { CompleteMultipartUpload: { Part: resParts } },
                options,
            );
            await retryAsyncFunction(()=>
                HTTPService.post(multipartUploadURLs.completeURL, body, null, {
                    'content-type': 'text/xml',
                }),
            );
            return multipartUploadURLs.objectKey;
        } catch (e) {
            logError(e, 'put file in parts failed');
            throw e;
        }
    }
}
export default new NetworkClient();


