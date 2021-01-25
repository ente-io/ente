import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
import EXIF from "exif-js";
import { fileAttribute } from './fileService';
import { collectionLatestFile } from "./collectionService"
import { FILE_TYPE } from 'pages/gallery';
const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();


interface encryptionResult {
    file: fileAttribute,
    key: string
}
export interface keyEncryptionResult {
    encryptedData: string,
    key: string,
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
    key: string;
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
    private metadataMap: Map<string, Object>;

    public async uploadFiles(recievedFiles: File[], collectionLatestFile: collectionLatestFile, token: string, progressBarProps) {
        try {
            const worker = await new CryptoWorker();
            this.stepsCompleted = 0;
            this.metadataMap = new Map<string, object>();

            let metadataFiles: File[] = [];
            let actualFiles: File[] = [];
            recievedFiles.forEach(file => {
                if (file.type.substr(0, 5) === "image" || file.type.substr(0, 5) === "video")
                    actualFiles.push(file);
                if (file.name.slice(-4) == "json")
                    metadataFiles.push(file);
            });
            this.totalFilesCount = actualFiles.length;
            this.perStepProgress = 100 / (3 * actualFiles.length);
            let formatedFiles: formatedFile[] = await Promise.all(actualFiles.map(async (recievedFile: File) => {
                const file = await this.formatData(recievedFile);
                this.changeProgressBarProps(progressBarProps);
                return file;
            }));
            await Promise.all(metadataFiles.map(async (recievedFile: File) => {
                this.updateMetadata(recievedFile)
                this.changeProgressBarProps(progressBarProps);
                return;

            }));
            console.log(formatedFiles);
            progressBarProps.setUploadStage(UPLOAD_STAGES.ENCRYPTION);
            const encryptedFiles: encryptedFile[] = await Promise.all(formatedFiles.map(async (file: formatedFile) => {
                const encryptedFile = await this.encryptFiles(worker, file, collectionLatestFile.collection.key);
                this.changeProgressBarProps(progressBarProps);
                return encryptedFile;
            }));

            progressBarProps.setUploadStage(UPLOAD_STAGES.UPLOAD);
            await Promise.all(encryptedFiles.map(async (encryptedFile: encryptedFile) => {

                const objectKeys = await this.uploadtoBucket(encryptedFile, token, 2 * this.totalFilesCount);
                await this.uploadFile(collectionLatestFile, encryptedFile, objectKeys, token);
                this.changeProgressBarProps(progressBarProps);

            }));

            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(100);

        }
        catch (e) {
            console.log(e);
        }
    }

    private changeProgressBarProps({ setPercentComplete, setFileCounter }) {
        this.stepsCompleted++;
        const fileCompleted = this.stepsCompleted % this.totalFilesCount;
        setFileCounter({ current: fileCompleted + 1, total: this.totalFilesCount });
        setPercentComplete(this.perStepProgress * this.stepsCompleted);
    }

    private async formatData(recievedFile: File) {
        try {
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

            const { location, creationTime } = await this.getExifData(recievedFile);
            this.metadataMap.set(recievedFile.name, {
                title: recievedFile.name,
                creationTime: creationTime || (recievedFile.lastModified) * 1000,
                modificationTime: (recievedFile.lastModified) * 1000,
                latitude: location?.latitude,
                longitude: location?.latitude,
                fileType,
            });
            return {
                filedata,
                metadata: this.metadataMap.get(recievedFile.name),
                thumbnail: await this.generateThumbnail(recievedFile)
            }
        } catch (e) {
            console.log("error reading files " + e);
        }
    }
    private async encryptFiles(worker, file: formatedFile, encryptionKey: string): Promise<encryptedFile> {
        try {

            const { key: fileKey, file: filedata }: encryptionResult = await worker.encryptFile(file.filedata);

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
        catch (e) {
            console.log("Error encrypting files " + e);
        }
    }

    private async uploadtoBucket(file: encryptedFile, token, count: number): Promise<objectKeys> {
        try {
            const fileUploadURL = await this.getUploadURL(token, count);
            const fileObjectKey = await this.putFile(fileUploadURL, file.filedata.encryptedData)

            const thumbnailUploadURL = await this.getUploadURL(token, count);
            const thumbnailObjectKey = await this.putFile(thumbnailUploadURL, file.thumbnail.encryptedData)

            return {
                file: { objectKey: fileObjectKey, decryptionHeader: file.filedata.decryptionHeader },
                thumbnail: { objectKey: thumbnailObjectKey, decryptionHeader: file.thumbnail.decryptionHeader }
            };
        } catch (e) {
            console.log("error uploading to bucket " + e);
        }
    }

    private async uploadFile(collectionLatestFile: collectionLatestFile, encryptedFile: encryptedFile, objectKeys: objectKeys, token) {
        try {
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
        } catch (e) {
            console.log("upload Files Failed " + e);
        }
    }

    private async updateMetadata(recievedFile: File) {
        try {
            const metadataJSON: object = await new Promise((resolve, reject) => {
                const reader = new FileReader()
                reader.onload = () => {
                    var result = typeof reader.result !== "string" ? new TextDecoder().decode(reader.result) : reader.result
                    resolve(JSON.parse(result));
                }
                reader.readAsText(recievedFile)
            });
            if (!this.metadataMap.has(metadataJSON['title']))
                return;

            const metaDataObject = this.metadataMap.get(metadataJSON['title']);
            metaDataObject['creationTime'] = metadataJSON['photoTakenTime']['timestamp'] * 1000000;
            metaDataObject['modificationTime'] = metadataJSON['modificationTime']['timestamp'] * 1000000;

            if (metaDataObject['latitude'] == null || (metaDataObject['latitude'] == 0.0 && metaDataObject['longitude'] == 0.0)) {
                var locationData = null;
                if (metadataJSON['geoData']['latitude'] != 0.0 || metadataJSON['geoData']['longitude'] != 0.0) {
                    locationData = metadataJSON['geoData'];
                }
                else if (metadataJSON['geoDataExif']['latitude'] != 0.0 || metadataJSON['geoDataExif']['longitude'] != 0.0) {
                    locationData = metadataJSON['geoDataExif'];
                }
                if (locationData != null) {
                    metaDataObject['latitude'] = locationData['latitide'];
                    metaDataObject['longitude'] = locationData['longitude'];
                }
            }
        } catch (e) {
            console.log("error reading metaData Files " + e);

        }
    }
    private async generateThumbnail(file: File): Promise<Uint8Array> {
        try {
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
        } catch (e) {
            console.log("Error generatin thumbnail " + e);
        }
    }

    private async getUint8ArrayView(file): Promise<Uint8Array> {
        try {
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
        } catch (e) {
            console.log("error readinf file to bytearray " + e);
            throw e;
        }
    }

    private async getUploadURL(token: string, count: number) {
        if (this.uploadURLs.isEmpty()) {
            await this.fetchUploadURLs(token, count);
        }
        return this.uploadURLs.pop();
    }

    private async fetchUploadURLs(token: string, count: number): Promise<void> {
        try {
            if (!this.uploadURLFetchInProgress) {
                this.uploadURLFetchInProgress = HTTPService.get(`${ENDPOINT}/files/upload-urls`,
                    {
                        token: token,
                        count: Math.min(50, count).toString()  //m4gic number
                    })
                const response = await this.uploadURLFetchInProgress;

                this.uploadURLFetchInProgress = null;
                this.uploadURLs.push(response.data["urls"]);
            }
            return this.uploadURLFetchInProgress;
        } catch (e) {
            console.log("fetch upload-url failed " + e);
            throw e;
        }
    }

    private async putFile(fileUploadURL: uploadURL, file: Uint8Array | string): Promise<string> {
        try {
            const fileSize = file.length.toString();
            await HTTPService.put(fileUploadURL.url, file, null, { contentLengthHeader: fileSize })
            return fileUploadURL.objectKey;
        } catch (e) {
            console.log('putFile to dataStore failed ' + e);
            throw e;
        }
    }

    private async getExifData(recievedFile) {
        try {
            const exifData: any = await new Promise((resolve, reject) => {
                const reader = new FileReader()
                reader.onload = () => {
                    resolve(EXIF.readFromBinaryFile(reader.result));
                }
                reader.readAsArrayBuffer(recievedFile)
            });
            if (!exifData)
                return { location: null, creationTime: null };
            return {
                location: this.getLocation(exifData),
                creationTime: this.getUNIXTime(exifData)
            };
        } catch (e) {
            console.log("error reading exif data");
        }
    }
    private getUNIXTime(exifData: any) {
        if (!exifData.DateTimeOriginal)
            return null;
        let dateString: string = exifData.DateTimeOriginal;
        var parts = dateString.split(' ')[0].split(":");
        var date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        return date.getTime() * 1000;
    }

    private getLocation(exifData) {

        if (!exifData.GPSLatitude)
            return null;
        var latDegree = exifData.GPSLatitude[0].numerator;
        var latMinute = exifData.GPSLatitude[1].numerator;
        var latSecond = exifData.GPSLatitude[2].numerator;
        var latDirection = exifData.GPSLatitudeRef;

        var latFinal = this.convertDMSToDD(latDegree, latMinute, latSecond, latDirection);

        // Calculate longitude decimal
        var lonDegree = exifData.GPSLongitude[0].numerator;
        var lonMinute = exifData.GPSLongitude[1].numerator;
        var lonSecond = exifData.GPSLongitude[2].numerator;
        var lonDirection = exifData.GPSLongitudeRef;

        var lonFinal = this.convertDMSToDD(lonDegree, lonMinute, lonSecond, lonDirection);

        return { latitude: latFinal, longitude: lonFinal };
    }

    private convertDMSToDD(degrees, minutes, seconds, direction) {

        var dd = degrees + (minutes / 60) + (seconds / 3600);

        if (direction == "S" || direction == "W") {
            dd = dd * -1;
        }

        return dd;
    }
}

export default new UploadService();

