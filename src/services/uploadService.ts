import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
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
interface keyEncryptionResult {
    encryptedData: string,
    key: Uint8Array,
    nonce: string,
}

interface uploadURL {
    url: string,
    objectKey: string
}

interface formatedFile {
    filedata: Uint8Array,
    metadata: Object,
    thumbnail: Uint8Array
}

interface encryptedFile {
    filedata: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
    encryptedKey: string;
    keyDecryptionNonce: string;
    key: Uint8Array;
}

interface objectKey {
    objectKey: string,
    decryptionHeader: string
}
interface objectKeys {
    file: objectKey
    thumbnail: objectKey
}

interface uploadFile extends objectKeys {
    collectionID: string,
    encryptedKey: string;
    keyDecryptionNonce: string;
    metadata: {
        encryptedData: string | Uint8Array,
        decryptionHeader: string
    }
}

class Queue<T> {
    _store: T[] = [];
    push(vals: T[]): void {
        vals.forEach((val) => this._store.push(val));
    }
    pop(): T {
        return this._store.shift();
    }
    isEmpty(): boolean {
        return this._store.length == 0;
    }
}

class UploadService {

    private uploadURLs = new Queue<uploadURL>();
    private uploadURLFetchInProgress: Promise<any> = null
    private increment
    private currentPercent
    public async uploadFiles(recievedFiles: File[], collectionLatestFile: collectionLatestFile, token, setPercentComplete) {
        try {
            this.currentPercent = 0;
            this.increment = 100 / (3 * recievedFiles.length);
            const worker = await new CryptoWorker();
            await Promise.all(recievedFiles.map(async (recievedFile: File) => {
                const file = await this.formatData(recievedFile);
                console.log(file);

                const encryptedfile: encryptedFile = await this.encryptFiles(worker, file, collectionLatestFile.collection.key);
                this.increasePercent(setPercentComplete)

                const objectKeys = await this.uploadtoBucket(encryptedfile, token);
                this.increasePercent(setPercentComplete)

                const uploadedfile = await this.uploadFile(collectionLatestFile, encryptedfile, objectKeys, token);
                this.increasePercent(setPercentComplete)

                console.log(uploadedfile);
            }));
            setPercentComplete(100);
        }
        catch (e) {
            console.log(e);
        }
    }

    private increasePercent(setPercentComplete) {
        this.currentPercent += this.increment;
        setPercentComplete(this.currentPercent);
    }
    private async formatData(recievedFile: File) {
        const filedata: Uint8Array = await this.getUint8ArrayView(recievedFile);
        return {
            filedata,
            metadata: {
                name: recievedFile.name,
                size: recievedFile.size,
                type: recievedFile.type,
                creationTime: Number(Date.now()) * 1000,
                lastModified: (recievedFile.lastModified) * 1000,
            },
            thumbnail: await this.generateThumbnail(recievedFile)
        }
    }
    private async encryptFiles(worker, file: formatedFile, encryptionKey: Uint8Array): Promise<encryptedFile> {


        const encryptFileResult = await worker.encryptFile(
            file.filedata,
            null
        );

        const { key: fileKey, file: filedata }: encryptionResult = encryptFileResult;

        const { file: encryptedThumbnail }: encryptionResult = await worker.encryptThumbnail(file.thumbnail, fileKey);

        const { file: encryptedMetadata }: encryptionResult = await worker.encryptMetadata(file.metadata, fileKey)

        const { encryptedData: encryptedKey, nonce: keyDecryptionNonce }: keyEncryptionResult = await worker.encryptToB64(fileKey, encryptionKey);


        const result: encryptedFile = {
            key: fileKey,
            filedata: filedata,
            thumbnail: encryptedThumbnail,
            metadata: encryptedMetadata,
            encryptedKey,
            keyDecryptionNonce,
        };
        return result;
    }

    private async uploadtoBucket(file: encryptedFile, token): Promise<objectKeys> {
        const fileUploadURL = await this.getUploadURL(token);
        const fileObjectKey = await this.putFile(fileUploadURL, file.filedata.encryptedData)

        const thumbnailUploadURL = await this.getUploadURL(token);
        const thumbnailObjectKey = await this.putFile(thumbnailUploadURL, file.thumbnail.encryptedData)

        return {
            file: { objectKey: fileObjectKey, decryptionHeader: file.filedata.decryptionHeader },
            thumbnail: { objectKey: thumbnailObjectKey, decryptionHeader: file.thumbnail.decryptionHeader }
        };
    }

    private async uploadFile(collectionLatestFile: collectionLatestFile, encryptedFile: encryptedFile, objectKeys: objectKeys, token) {
        const uploadFile: uploadFile = {
            collectionID: collectionLatestFile.collection.id,
            encryptedKey: encryptedFile.encryptedKey,
            keyDecryptionNonce: encryptedFile.keyDecryptionNonce,
            metadata: {
                encryptedData: encryptedFile.metadata.encryptedData,
                decryptionHeader: encryptedFile.metadata.decryptionHeader
            },
            ...objectKeys
        }
        console.log(uploadFile);


        const response = await HTTPService.post(`${ENDPOINT}/files`, uploadFile, { token });

        return response.data;
    }

    private async generateThumbnail(file: File): Promise<Uint8Array> {
        let canvas = document.createElement("canvas");
        let canvas_CTX = canvas.getContext("2d");
        let type = file.type.split('/')[0];
        console.log(type);
        if (type === "image") {
            let image = new Image();
            image.setAttribute("src", URL.createObjectURL(file));
            await new Promise((resolve, reject) => {
                image.onload = () => {
                    console.log(image);
                    canvas.width = image.width;
                    canvas.height = image.height;
                    resolve(null);
                }
            });
            canvas_CTX.drawImage(image, 0, 0, image.width, image.height);
        }
        else {
            let video = document.createElement('video');
            video.setAttribute("src", URL.createObjectURL(file));

            await new Promise((resolve, reject) => {
                video.addEventListener('loadedmetadata', function () {
                    console.log(video);
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                    canvas_CTX.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
                    resolve(null);
                });
            });
        }
        const thumbnail: Uint8Array = await new Promise((resolve, reject) => {
            canvas.toBlob(async (blob) => {
                console.log(URL.createObjectURL(blob));
                resolve(await this.getUint8ArrayView(blob));
            })
        });
        return thumbnail;
    }
    private async getUint8ArrayView(file): Promise<Uint8Array> {
        return await new Promise((resolve, reject) => {
            const reader = new FileReader()

            reader.onabort = () => reject('file reading was aborted')
            reader.onerror = () => reject('file reading has failed')
            reader.onload = () => {
                // Do whatever you want with the file contents
                const result = typeof reader.result === "string" ? new TextEncoder().encode(reader.result) : new Uint8Array(reader.result);
                resolve(result);
            }
            reader.readAsArrayBuffer(file)
        });
    }

    private async getUploadURL(token) {
        if (this.uploadURLs.isEmpty()) {
            await this.fetchUploadURLs(token);
        }
        return this.uploadURLs.pop();
    }

    private async fetchUploadURLs(token): Promise<void> {
        if (!this.uploadURLFetchInProgress) {
            this.uploadURLFetchInProgress = HTTPService.get(`${ENDPOINT}/files/upload-urls`,
                {
                    token: token,
                    count: "42"  //m4gic number
                })
            const response = await this.uploadURLFetchInProgress;

            this.uploadURLFetchInProgress = null;
            this.uploadURLs.push(response.data["urls"]);
        }
        return this.uploadURLFetchInProgress;
    }

    private async putFile(fileUploadURL: uploadURL, file: Uint8Array | string): Promise<string> {
        const fileSize = file.length.toString();
        await HTTPService.put(fileUploadURL.url, file, null, { contentLengthHeader: fileSize })
        return fileUploadURL.objectKey;
    }
}

export default new UploadService();

