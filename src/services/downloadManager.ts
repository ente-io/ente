import { getToken } from 'utils/common/key';
import { file } from './fileService';
import HTTPService from './HTTPService';
import { getEndpoint, getFileUrl, getThumbnailUrl } from 'utils/common/apiUtil';
import { getFileExtension, runningInBrowser } from 'utils/common/utilFunctions';
import CryptoWorker from 'utils/crypto/cryptoWorker';

const heic2any = runningInBrowser() && require('heic2any');
const TYPE_HEIC = 'heic';

class DownloadManager {
    private fileDownloads = new Map<number, Promise<string>>();
    private thumbnailDownloads = new Map<number, Promise<string>>();

    public async getPreview(file: file) {
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
                const download = (async () => {
                    const resp = await HTTPService.get(
                        getThumbnailUrl(file.id),
                        null,
                        { 'X-Auth-Token': token },
                        { responseType: 'arraybuffer' }
                    );
                    const worker = await new CryptoWorker();
                    const decrypted: any = await worker.decryptThumbnail(
                        new Uint8Array(resp.data),
                        await worker.fromB64(file.thumbnail.decryptionHeader),
                        file.key
                    );
                    try {
                        await cache.put(
                            file.id.toString(),
                            new Response(new Blob([decrypted]))
                        );
                    } catch (e) {
                        // TODO: handle storage full exception.
                    }

                    return URL.createObjectURL(new Blob([decrypted]));
                })();
                this.thumbnailDownloads.set(file.id, download);
            }
            return await this.thumbnailDownloads.get(file.id);
        } catch (e) {
            console.error('get preview Failed', e);
        }
    }

    getFile = async (file: file) => {
        try {
            if (!this.fileDownloads.get(file.id)) {
                const download = (async () => {
                    return await this.downloadFile(file);
                })();
                this.fileDownloads.set(file.id, download);
            }
            return await this.fileDownloads.get(file.id);
        } catch (e) {
            console.error('Failed to get File', e);
        }
    };

    private async downloadFile(file: file) {
        const worker = await new CryptoWorker();
        const token = getToken();
        if (!token) {
            return null;
        }
        if (file.metadata.fileType === 0) {
            const resp = await HTTPService.get(
                getFileUrl(file.id),
                null,
                { 'X-Auth-Token': token },
                { responseType: 'arraybuffer' }
            );
            const decrypted: any = await worker.decryptFile(
                new Uint8Array(resp.data),
                await worker.fromB64(file.file.decryptionHeader),
                file.key
            );
            let decryptedBlob = new Blob([decrypted]);

            if (getFileExtension(file.metadata.title) === TYPE_HEIC) {
                decryptedBlob = await this.convertHEIC2JPEG(decryptedBlob);
            }
            return URL.createObjectURL(new Blob([decryptedBlob]));
        } else {
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
                    let {
                        pullState,
                        decryptionChunkSize,
                        tag,
                    } = await worker.initDecryption(decryptionHeader, fileKey);
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
                                buffer.set(
                                    new Uint8Array(value),
                                    data.byteLength
                                );
                                if (buffer.length > decryptionChunkSize) {
                                    const fileData = buffer.slice(
                                        0,
                                        decryptionChunkSize
                                    );
                                    const {
                                        decryptedData,
                                        newTag,
                                    } = await worker.decryptChunk(
                                        fileData,
                                        pullState
                                    );
                                    controller.enqueue(decryptedData);
                                    tag = newTag;
                                    data = buffer.slice(decryptionChunkSize);
                                } else {
                                    data = buffer;
                                }
                                push();
                            } else {
                                if (data) {
                                    const {
                                        decryptedData,
                                    } = await worker.decryptChunk(
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
            return URL.createObjectURL(await new Response(stream).blob());
        }
    }

    private async convertHEIC2JPEG(fileBlob): Promise<Blob> {
        return await heic2any({
            blob: fileBlob,
            toType: 'image/jpeg',
            quality: 1,
        });
    }
}

export default new DownloadManager();
