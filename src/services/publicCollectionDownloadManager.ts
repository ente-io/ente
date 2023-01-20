import {
    getPublicCollectionFileURL,
    getPublicCollectionThumbnailURL,
} from 'utils/common/apiUtil';
import {
    generateStreamFromArrayBuffer,
    getRenderableFileURL,
    createTypedObjectURL,
} from 'utils/file';
import HTTPService from './HTTPService';
import { EnteFile } from 'types/file';

import { logError } from 'utils/sentry';
import { FILE_TYPE } from 'constants/file';
import { CustomError } from 'utils/error';
import QueueProcessor from './queueProcessor';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { addLogLine } from 'utils/logging';

class PublicCollectionDownloadManager {
    private fileObjectURLPromise = new Map<
        string,
        Promise<{ original: string[]; converted: string[] }>
    >();
    private thumbnailObjectURLPromise = new Map<number, Promise<string>>();

    private thumbnailDownloadRequestsProcessor = new QueueProcessor<any>(5);

    public async getThumbnail(
        file: EnteFile,
        token: string,
        passwordToken: string
    ) {
        addLogLine(`[${file.id}] [PublicDownloadManger] getThumbnail called`);
        try {
            if (!token) {
                return null;
            }
            if (this.thumbnailObjectURLPromise.has(file.id)) {
                addLogLine(
                    `[${file.id}] [PublicDownloadManger] getThumbnail promise cache hit, returning existing promise`
                );
            }
            if (!this.thumbnailObjectURLPromise.has(file.id)) {
                const downloadPromise = async () => {
                    const thumbnailCache = await (async () => {
                        try {
                            return await caches.open('thumbs');
                        } catch (e) {
                            return null;
                            // ignore
                        }
                    })();

                    const cacheResp: Response = await thumbnailCache?.match(
                        file.id.toString()
                    );

                    if (cacheResp) {
                        addLogLine(
                            `[${file.id}] [PublicDownloadManger] in memory cache hit, using localCache files`
                        );
                        return URL.createObjectURL(await cacheResp.blob());
                    }
                    addLogLine(
                        `[${file.id}] [PublicDownloadManger] in memory cache miss, getThumbnail download started`
                    );
                    const thumb =
                        await this.thumbnailDownloadRequestsProcessor.queueUpRequest(
                            () => this.downloadThumb(token, passwordToken, file)
                        ).promise;
                    const thumbBlob = new Blob([thumb]);
                    try {
                        await thumbnailCache?.put(
                            file.id.toString(),
                            new Response(thumbBlob)
                        );
                    } catch (e) {
                        // TODO: handle storage full exception.
                    }
                    return URL.createObjectURL(thumbBlob);
                };
                this.thumbnailObjectURLPromise.set(file.id, downloadPromise());
            }

            return await this.thumbnailObjectURLPromise.get(file.id);
        } catch (e) {
            this.thumbnailObjectURLPromise.delete(file.id);
            logError(e, 'get publicDownloadManger preview Failed');
            throw e;
        }
    }

    private downloadThumb = async (
        token: string,
        passwordToken: string,
        file: EnteFile
    ) => {
        const resp = await HTTPService.get(
            getPublicCollectionThumbnailURL(file.id),
            null,
            {
                'X-Auth-Access-Token': token,
                ...(passwordToken && {
                    'X-Auth-Access-Token-JWT': passwordToken,
                }),
            },
            { responseType: 'arraybuffer' }
        );
        if (typeof resp.data === 'undefined') {
            throw Error(CustomError.REQUEST_FAILED);
        }
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const decrypted = await cryptoWorker.decryptThumbnail(
            new Uint8Array(resp.data),
            await cryptoWorker.fromB64(file.thumbnail.decryptionHeader),
            file.key
        );
        return decrypted;
    };

    getFile = async (
        file: EnteFile,
        token: string,
        passwordToken: string,
        forPreview = false
    ) => {
        const fileKey = forPreview ? `${file.id}_preview` : `${file.id}`;
        try {
            const getFilePromise = async () => {
                addLogLine(
                    `[${file.id}] [PublicDownloadManager] downloading file`
                );
                const fileStream = await this.downloadFile(
                    token,
                    passwordToken,
                    file
                );
                const fileBlob = await new Response(fileStream).blob();
                if (forPreview) {
                    return await getRenderableFileURL(file, fileBlob);
                } else {
                    const fileURL = await createTypedObjectURL(
                        fileBlob,
                        file.metadata.title
                    );
                    return { converted: [fileURL], original: [fileURL] };
                }
            };
            if (this.fileObjectURLPromise.has(fileKey)) {
                addLogLine(
                    `[${file.id}] [PublicDownloadManager] getFile promise cache hit, returning existing promise`
                );
            }
            if (!this.fileObjectURLPromise.get(fileKey)) {
                this.fileObjectURLPromise.set(fileKey, getFilePromise());
            }
            const fileURLs = await this.fileObjectURLPromise.get(fileKey);
            return fileURLs;
        } catch (e) {
            this.fileObjectURLPromise.delete(fileKey);
            logError(e, 'public download manager Failed to get File');
            throw e;
        }
    };

    public async getCachedOriginalFile(file: EnteFile) {
        return await this.fileObjectURLPromise.get(file.id.toString());
    }

    async downloadFile(token: string, passwordToken: string, file: EnteFile) {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        if (!token) {
            return null;
        }
        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getPublicCollectionFileURL(file.id),
                null,
                {
                    'X-Auth-Access-Token': token,
                    ...(passwordToken && {
                        'X-Auth-Access-Token-JWT': passwordToken,
                    }),
                },
                { responseType: 'arraybuffer' }
            );
            if (typeof resp.data === 'undefined') {
                throw Error(CustomError.REQUEST_FAILED);
            }
            const decrypted = await cryptoWorker.decryptFile(
                new Uint8Array(resp.data),
                await cryptoWorker.fromB64(file.file.decryptionHeader),
                file.key
            );
            return generateStreamFromArrayBuffer(decrypted);
        }
        const resp = await fetch(getPublicCollectionFileURL(file.id), {
            headers: {
                'X-Auth-Access-Token': token,
                ...(passwordToken && {
                    'X-Auth-Access-Token-JWT': passwordToken,
                }),
            },
        });
        const reader = resp.body.getReader();
        const stream = new ReadableStream({
            async start(controller) {
                const decryptionHeader = await cryptoWorker.fromB64(
                    file.file.decryptionHeader
                );
                const fileKey = await cryptoWorker.fromB64(file.key);
                const { pullState, decryptionChunkSize } =
                    await cryptoWorker.initDecryption(
                        decryptionHeader,
                        fileKey
                    );
                let data = new Uint8Array();
                // The following function handles each data chunk
                function push() {
                    // "done" is a Boolean and value a "Uint8Array"
                    reader.read().then(async ({ done, value }) => {
                        // Is there more data to read?
                        if (!done) {
                            const buffer = new Uint8Array(
                                data.byteLength + value.byteLength
                            );
                            buffer.set(new Uint8Array(data), 0);
                            buffer.set(new Uint8Array(value), data.byteLength);
                            if (buffer.length > decryptionChunkSize) {
                                const fileData = buffer.slice(
                                    0,
                                    decryptionChunkSize
                                );
                                const { decryptedData } =
                                    await cryptoWorker.decryptChunk(
                                        fileData,
                                        pullState
                                    );
                                controller.enqueue(decryptedData);
                                data = buffer.slice(decryptionChunkSize);
                            } else {
                                data = buffer;
                            }
                            push();
                        } else {
                            if (data) {
                                const { decryptedData } =
                                    await cryptoWorker.decryptChunk(
                                        data,
                                        pullState
                                    );
                                controller.enqueue(decryptedData);
                                data = null;
                            }
                            controller.close();
                        }
                    });
                }

                push();
            },
        });
        return stream;
    }
}

export default new PublicCollectionDownloadManager();
