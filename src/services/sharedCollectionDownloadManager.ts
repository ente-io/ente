import {
    getFileUrl,
    getSharedAlbumFileUrl,
    getSharedAlbumThumbnailUrl,
} from 'utils/common/apiUtil';
import CryptoWorker from 'utils/crypto';
import {
    generateStreamFromArrayBuffer,
    convertForPreview,
    needsConversionForPreview,
} from 'utils/file';
import HTTPService from './HTTPService';
import { EnteFile } from 'types/file';

import { logError } from 'utils/sentry';
import { FILE_TYPE } from 'constants/file';

class SharedCollectionDownloadManager {
    private fileObjectUrlPromise = new Map<string, Promise<string>>();
    private thumbnailObjectUrlPromise = new Map<number, Promise<string>>();

    public async getThumbnail(file: EnteFile, token: string) {
        try {
            if (!token) {
                return null;
            }
            if (!this.thumbnailObjectUrlPromise.get(file.id)) {
                const downloadPromise = async () => {
                    const thumbnailCache = await caches.open('thumbs');
                    const cacheResp: Response = await thumbnailCache.match(
                        file.id.toString()
                    );
                    if (cacheResp) {
                        return URL.createObjectURL(await cacheResp.blob());
                    }
                    const thumb = await this.downloadThumb(token, file);
                    const thumbBlob = new Blob([thumb]);
                    try {
                        await thumbnailCache.put(
                            file.id.toString(),
                            new Response(thumbBlob)
                        );
                    } catch (e) {
                        // TODO: handle storage full exception.
                    }
                    return URL.createObjectURL(thumbBlob);
                };
                this.thumbnailObjectUrlPromise.set(file.id, downloadPromise());
            }

            return await this.thumbnailObjectUrlPromise.get(file.id);
        } catch (e) {
            this.thumbnailObjectUrlPromise.delete(file.id);
            logError(e, 'get preview Failed');
            throw e;
        }
    }

    downloadThumb = async (token: string, file: EnteFile) => {
        const resp = await HTTPService.get(
            getSharedAlbumThumbnailUrl(file.id),
            null,
            { 'X-Auth-Access-Token': token },
            { responseType: 'arraybuffer' }
        );
        const worker = await new CryptoWorker();
        const decrypted: Uint8Array = await worker.decryptThumbnail(
            new Uint8Array(resp.data),
            await worker.fromB64(file.thumbnail.decryptionHeader),
            file.key
        );
        return decrypted;
    };

    getFile = async (file: EnteFile, token: string, forPreview = false) => {
        const shouldBeConverted = forPreview && needsConversionForPreview(file);
        const fileKey = shouldBeConverted
            ? `${file.id}_converted`
            : `${file.id}`;
        try {
            const getFilePromise = async (convert: boolean) => {
                const fileStream = await this.downloadFile(token, file);
                let fileBlob = await new Response(fileStream).blob();
                if (convert) {
                    fileBlob = await convertForPreview(file, fileBlob);
                }
                return URL.createObjectURL(fileBlob);
            };
            if (!this.fileObjectUrlPromise.get(fileKey)) {
                this.fileObjectUrlPromise.set(
                    fileKey,
                    getFilePromise(shouldBeConverted)
                );
            }
            const fileURL = await this.fileObjectUrlPromise.get(fileKey);
            return fileURL;
        } catch (e) {
            this.fileObjectUrlPromise.delete(fileKey);
            logError(e, 'Failed to get File');
            throw e;
        }
    };

    public async getCachedOriginalFile(file: EnteFile) {
        return await this.fileObjectUrlPromise.get(file.id.toString());
    }

    async downloadFile(token: string, file: EnteFile) {
        const worker = await new CryptoWorker();
        if (!token) {
            return null;
        }
        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getSharedAlbumFileUrl(file.id),
                null,
                { 'X-Auth-Access-Token': token },
                { responseType: 'arraybuffer' }
            );
            const decrypted: any = await worker.decryptFile(
                new Uint8Array(resp.data),
                await worker.fromB64(file.file.decryptionHeader),
                file.key
            );
            return generateStreamFromArrayBuffer(decrypted);
        }
        const resp = await fetch(getFileUrl(file.id), {
            headers: {
                'X-Auth-Token': token,
            },
        });
        const reader = resp.body.getReader();
        const stream = new ReadableStream({
            async start(controller) {
                const decryptionHeader = await worker.fromB64(
                    file.file.decryptionHeader
                );
                const fileKey = await worker.fromB64(file.key);
                const { pullState, decryptionChunkSize } =
                    await worker.initDecryption(decryptionHeader, fileKey);
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
                                    await worker.decryptChunk(
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
                                    await worker.decryptChunk(data, pullState);
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

export default new SharedCollectionDownloadManager();
