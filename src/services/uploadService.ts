import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import localForage from 'localforage';
import { fileAttribute, collectionLatestFile, collection, file } from './fileService';
const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();

localForage.config({
    driver: localForage.INDEXEDDB,
    name: 'ente-files',
    version: 1.0,
    storeName: 'files',
});

interface encryptionResult {
    file: fileAttribute,
    key: Uint8Array
}


interface UploadURL {
    url: string,
    objectKey: string
}

interface Uploadfiles {
    file: Uint8Array,
    metaData: string,
    thumbnail: Uint8Array
}

class Queue<T> {
    _store: T[] = [];
    push(val: T) {
        this._store.push(val);
    }
    pop(): T {
        return this._store.shift();
    }
    isEmpty(): boolean {
        return this._store.length == 0;
    }
}

class UploadService {

    private uploadUrls = new Queue<UploadURL>();
    private UploadQueue = new Queue<number>();

    public async uploadFiles(recivedFiles: any[], collectionLatestFile: collectionLatestFile) {
        try {
            const files: Uploadfiles[] = await this.formatData(recivedFiles);
            const Encryptedfiles: files[] = await this.encryptFiles(files, collectionLatestFile.collection.key);
        }
        catch (e) {
            console.log(e);
        }

    }

    public async formatData(filesToUpload: any[]) {
        const formatedDataPromises: Promise<Uploadfiles>[] = filesToUpload.map(async (uploadedFile): Promise<Uploadfiles> => {
            console.log(uploadedFile);
            const fileData: Uint8Array = await new Promise((resolve, reject) => {
                const reader = new FileReader()

                reader.onabort = () => reject('file reading was aborted')
                reader.onerror = () => reject('file reading has failed')
                reader.onload = () => {
                    // Do whatever you want with the file contents
                    const result = typeof reader.result === "string" ? new TextEncoder().encode(reader.result) : new Uint8Array(reader.result);
                    resolve(result);
                }
                reader.readAsArrayBuffer(uploadedFile)
            });
            return {
                file: fileData,
                metaData: null,
                thumbnail: null
            }
        })
        return await Promise.all(formatedDataPromises);
    }
    private async encryptFiles(files: Uploadfiles[], encryptionKey: string): Promise<file[]> {
        let encryptedfilesPromises: Promise<file>[] = files.map(async (file): Promise<file> => {
            const worker = await new CryptoWorker();
            const encryptResult = await worker.encryptFile(
                files,
                null
            );

            const { key: fileKey, file: fileAttributes }: encryptionResult = encryptResult;

            // console.log(file, key);

            // const reDecrypted: any = await worker.decryptFile(
            //   fileAttributes.encryptedData,
            //   await worker.fromB64(fileAttributes.decryptionHeader),
            //   key
            // );
            // console.log(URL.createObjectURL(new Blob([reDecrypted])));

            let thumbnailData = await this.generateThumbnail(file);

            const encryptedThumbnailData = await worker.encryptThumbnail(thumbnailData, fileKey);

            const encryptedMetaData=await worker.

            const keyEncryptionResult = await worker.encrypt(fileKey, encryptionKey);

            const fileUploadURL = await this.getUploadURL();
            // string fileObjectKey = await putFile(fileUploadURL, encryptedFile);

            // final thumbnailUploadURL = await _getUploadURL();
            // String thumbnailObjectKey =
            //     await _putFile(thumbnailUploadURL, encryptedThumbnailFile);
            const fileToBeUploaded = {
                collectionID: Number(collection.id),
                file: fileAttributes,
                encryptedKey: keyEncryptionResult.encryptedData,
                keyDecryptionNonce: keyEncryptionResult.nonce,
                key,
                id: 0,
            }
            return fileToBeUploaded;
        }
    }

    private async generateThumbnail(fileData) {
        return fileData;
    }

    private async getUploadURL() {
        if (this.uploadUrls.isEmpty()) {
            await this.fetchUploadURLs();
        }
        return this.uploadUrls.pop();
    }

    private async fetchUploadURLs() {

    }
}

export default new UploadService();

