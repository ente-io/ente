import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
import EXIF from 'exif-js';
import { fileAttribute } from './fileService';
import { collection } from './collectionService';
import { FILE_TYPE } from 'pages/gallery';
import { checkConnectivity } from 'utils/common/utilFunctions';
import { ErrorHandler } from 'utils/common/errorUtil';
import CryptoWorker from 'utils/crypto/cryptoWorker';
import * as convert from 'xml-js';
import { ENCRYPTION_CHUNK_SIZE } from 'utils/crypto/libsodium';
const ENDPOINT = getEndpoint();

const THUMBNAIL_HEIGHT = 720;
const MAX_URL_REQUESTS = 50;
const MAX_ATTEMPTS = 3;
const MIN_THUMBNAIL_SIZE = 50000;
const MAX_CONCURRENT_UPLOADS = 4;
const TYPE_IMAGE = 'image';
const TYPE_VIDEO = 'video';
const TYPE_JSON = 'json';
const SOUTH_DIRECTION = 'S';
const WEST_DIRECTION = 'W';
const MIN_STREAM_FILE_SIZE = 20 * 1024 * 1024;
const CHUNKS_COMBINED_FOR_UPLOAD = 2;

export interface DataStream {
    stream: ReadableStream<Uint8Array>;
    chunkCount: number;
}

function isDataStream(object: any): object is DataStream {
    return object.hasOwnProperty('stream');
}
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

interface MultipartUploadURLs {
    objectKey: string;
    partURLs: string[];
    completeURL: string;
}

export interface MetadataObject {
    title: string;
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
    fileType: FILE_TYPE;
}

interface FileInMemory {
    filedata: Uint8Array | DataStream;
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
        receivedFiles: File[],
        collection: collection,
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
            receivedFiles.forEach((file) => {
                if (
                    file.type.substr(0, 5) === TYPE_IMAGE ||
                    file.type.substr(0, 5) === TYPE_VIDEO
                ) {
                    actualFiles.push(file);
                }
                if (file.name.slice(-4) == TYPE_JSON) {
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
                console.log('error fetching uploadURLs', e);
                ErrorHandler(e);
            }
            const uploadProcesses = [];
            for (
                let i = 0;
                i < Math.min(MAX_CONCURRENT_UPLOADS, this.totalFileCount);
                i++
            ) {
                uploadProcesses.push(
                    this.uploader(
                        await new CryptoWorker(),
                        new FileReader(),
                        this.filesToBeUploaded.pop(),
                        collection,
                        token
                    )
                );
            }
            await Promise.all(uploadProcesses);
            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(100);
        } catch (e) {
            console.log('uploading failed with error', e);
            this.filesToBeUploaded = [];
            console.error(e);
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
            let file: FileInMemory = await this.readFile(reader, rawFile);
            let {
                file: encryptedFile,
                fileKey: encryptedKey,
            }: EncryptedFile = await this.encryptFile(
                worker,
                file,
                collection.key
            );
            let backupedFile: BackupedFile = await this.uploadToBucket(
                encryptedFile,
                token
            );
            file = null;
            encryptedFile = null;
            let uploadFile: uploadFile = this.getUploadFile(
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
            console.log('file upload failed with error', e);
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

    private async readFile(reader: FileReader, receivedFile: File) {
        try {
            const thumbnail = await this.generateThumbnail(
                reader,
                receivedFile
            );

            let fileType: FILE_TYPE;
            switch (receivedFile.type.split('/')[0]) {
                case TYPE_IMAGE:
                    fileType = FILE_TYPE.IMAGE;
                    break;
                case TYPE_VIDEO:
                    fileType = FILE_TYPE.VIDEO;
                    break;
                default:
                    fileType = FILE_TYPE.OTHERS;
            }

            const { location, creationTime } = await this.getExifData(
                reader,
                receivedFile,
                fileType
            );
            const metadata = Object.assign(
                {
                    title: receivedFile.name,
                    creationTime:
                        creationTime || receivedFile.lastModified * 1000,
                    modificationTime: receivedFile.lastModified * 1000,
                    latitude: location?.latitude,
                    longitude: location?.latitude,
                    fileType,
                },
                this.metadataMap.get(receivedFile.name)
            );
            const filedata =
                receivedFile.size > MIN_STREAM_FILE_SIZE
                    ? this.getFileStream(reader, receivedFile)
                    : await this.getUint8ArrayView(reader, receivedFile);

            return {
                filedata,
                thumbnail,
                metadata,
            };
        } catch (e) {
            console.error('error reading files ', e);
            throw e;
        }
    }

    private async encryptFile(
        worker: any,
        file: FileInMemory,
        encryptionKey: string
    ): Promise<EncryptedFile> {
        try {
            const {
                key: fileKey,
                file: encryptedFiledata,
            }: EncryptionResult = isDataStream(file.filedata)
                ? await this.encryptFileStream(worker, file.filedata)
                : await worker.encryptFile(file.filedata);

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
            console.error('Error encrypting files ', e);
            throw e;
        }
    }

    private async encryptFileStream(worker, fileData: DataStream) {
        const { stream, chunkCount } = fileData;
        const fileStreamReader = stream.getReader();
        const {
            key,
            decryptionHeader,
            pushState,
        } = await worker.initChunkEncryption();

        const encryptedFileStream = new ReadableStream({
            async start(controller) {
                for (let i = 0; i < chunkCount; i++) {
                    let { value } = await fileStreamReader.read();

                    const encryptedFileChunk = await worker.encryptFileChunk(
                        value,
                        pushState,
                        i === chunkCount - 1
                    );
                    controller.enqueue(encryptedFileChunk);
                }
                controller.close();
            },
        });
        return {
            key,
            file: {
                decryptionHeader,
                encryptedData: { stream: encryptedFileStream, chunkCount },
            },
        };
    }

    private async uploadToBucket(
        file: ProcessedFile,
        token: string
    ): Promise<BackupedFile> {
        try {
            if (isDataStream(file.file.encryptedData)) {
                const { chunkCount, stream } = file.file.encryptedData;
                const filePartUploadURLs = await this.fetchMultipartUploadURLs(
                    token,
                    Math.ceil(chunkCount / CHUNKS_COMBINED_FOR_UPLOAD)
                );
                file.file.objectKey = await this.putFileInParts(
                    filePartUploadURLs,
                    stream
                );
            } else {
                const fileUploadURL = await this.getUploadURL(token);
                file.file.objectKey = await this.putFile(
                    fileUploadURL,
                    file.file.encryptedData
                );
            }
            const thumbnailUploadURL = await this.getUploadURL(token);
            file.thumbnail.objectKey = await this.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData as Uint8Array
            );
            delete file.file.encryptedData;
            delete file.thumbnail.encryptedData;

            return file;
        } catch (e) {
            console.error('error uploading to bucket ', e);
            throw e;
        }
    }

    private getUploadFile(
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
            console.error('upload Files Failed ', e);
            throw e;
        }
    }

    private async seedMetadataMap(receivedFile: File) {
        try {
            const metadataJSON: object = await new Promise(
                (resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                        let result =
                            typeof reader.result !== 'string'
                                ? new TextDecoder().decode(reader.result)
                                : reader.result;
                        resolve(JSON.parse(result));
                    };
                    reader.readAsText(receivedFile);
                }
            );

            const metaDataObject = {};
            metaDataObject['creationTime'] =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
            metaDataObject['modificationTime'] =
                metadataJSON['modificationTime']['timestamp'] * 1000000;

            let locationData = null;
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
                metaDataObject['latitude'] = locationData['latitude'];
                metaDataObject['longitude'] = locationData['longitude'];
            }
            this.metadataMap.set(metadataJSON['title'], metaDataObject);
        } catch (e) {
            //ignore
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
            if (file.type.match(TYPE_IMAGE)) {
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
                        video = null;
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
            console.error('Error generating thumbnail ', e);
            throw e;
        }
    }

    private getFileStream(reader: FileReader, file: File) {
        let fileSize = file.size;
        let offset = 0;
        let self = this;
        return {
            stream: new ReadableStream<Uint8Array>({
                async start(controller) {
                    while (offset < fileSize) {
                        let blob = file.slice(
                            offset,
                            ENCRYPTION_CHUNK_SIZE + offset
                        );
                        let fileChunk = await self.getUint8ArrayView(
                            reader,
                            blob
                        );
                        controller.enqueue(fileChunk);
                        offset += ENCRYPTION_CHUNK_SIZE;
                    }
                    controller.close();
                },
            }),
            chunkCount: Math.ceil(fileSize / ENCRYPTION_CHUNK_SIZE),
        };
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
            console.error('error reading file to byte-array ', e);
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
                            MAX_URL_REQUESTS,
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
            console.error('fetch upload-url failed ', e);
            throw e;
        }
    }

    private async fetchMultipartUploadURLs(
        token: string,
        count: number
    ): Promise<MultipartUploadURLs> {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/files/multipart-upload-urls`,
                {
                    count,
                },
                { 'X-Auth-Token': token }
            );

            return response.data['multipartUploadURLs'];
        } catch (e) {
            console.log('fetch multipart-upload-url failed ', e);
            throw e;
        }
    }

    private async putFile(
        fileUploadURL: UploadURL,
        file: Uint8Array
    ): Promise<string> {
        try {
            await HTTPService.put(fileUploadURL.url, file);
            return fileUploadURL.objectKey;
        } catch (e) {
            console.error('putFile to dataStore failed ', e);
            throw e;
        }
    }

    private async putFileInParts(
        multipartUploadURLs: MultipartUploadURLs,
        file: ReadableStream<Uint8Array>
    ) {
        let streamEncryptedFileReader = file.getReader();
        const resParts = [];
        for (const [
            index,
            fileUploadURL,
        ] of multipartUploadURLs.partURLs.entries()) {
            let {
                done: done1,
                value: chunk1,
            } = await streamEncryptedFileReader.read();
            if (done1) {
                break;
            }
            let {
                done: done2,
                value: chunk2,
            } = await streamEncryptedFileReader.read();
            let uploadChunk: Uint8Array;
            if (!done2) {
                uploadChunk = new Uint8Array(chunk1.length + chunk2.length);
                uploadChunk.set(chunk1);
                uploadChunk.set(chunk2, chunk1.length);
            } else {
                uploadChunk = chunk1;
            }
            const response = await HTTPService.put(fileUploadURL, uploadChunk);
            resParts.push({
                PartNumber: index + 1,
                ETag: response.headers.etag,
            });
        }
        var options = { compact: true, ignoreComment: true, spaces: 4 };
        const body = convert.js2xml(
            { CompleteMultipartUpload: { Part: resParts } },
            options
        );
        await HTTPService.post(multipartUploadURLs.completeURL, body, null, {
            'content-type': 'text/xml',
        });
        return multipartUploadURLs.objectKey;
    }

    private async getExifData(
        reader: FileReader,
        receivedFile: File,
        fileType: FILE_TYPE
    ) {
        try {
            if (fileType === FILE_TYPE.VIDEO) {
                // Todo  extract exif data from videos
                return { location: null, creationTime: null };
            }
            const exifData: any = await new Promise((resolve, reject) => {
                reader.onload = () => {
                    resolve(EXIF.readFromBinaryFile(reader.result));
                };
                reader.readAsArrayBuffer(receivedFile);
            });
            if (!exifData) {
                return { location: null, creationTime: null };
            }
            return {
                location: this.getLocation(exifData),
                creationTime: this.getUNIXTime(exifData),
            };
        } catch (e) {
            console.error('error reading exif data');
            throw e;
        }
    }
    private getUNIXTime(exifData: any) {
        let dateString: string = exifData.DateTimeOriginal || exifData.DateTime;
        if (!dateString) {
            return null;
        }
        let parts = dateString.split(' ')[0].split(':');
        let date = new Date(
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

        let latDirection = exifData.GPSLatitudeRef;
        let lonDirection = exifData.GPSLongitudeRef;

        let latFinal = this.convertDMSToDD(
            latDegree,
            latMinute,
            latSecond,
            latDirection
        );

        let lonFinal = this.convertDMSToDD(
            lonDegree,
            lonMinute,
            lonSecond,
            lonDirection
        );
        return { latitude: latFinal * 1.0, longitude: lonFinal * 1.0 };
    }

    private convertDMSToDD(degrees, minutes, seconds, direction) {
        let dd = degrees + minutes / 60 + seconds / 3600;

        if (direction == SOUTH_DIRECTION || direction == WEST_DIRECTION) {
            dd = dd * -1;
        }

        return dd;
    }
}

export default new UploadService();
