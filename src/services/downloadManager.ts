import { getToken } from 'utils/common/key';
import { file } from './fileService';
import HTTPService from './HTTPService';
import { getEndpoint } from 'utils/common/apiUtil';
import * as Comlink from 'comlink';

const ENDPOINT = getEndpoint();
const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));

class DownloadManager {
    constructor(private token) {}
    public async getPreview(file: file) {
        try {
            const cache = await caches.open('thumbs');
            const cacheResp: Response = await cache.match(file.id.toString());
            if (cacheResp) {
                return URL.createObjectURL(await cacheResp.blob());
            }
            const resp = await HTTPService.get(
                `${ENDPOINT}/files/preview/${file.id}`,
                null,
                { 'X-Auth-Token': this.token },
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
        } catch (e) {
            console.log('get preview Failed' + e);
        }
    }

    getFile = async (file: file) => {
        try {
            const resp = await HTTPService.get(
                `${ENDPOINT}/files/download/${file.id}`,
                null,
                { 'X-Auth-Token': this.token },
                { responseType: 'arraybuffer' }
            );
            const worker = await new CryptoWorker();
            const decrypted: any = await worker.decryptFile(
                new Uint8Array(resp.data),
                await worker.fromB64(file.file.decryptionHeader),
                file.key
            );
            return URL.createObjectURL(new Blob([decrypted]));
        } catch (e) {
            console.log('get file failed ' + e);
        }
    };
}

export default new DownloadManager(getToken());
