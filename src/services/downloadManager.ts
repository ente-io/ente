import { getToken } from 'utils/common/key';
import { getFileUrl, getThumbnailUrl } from 'utils/common/apiUtil';
import CryptoWorker from 'utils/crypto';
import {
    fileIsHEIC,
    convertHEIC2JPEG,
    fileNameWithoutExtension,
    generateStreamFromArrayBuffer,
} from 'utils/file';
import HTTPService from './HTTPService';
import { File } from './fileService';
import { logError } from 'utils/sentry';
import { FILE_TYPE } from 'pages/gallery';
import { decodeMotionPhoto } from './motionPhotoService';

class DownloadManager {
    private fileDownloads = new Map<string, string>();

    private thumbnailDownloads = new Map<number, string>();

    public async getPreview(file: File) {
        try {
            const token = getToken();
            if (!token) {
                return null;
            }
            const cache = await caches.open('thumbs');
            const cacheResp: Response = await cache.match(file.id.toString());
            if (cacheResp) {
                return URL.createObjectURL(await cacheResp.blob());
            }
            if (!this.thumbnailDownloads.get(file.id)) {
                const download = await this.downloadThumb(token, cache, file);
                this.thumbnailDownloads.set(file.id, download);
            }
            return await this.thumbnailDownloads.get(file.id);
        } catch (e) {
            logError(e, 'get preview Failed');
        }
    }
    downloadThumb = async (token: string, cache: Cache, file: File) => {
        const resp = await HTTPService.get(
            getThumbnailUrl(file.id),
            null,
            { 'X-Auth-Token': token },
            { responseType: 'arraybuffer' },
        );
        const worker = await new CryptoWorker();
        const decrypted: any = await worker.decryptThumbnail(
            new Uint8Array(resp.data),
            await worker.fromB64(file.thumbnail.decryptionHeader),
            file.key,
        );
        try {
            await cache.put(
                file.id.toString(),
                new Response(new Blob([decrypted])),
            );
        } catch (e) {
            // TODO: handle storage full exception.
        }
        return URL.createObjectURL(new Blob([decrypted]));
    };

    getFile = async (file: File, forPreview = false) => {
        try {
            if (!this.fileDownloads.get(`${file.id}_${forPreview}`)) {
                // unzip motion photo and return fileBlob of the image for preview
                const fileStream = await this.downloadFile(file);
                let fileBlob = await new Response(fileStream).blob();
                if (forPreview) {
                    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                        const originalName = fileNameWithoutExtension(
                            file.metadata.title,
                        );
                        const motionPhoto = await decodeMotionPhoto(
                            fileBlob,
                            originalName,
                        );
                        fileBlob = new Blob([motionPhoto.image]);
                    }
                    if (fileIsHEIC(file.metadata.title)) {
                        fileBlob = await convertHEIC2JPEG(fileBlob);
                    }
                }
                this.fileDownloads.set(
                    `${file.id}_${forPreview}`,
                    URL.createObjectURL(fileBlob),
                );
            }
            return this.fileDownloads.get(`${file.id}_${forPreview}`);
        } catch (e) {
            logError(e, 'Failed to get File');
        }
    };

    async downloadFile(file: File) {
        const worker = await new CryptoWorker();
        const token = getToken();
        if (!token) {
            return null;
        }
        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getFileUrl(file.id),
                null,
                { 'X-Auth-Token': token },
                { responseType: 'arraybuffer' },
            );
            const decrypted: any = await worker.decryptFile(
                new Uint8Array(resp.data),
                await worker.fromB64(file.file.decryptionHeader),
                file.key,
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
                    file.file.decryptionHeader,
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
                                data.byteLength + value.byteLength,
                            );
                            buffer.set(new Uint8Array(data), 0);
                            buffer.set(new Uint8Array(value), data.byteLength);
                            if (buffer.length > decryptionChunkSize) {
                                const fileData = buffer.slice(
                                    0,
                                    decryptionChunkSize,
                                );
                                const { decryptedData } =
                                    await worker.decryptChunk(
                                        fileData,
                                        pullState,
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

export default new DownloadManager();
