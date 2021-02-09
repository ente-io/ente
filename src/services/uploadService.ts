import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import * as Comlink from 'comlink';
import EXIF from 'exif-js';
import { fileAttribute } from './fileService';
import { collection, CollectionAndItsLatestFile } from './collectionService';
import { FILE_TYPE } from 'pages/gallery';
const CryptoWorker: any =
    typeof window !== 'undefined' &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));
const ENDPOINT = getEndpoint();

interface encryptionResult {
    file: fileAttribute;
    key: string;
}
export interface keyEncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

interface uploadURL {
    url: string;
    objectKey: string;
}

interface FileinMemory {
    filedata: Uint8Array;
    thumbnail: Uint8Array;
    filename: string;
}

interface encryptedFile {
    filedata: fileAttribute;
    thumbnail: fileAttribute;
    fileKey: keyEncryptionResult;
}

interface objectKey {
    objectKey: string;
    decryptionHeader: string;
}
interface objectKeys {
    file: objectKey;
    thumbnail: objectKey;
}

interface uploadFile extends objectKeys {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    metadata?: {
        encryptedData: string | Uint8Array;
        decryptionHeader: string;
    };
}

interface UploadFileWithoutMetaData {
    tempUploadFile: uploadFile;
    encryptedFileKey: keyEncryptionResult;
    fileName: string;
}

export enum UPLOAD_STAGES {
    START,
    ENCRYPTION,
    UPLOAD,
    FINISH,
}

class UploadService {
    private uploadURLs: uploadURL[];
    private uploadURLFetchInProgress: Promise<any>;
    private perStepProgress: number;
    private stepsCompleted: number;
    private totalFilesCount: number;
    private metadataMap: Map<string, Object>;

    public async uploadFiles(
        recievedFiles: File[],
        collectionAndItsLatestFile: CollectionAndItsLatestFile,
        token: string,
        progressBarProps
    ) {
        try {
            const worker = await new CryptoWorker();
            this.stepsCompleted = 0;
            this.metadataMap = new Map<string, object>();
            this.uploadURLs = [];
            this.uploadURLFetchInProgress = null;

            let metadataFiles: File[] = [];
            let actualFiles: File[] = [];
            recievedFiles.forEach((file) => {
                if (
                    file.type.substr(0, 5) === 'image' ||
                    file.type.substr(0, 5) === 'video'
                ) {
                    actualFiles.push(file);
                }
                if (file.name.slice(-4) == 'json') {
                    metadataFiles.push(file);
                }
            });
            this.totalFilesCount = actualFiles.length;
            this.perStepProgress = 100 / (3 * actualFiles.length);

            progressBarProps.setUploadStage(UPLOAD_STAGES.START);
            this.changeProgressBarProps(progressBarProps);

            const uploadFilesWithoutMetaData: UploadFileWithoutMetaData[] = [];

            while (actualFiles.length > 0) {
                var promises = [];
                for (var i = 0; i < 5 && actualFiles.length > 0; i++)
                    promises.push(
                        this.uploadHelper(
                            progressBarProps,
                            actualFiles.pop(),
                            collectionAndItsLatestFile.collection,
                            token
                        )
                    );
                uploadFilesWithoutMetaData.push(
                    ...(await Promise.all(promises))
                );
            }

            for await (const rawFile of metadataFiles) {
                await this.updateMetadata(rawFile);
            }

            progressBarProps.setUploadStage(UPLOAD_STAGES.ENCRYPTION);
            const completeUploadFiles: uploadFile[] = await Promise.all(
                uploadFilesWithoutMetaData.map(
                    async (file: UploadFileWithoutMetaData) => {
                        const {
                            file: encryptedMetaData,
                        } = await this.encryptMetadata(
                            worker,
                            file.fileName,
                            file.encryptedFileKey
                        );
                        const completeUploadFile = {
                            ...file.tempUploadFile,
                            metadata: {
                                encryptedData: encryptedMetaData.encryptedData,
                                decryptionHeader:
                                    encryptedMetaData.decryptionHeader,
                            },
                        };
                        this.changeProgressBarProps(progressBarProps);
                        return completeUploadFile;
                    }
                )
            );

            progressBarProps.setUploadStage(UPLOAD_STAGES.UPLOAD);
            await Promise.all(
                completeUploadFiles.map(async (uploadFile: uploadFile) => {
                    await this.uploadFile(uploadFile, token);
                    this.changeProgressBarProps(progressBarProps);
                })
            );

            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(100);
        } catch (e) {
            console.log(e);
            throw e;
        }
    }
    private async uploadHelper(progressBarProps, rawFile, collection, token) {
        try {
            const worker = await new CryptoWorker();
            let file: FileinMemory = await this.readFile(rawFile);
            let encryptedFile: encryptedFile = await this.encryptFile(
                worker,
                file,
                collection.key
            );
            let objectKeys = await this.uploadtoBucket(
                encryptedFile,
                token,
                2 * this.totalFilesCount
            );
            let uploadFileWithoutMetaData: uploadFile = this.getuploadFile(
                collection,
                encryptedFile.fileKey,
                objectKeys
            );
            this.changeProgressBarProps(progressBarProps);

            return {
                tempUploadFile: uploadFileWithoutMetaData,
                encryptedFileKey: encryptedFile.fileKey,
                fileName: file.filename,
            };
        } catch (e) {
            console.log(e);
            throw e;
        }
    }

    private changeProgressBarProps({ setPercentComplete, setFileCounter }) {
        this.stepsCompleted++;
        const fileCompleted = this.stepsCompleted % this.totalFilesCount;
        setFileCounter({ current: fileCompleted, total: this.totalFilesCount });
        setPercentComplete(this.perStepProgress * this.stepsCompleted);
    }

    private async readFile(recievedFile: File) {
        try {
            const filedata: Uint8Array = await this.getUint8ArrayView(
                recievedFile
            );
            let fileType;
            switch (recievedFile.type.split('/')[0]) {
                case 'image':
                    fileType = FILE_TYPE.IMAGE;
                    break;
                case 'video':
                    fileType = FILE_TYPE.VIDEO;
                    break;
                default:
                    fileType = FILE_TYPE.OTHERS;
            }

            const { location, creationTime } = await this.getExifData(
                recievedFile
            );
            this.metadataMap.set(recievedFile.name, {
                title: recievedFile.name,
                creationTime: creationTime || recievedFile.lastModified * 1000,
                modificationTime: recievedFile.lastModified * 1000,
                latitude: location?.latitude,
                longitude: location?.latitude,
                fileType,
            });
            return {
                filedata,
                filename: recievedFile.name,
                thumbnail: await this.generateThumbnail(recievedFile),
            };
        } catch (e) {
            console.log('error reading files ' + e);
        }
    }
    private async encryptFile(
        worker,
        file: FileinMemory,
        encryptionKey: string
    ): Promise<encryptedFile> {
        try {
            const {
                key: fileKey,
                file: encryptedFiledata,
            }: encryptionResult = await worker.encryptFile(file.filedata);

            const {
                file: encryptedThumbnail,
            }: encryptionResult = await worker.encryptThumbnail(
                file.thumbnail,
                fileKey
            );

            const encryptedKey: keyEncryptionResult = await worker.encryptToB64(
                fileKey,
                encryptionKey
            );

            const result: encryptedFile = {
                filedata: encryptedFiledata,
                thumbnail: encryptedThumbnail,
                fileKey: encryptedKey,
            };
            return result;
        } catch (e) {
            console.log('Error encrypting files ' + e);
        }
    }

    private async encryptMetadata(
        worker: any,
        fileName: string,
        encryptedFileKey: keyEncryptionResult
    ) {
        const metaData = this.metadataMap.get(fileName);
        const fileKey = await worker.decryptB64(
            encryptedFileKey.encryptedData,
            encryptedFileKey.nonce,
            encryptedFileKey.key
        );
        const encryptedMetaData = await worker.encryptMetadata(
            metaData,
            fileKey
        );
        return encryptedMetaData;
    }

    private async uploadtoBucket(
        file: encryptedFile,
        token,
        count: number
    ): Promise<objectKeys> {
        try {
            const fileUploadURL = await this.getUploadURL(token, count);
            const fileObjectKey = await this.putFile(
                fileUploadURL,
                file.filedata.encryptedData
            );

            const thumbnailUploadURL = await this.getUploadURL(token, count);
            const thumbnailObjectKey = await this.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData
            );

            return {
                file: {
                    objectKey: fileObjectKey,
                    decryptionHeader: file.filedata.decryptionHeader,
                },
                thumbnail: {
                    objectKey: thumbnailObjectKey,
                    decryptionHeader: file.thumbnail.decryptionHeader,
                },
            };
        } catch (e) {
            console.log('error uploading to bucket ' + e);
            throw e;
        }
    }

    private getuploadFile(
        collection: collection,
        encryptedKey: keyEncryptionResult,
        objectKeys: objectKeys
    ): uploadFile {
        const uploadFile: uploadFile = {
            collectionID: collection.id,
            encryptedKey: encryptedKey.encryptedData,
            keyDecryptionNonce: encryptedKey.nonce,
            ...objectKeys,
        };
        return uploadFile;
    }

    private async uploadFile(uploadFile: uploadFile, token) {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/files`,
                uploadFile,
                null,
                { 'X-Auth-Token': token }
            );

            return response.data;
        } catch (e) {
            console.log('upload Files Failed ' + e);
        }
    }

    private async updateMetadata(recievedFile: File) {
        try {
            const metadataJSON: object = await new Promise(
                (resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                        var result =
                            typeof reader.result !== 'string'
                                ? new TextDecoder().decode(reader.result)
                                : reader.result;
                        resolve(JSON.parse(result));
                    };
                    reader.readAsText(recievedFile);
                }
            );
            if (!this.metadataMap.has(metadataJSON['title'])) {
                return;
            }

            const metaDataObject = this.metadataMap.get(metadataJSON['title']);
            metaDataObject['creationTime'] =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
            metaDataObject['modificationTime'] =
                metadataJSON['modificationTime']['timestamp'] * 1000000;

            if (
                metaDataObject['latitude'] == null ||
                (metaDataObject['latitude'] == 0.0 &&
                    metaDataObject['longitude'] == 0.0)
            ) {
                var locationData = null;
                if (
                    metadataJSON['geoData']['latitude'] != 0.0 ||
                    metadataJSON['geoData']['longitude'] != 0.0
                ) {
                    locationData = metadataJSON['geoData'];
                } else if (
                    metadataJSON['geoDataExif']['latitude'] != 0.0 ||
                    metadataJSON['geoDataExif']['longitude'] != 0.0
                ) {
                    locationData = metadataJSON['geoDataExif'];
                }
                if (locationData != null) {
                    metaDataObject['latitude'] = locationData['latitide'];
                    metaDataObject['longitude'] = locationData['longitude'];
                }
            }
        } catch (e) {
            console.log('error reading metaData Files ' + e);
        }
    }
    private async generateThumbnail(file: File): Promise<Uint8Array> {
        try {
            let canvas = document.createElement('canvas');
            let canvas_CTX = canvas.getContext('2d');
            let imageURL = null;
            if (file.type.match('image')) {
                let image = new Image();
                imageURL = URL.createObjectURL(file);
                image.setAttribute('src', imageURL);
                await new Promise((resolve) => {
                    image.onload = () => {
                        canvas.width = image.width;
                        canvas.height = image.height;
                        canvas_CTX.drawImage(
                            image,
                            0,
                            0,
                            image.width,
                            image.height
                        );
                        image = undefined;
                        resolve(null);
                    };
                });
            } else {
                await new Promise(async (resolve) => {
                    let video = document.createElement('video');
                    imageURL = URL.createObjectURL(file);
                    var timeupdate = function () {
                        if (snapImage()) {
                            video.removeEventListener('timeupdate', timeupdate);
                            video.pause();
                            resolve(null);
                        }
                    };
                    video.addEventListener('loadeddata', function () {
                        if (snapImage()) {
                            video.removeEventListener('timeupdate', timeupdate);
                            resolve(null);
                        }
                    });
                    var snapImage = function () {
                        canvas.width = video.videoWidth;
                        canvas.height = video.videoHeight;
                        canvas_CTX.drawImage(
                            video,
                            0,
                            0,
                            canvas.width,
                            canvas.height
                        );
                        var image = canvas.toDataURL();
                        var success = image.length > 100000;
                        return success;
                    };
                    video.addEventListener('timeupdate', timeupdate);
                    video.preload = 'metadata';
                    video.src = imageURL;
                    // Load video in Safari / IE11
                    video.muted = true;
                    video.playsInline = true;
                    video.play();
                });
            }
            URL.revokeObjectURL(imageURL);
            var thumbnailBlob = await new Promise((resolve) => {
                canvas.toBlob(function (blob) {
                    resolve(blob);
                }),
                    'image/jpeg',
                    0.4;
            });
            const thumbnail = this.getUint8ArrayView(thumbnailBlob);
            return thumbnail;
        } catch (e) {
            console.log('Error generatin thumbnail ' + e);
        }
    }

    private async getUint8ArrayView(file): Promise<Uint8Array> {
        try {
            return await new Promise((resolve, reject) => {
                const reader = new FileReader();

                reader.onabort = () => reject('file reading was aborted');
                reader.onerror = () => reject('file reading has failed');
                reader.onload = () => {
                    // Do whatever you want with the file contents
                    const result =
                        typeof reader.result === 'string'
                            ? new TextEncoder().encode(reader.result)
                            : new Uint8Array(reader.result);
                    resolve(result);
                };
                reader.readAsArrayBuffer(file);
            });
        } catch (e) {
            console.log('error readinf file to bytearray ' + e);
            throw e;
        }
    }

    private async getUploadURL(token: string, count: number) {
        if (this.uploadURLs.length == 0) {
            await this.fetchUploadURLs(token, count);
        }
        return this.uploadURLs.pop();
    }

    private async fetchUploadURLs(token: string, count: number): Promise<void> {
        try {
            if (!this.uploadURLFetchInProgress) {
                this.uploadURLFetchInProgress = HTTPService.get(
                    `${ENDPOINT}/files/upload-urls`,
                    {
                        count: Math.min(50, count).toString(), //m4gic number
                    },
                    { 'X-Auth-Token': token }
                );
                const response = await this.uploadURLFetchInProgress;

                this.uploadURLFetchInProgress = null;
                this.uploadURLs.push(...response.data['urls']);
            }
            return this.uploadURLFetchInProgress;
        } catch (e) {
            console.log('fetch upload-url failed ' + e);
            throw e;
        }
    }

    private async putFile(
        fileUploadURL: uploadURL,
        file: Uint8Array | string
    ): Promise<string> {
        try {
            const fileSize = file.length.toString();
            await HTTPService.put(fileUploadURL.url, file, null, {
                contentLengthHeader: fileSize,
            });
            return fileUploadURL.objectKey;
        } catch (e) {
            console.log('putFile to dataStore failed ' + e);
            throw e;
        }
    }

    private async getExifData(recievedFile) {
        try {
            const exifData: any = await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => {
                    resolve(EXIF.readFromBinaryFile(reader.result));
                };
                reader.readAsArrayBuffer(recievedFile);
            });
            if (!exifData) {
                return { location: null, creationTime: null };
            }
            return {
                location: this.getLocation(exifData),
                creationTime: this.getUNIXTime(exifData),
            };
        } catch (e) {
            console.log('error reading exif data');
        }
    }
    private getUNIXTime(exifData: any) {
        if (!exifData.DateTimeOriginal) {
            return null;
        }
        let dateString: string = exifData.DateTimeOriginal;
        var parts = dateString.split(' ')[0].split(':');
        var date = new Date(
            Number(parts[0]),
            Number(parts[1]) - 1,
            Number(parts[2])
        );
        return date.getTime() * 1000;
    }

    private getLocation(exifData) {
        if (!exifData.GPSLatitude) {
            return null;
        }
        var latDegree = exifData.GPSLatitude[0].numerator;
        var latMinute = exifData.GPSLatitude[1].numerator;
        var latSecond = exifData.GPSLatitude[2].numerator;
        var latDirection = exifData.GPSLatitudeRef;

        var latFinal = this.convertDMSToDD(
            latDegree,
            latMinute,
            latSecond,
            latDirection
        );

        // Calculate longitude decimal
        var lonDegree = exifData.GPSLongitude[0].numerator;
        var lonMinute = exifData.GPSLongitude[1].numerator;
        var lonSecond = exifData.GPSLongitude[2].numerator;
        var lonDirection = exifData.GPSLongitudeRef;

        var lonFinal = this.convertDMSToDD(
            lonDegree,
            lonMinute,
            lonSecond,
            lonDirection
        );

        return { latitude: latFinal * 1.0, longitude: lonFinal * 1.0 };
    }

    private convertDMSToDD(degrees, minutes, seconds, direction) {
        var dd = degrees + minutes / 60 + seconds / 3600;

        if (direction == 'S' || direction == 'W') {
            dd = dd * -1;
        }

        return dd;
    }
}

export default new UploadService();
