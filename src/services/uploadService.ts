import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import EXIF from 'exif-js';
import { fileAttribute } from './fileService';
import { collection, CollectionAndItsLatestFile } from './collectionService';
import { FILE_TYPE } from 'pages/gallery';
import { checkConnectivity } from 'utils/common/utilFunctions';
import { ErrorHandler } from 'utils/common/errorUtil';
import CryptoWorker from 'utils/crypto/cryptoWorker';
const ENDPOINT = getEndpoint();

const THUMBNAIL_HEIGHT = 720;
const MAX_ATTEMPTS = 3;
const MIN_THUMBNAIL_SIZE = 50000;

interface EncryptionResult {
    file: fileAttribute;
    key: string;
}
export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

interface UploadURL {
    url: string;
    objectKey: string;
}

export interface MetadataObject {
    title: string;
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
    fileType: FILE_TYPE;
}

interface FileinMemory {
    filedata: Uint8Array;
    thumbnail: Uint8Array;
    metadata: MetadataObject;
}

interface EncryptedFile {
    file: ProcessedFile;
    fileKey: B64EncryptionResult;
}
interface ProcessedFile {
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
}
interface BackupedFile extends ProcessedFile {}

interface uploadFile extends BackupedFile {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    UPLOADING,
    FINISH,
}

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private uploadURLFetchInProgress: Promise<any> = null;
    private perFileProgress: number;
    private filesCompleted: number;
    private totalFileCount: number;
    private metadataMap: Map<string, Object>;
    private filesToBeUploaded: File[];
    private progressBarProps;
    private uploadErrors: Error[];
    private setUploadErrors;

    public async uploadFiles(
        recievedFiles: File[],
        collectionAndItsLatestFile: CollectionAndItsLatestFile,
        token: string,
        progressBarProps,
        setUploadErrors
    ) {
        try {
            checkConnectivity();
            progressBarProps.setUploadStage(UPLOAD_STAGES.START);

            this.filesCompleted = 0;
            this.uploadErrors = [];
            this.setUploadErrors = setUploadErrors;
            this.metadataMap = new Map<string, object>();
            this.progressBarProps = progressBarProps;

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
            this.totalFileCount = actualFiles.length;
            this.perFileProgress = 100 / actualFiles.length;
            this.filesToBeUploaded = actualFiles;

            progressBarProps.setUploadStage(
                UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES
            );
            for (const rawFile of metadataFiles) {
                await this.seedMetadataMap(rawFile);
            }

            progressBarProps.setUploadStage(UPLOAD_STAGES.UPLOADING);
            this.changeProgressBarProps();
            try {
                await this.fetchUploadURLs(token);
            } catch (e) {
                ErrorHandler(e);
            }
            const uploadProcesses = [];
            for (let i = 0; i < Math.min(4, this.totalFileCount); i++) {
                uploadProcesses.push(
                    this.uploader(
                        await new CryptoWorker(),
                        new FileReader(),
                        this.filesToBeUploaded.pop(),
                        collectionAndItsLatestFile.collection,
                        token
                    )
                );
            }
            await Promise.all(uploadProcesses);
            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(100);
        } catch (e) {
            this.filesToBeUploaded = [];
            console.log(e);
            throw e;
        }
    }
    private async uploader(
        worker: any,
        reader: FileReader,
        rawFile: File,
        collection: collection,
        token: string
    ) {
        try {
            let file: FileinMemory = await this.readFile(reader, rawFile);
            let {
                file: encryptedFile,
                fileKey: encryptedKey,
            }: EncryptedFile = await this.encryptFile(
                worker,
                file,
                collection.key
            );
            file = null;
            let backupedFile: BackupedFile = await this.uploadtoBucket(
                encryptedFile,
                token
            );
            encryptedFile = null;
            let uploadFile: uploadFile = this.getuploadFile(
                collection,
                backupedFile,
                encryptedKey
            );
            encryptedKey = null;
            backupedFile = null;
            await this.uploadFile(uploadFile, token);
            uploadFile = null;
            this.filesCompleted++;
            this.changeProgressBarProps();
        } catch (e) {
            ErrorHandler(e);
            const error = new Error(
                `Uploading Failed for File - ${rawFile.name}`
            );
            this.uploadErrors.push(error);
        }
        if (this.filesToBeUploaded.length > 0) {
            await this.uploader(
                worker,
                reader,
                this.filesToBeUploaded.pop(),
                collection,
                token
            );
        }
    }

    private changeProgressBarProps() {
        const { setPercentComplete, setFileCounter } = this.progressBarProps;
        setFileCounter({
            current: this.filesCompleted + 1,
            total: this.totalFileCount,
        });
        setPercentComplete(this.filesCompleted * this.perFileProgress);
        this.setUploadErrors(this.uploadErrors);
    }

    private async readFile(reader: FileReader, recievedFile: File) {
        try {
            const filedata: Uint8Array = await this.getUint8ArrayView(
                reader,
                recievedFile
            );
            const thumbnail = await this.generateThumbnail(
                reader,
                recievedFile
            );

            let fileType: FILE_TYPE;
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
                reader,
                recievedFile
            );
            const metadata = Object.assign(
                {
                    title: recievedFile.name,
                    creationTime:
                        creationTime || recievedFile.lastModified * 1000,
                    modificationTime: recievedFile.lastModified * 1000,
                    latitude: location?.latitude,
                    longitude: location?.latitude,
                    fileType,
                },
                this.metadataMap.get(recievedFile.name)
            );
            return {
                filedata,
                thumbnail,
                metadata,
            };
        } catch (e) {
            console.log('error reading files ', e);
            throw e;
        }
    }
    private async encryptFile(
        worker,
        file: FileinMemory,
        encryptionKey: string
    ): Promise<EncryptedFile> {
        try {
            const {
                key: fileKey,
                file: encryptedFiledata,
            }: EncryptionResult = await worker.encryptFile(file.filedata);

            const {
                file: encryptedThumbnail,
            }: EncryptionResult = await worker.encryptThumbnail(
                file.thumbnail,
                fileKey
            );
            const {
                file: encryptedMetadata,
            }: EncryptionResult = await worker.encryptMetadata(
                file.metadata,
                fileKey
            );

            const encryptedKey: B64EncryptionResult = await worker.encryptToB64(
                fileKey,
                encryptionKey
            );

            const result: EncryptedFile = {
                file: {
                    file: encryptedFiledata,
                    thumbnail: encryptedThumbnail,
                    metadata: encryptedMetadata,
                },
                fileKey: encryptedKey,
            };
            return result;
        } catch (e) {
            console.log('Error encrypting files ', e);
            throw e;
        }
    }

    private async uploadtoBucket(
        file: ProcessedFile,
        token
    ): Promise<BackupedFile> {
        try {
            const fileUploadURL = await this.getUploadURL(token);
            file.file.objectKey = await this.putFile(
                fileUploadURL,
                file.file.encryptedData
            );

            const thumbnailUploadURL = await this.getUploadURL(token);
            file.thumbnail.objectKey = await this.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData
            );
            delete file.file.encryptedData;
            delete file.thumbnail.encryptedData;

            return file;
        } catch (e) {
            console.log('error uploading to bucket ', e);
            throw e;
        }
    }

    private getuploadFile(
        collection: collection,
        backupedFile: BackupedFile,
        fileKey: B64EncryptionResult
    ): uploadFile {
        const uploadFile: uploadFile = {
            collectionID: collection.id,
            encryptedKey: fileKey.encryptedData,
            keyDecryptionNonce: fileKey.nonce,
            ...backupedFile,
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
            console.log('upload Files Failed ', e);
            throw e;
        }
    }

    private async seedMetadataMap(recievedFile: File) {
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

            const metaDataObject = {};
            metaDataObject['creationTime'] =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
            metaDataObject['modificationTime'] =
                metadataJSON['modificationTime']['timestamp'] * 1000000;

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
            this.metadataMap.set(metadataJSON['title'], metaDataObject);
        } catch (e) {
            const error = new Error(
                `Error reading metaDataFile ${recievedFile.name}`
            );
            this.uploadErrors.push(error);
            this.setUploadErrors(this.uploadErrors);
        }
    }
    private async generateThumbnail(
        reader: FileReader,
        file: File
    ): Promise<Uint8Array> {
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
                        const thumbnailWidth =
                            (image.width * THUMBNAIL_HEIGHT) / image.height;
                        canvas.width = thumbnailWidth;
                        canvas.height = THUMBNAIL_HEIGHT;
                        canvas_CTX.drawImage(
                            image,
                            0,
                            0,
                            thumbnailWidth,
                            THUMBNAIL_HEIGHT
                        );
                        image = undefined;
                        resolve(null);
                    };
                });
            } else {
                await new Promise(async (resolve) => {
                    let video = document.createElement('video');
                    imageURL = URL.createObjectURL(file);
                    video.addEventListener('loadeddata', function () {
                        const thumbnailWidth =
                            (video.videoWidth * THUMBNAIL_HEIGHT) /
                            video.videoHeight;
                        canvas.width = thumbnailWidth;
                        canvas.height = THUMBNAIL_HEIGHT;
                        canvas_CTX.drawImage(
                            video,
                            0,
                            0,
                            thumbnailWidth,
                            THUMBNAIL_HEIGHT
                        );
                        resolve(null);
                    });
                    video.preload = 'metadata';
                    video.src = imageURL;
                    // Load video in Safari / IE11
                    video.muted = true;
                    video.playsInline = true;
                    video.play();
                });
            }
            URL.revokeObjectURL(imageURL);
            if (canvas.toDataURL().length == 0) {
                throw new Error('');
            }
            let thumbnailBlob: Blob = file,
                attempts = 0;
            let quality = 1;

            do {
                attempts++;
                quality /= 2;
                thumbnailBlob = await new Promise((resolve) => {
                    canvas.toBlob(
                        function (blob) {
                            resolve(blob);
                        },
                        'image/jpeg',
                        quality
                    );
                });
                if (!thumbnailBlob) {
                    thumbnailBlob = file;
                }
            } while (
                thumbnailBlob.size > MIN_THUMBNAIL_SIZE &&
                attempts <= MAX_ATTEMPTS
            );
            const thumbnail = await this.getUint8ArrayView(
                reader,
                thumbnailBlob
            );
            return thumbnail;
        } catch (e) {
            console.log('Error generating thumbnail ', e);
            throw e;
        }
    }

    private async getUint8ArrayView(
        reader: FileReader,
        file: Blob
    ): Promise<Uint8Array> {
        try {
            return await new Promise((resolve, reject) => {
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
            console.log('error readinf file to bytearray ', e);
            throw e;
        }
    }

    private async getUploadURL(token: string) {
        if (this.uploadURLs.length == 0) {
            await this.fetchUploadURLs(token);
        }
        return this.uploadURLs.pop();
    }

    private async fetchUploadURLs(token: string): Promise<void> {
        try {
            if (!this.uploadURLFetchInProgress) {
                this.uploadURLFetchInProgress = HTTPService.get(
                    `${ENDPOINT}/files/upload-urls`,
                    {
                        count: Math.min(
                            50,
                            (this.totalFileCount - this.filesCompleted) * 2
                        ),
                    },
                    { 'X-Auth-Token': token }
                );
                const response = await this.uploadURLFetchInProgress;

                this.uploadURLFetchInProgress = null;
                this.uploadURLs.push(...response.data['urls']);
            }
            return this.uploadURLFetchInProgress;
        } catch (e) {
            console.log('fetch upload-url failed ', e);
            throw e;
        }
    }

    private async putFile(
        fileUploadURL: UploadURL,
        file: Uint8Array | string
    ): Promise<string> {
        try {
            const fileSize = file.length;
            await HTTPService.put(fileUploadURL.url, file, null, {
                contentLengthHeader: fileSize,
            });
            return fileUploadURL.objectKey;
        } catch (e) {
            console.log('putFile to dataStore failed ', e);
            throw e;
        }
    }

    private async getExifData(reader: FileReader, recievedFile: File) {
        try {
            const exifData: any = await new Promise((resolve, reject) => {
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
            throw e;
        }
    }
    private getUNIXTime(exifData: any) {
        let dateString: string = exifData.DateTimeOriginal || exifData.DateTime;
        if (!dateString) {
            return null;
        }
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

        let latDegree: number, latMinute: number, latSecond: number;
        let lonDegree: number, lonMinute: number, lonSecond: number;

        latDegree = exifData.GPSLatitude[0];
        latMinute = exifData.GPSLatitude[1];
        latSecond = exifData.GPSLatitude[2];

        lonDegree = exifData.GPSLongitude[0];
        lonMinute = exifData.GPSLongitude[1];
        lonSecond = exifData.GPSLongitude[2];

        var latDirection = exifData.GPSLatitudeRef;
        var lonDirection = exifData.GPSLongitudeRef;

        var latFinal = this.convertDMSToDD(
            latDegree,
            latMinute,
            latSecond,
            latDirection
        );

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
