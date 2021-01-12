import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
import localForage from 'localforage';
import { fileAttribute, collectionLatestFile, collection, file } from './fileService';
import { FILE_TYPE } from 'pages/gallery';
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

export enum UPLOAD_STAGES {
    START = "Preparing to upload",
    ENCRYPTION = "Encryting your files",
    UPLOAD = "Uploading your Files",
    FINISH = "Files Uploaded Successfully !!!"
}

class UploadService {

    private uploadURLs = new Queue<uploadURL>();
    private uploadURLFetchInProgress: Promise<any> = null
    private perStepProgress: number
    private stepsCompleted: number
    private totalFilesCount: number

    public async uploadFiles(recievedFiles: File[], collectionLatestFile: collectionLatestFile, token: string, progressBarProps) {
        try {
            const worker = await new CryptoWorker();
            this.stepsCompleted = 0;
            this.totalFilesCount = recievedFiles.length;
            this.perStepProgress = 100 / (2 * recievedFiles.length);

            progressBarProps.setUploadStage(UPLOAD_STAGES.ENCRYPTION);
            const encryptedFiles: encryptedFile[] = await Promise.all(recievedFiles.map(async (recievedFile: File, index) => {
                const file = await this.formatData(recievedFile);
                const encryptedFile = await this.encryptFiles(worker, file, collectionLatestFile.collection.key);

                this.changeUploadProgressProps(progressBarProps);
                return encryptedFile;
            }));

            progressBarProps.setUploadStage(UPLOAD_STAGES.UPLOAD);
            await Promise.all(encryptedFiles.map(async (encryptedFile: encryptedFile, index) => {

                const objectKeys = await this.uploadtoBucket(encryptedFile, token);
                await this.uploadFile(collectionLatestFile, encryptedFile, objectKeys, token);
                this.changeUploadProgressProps(progressBarProps);

            }));

            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(100);

        }
        catch (e) {
            console.log(e);
        }
    }

    private changeUploadProgressProps({ setPercentComplete, setFileCounter }) {
        this.stepsCompleted++;
        const fileCompleted = this.stepsCompleted % this.totalFilesCount;
        setFileCounter({ current: fileCompleted + 1, total: this.totalFilesCount });
        setPercentComplete(this.perStepProgress * this.stepsCompleted);
    }
    private async formatData(recievedFile: File) {
        const filedata: Uint8Array = await this.getUint8ArrayView(recievedFile);
        let fileType;
        switch (recievedFile.type.split('/')[0]) {
            case "image":
                fileType = FILE_TYPE.IMAGE;
                break;
            case "video":
                fileType = FILE_TYPE.VIDEO;
            default:
                fileType = FILE_TYPE.OTHERS;
        }
        return {
            filedata,
            metadata: {
                title: recievedFile.name,
                creationTime: Number(Date.now()) * 1000,
                modificationTime: (recievedFile.lastModified) * 1000,
                latitude: null,
                longitude: null,
                fileType,
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


        const response = await HTTPService.post(`${ENDPOINT}/files`, uploadFile, { token });

        return response.data;
    }

    private async generateThumbnail(file: File): Promise<Uint8Array> {
        let canvas = document.createElement("canvas");
        let canvas_CTX = canvas.getContext("2d");
        let type = file.type.split('/')[0];
        if (type === "image") {
            let image = new Image();
            image.setAttribute("src", URL.createObjectURL(file));
            await new Promise((resolve, reject) => {
                image.onload = () => {
                    canvas.width = image.width;
                    canvas.height = image.height;
                    canvas_CTX.drawImage(image, 0, 0, image.width, image.height);
                    image = undefined;
                    resolve(null);
                }
            });

        }
        else {
            let video = document.createElement('video');
            video.setAttribute("src", URL.createObjectURL(file));

            await new Promise((resolve, reject) => {
                video.addEventListener('loadedmetadata', function () {
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                    canvas_CTX.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
                    video = undefined;
                    resolve(null);
                });
            });
        }
        const thumbnail: Uint8Array = await new Promise((resolve, reject) => {
            canvas.toBlob(async (blob) => {
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

