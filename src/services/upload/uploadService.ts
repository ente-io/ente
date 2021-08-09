import { File, fileAttribute } from '../fileService';
import { Collection } from '../collectionService';
import { FILE_TYPE, SetFiles } from 'pages/gallery';
import {
    handleError,
    parseError,
} from 'utils/common/errorUtil';
import { ComlinkWorker, getDedicatedCryptoWorker } from 'utils/crypto';
import {
    sortFilesIntoCollections,
    sortFiles,
    decryptFile,
    removeUnneccessaryFileProps,
} from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import { sleep } from 'utils/common';
import NetworkClient, { UploadURL } from './networkClient';
import { extractMetatdata, ParsedMetaDataJSON, parseMetadataJSON } from './metadataService';
import { generateThumbnail } from './thumbnailService';
import { getFileType, getFileOriginalName, getFileData } from './readFileService';
import { encryptFiledata } from './encryptionService';


const MAX_CONCURRENT_UPLOADS = 4;
const TYPE_JSON = 'json';
const FILE_UPLOAD_COMPLETED = 100;
const TwoSecondInMillSeconds = 2000;
export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();
export const CHUNKS_COMBINED_FOR_UPLOAD = 5;

export enum FileUploadErrorCode {
    FAILED = -1,
    SKIPPED = -2,
    UNSUPPORTED = -3,
}

export interface FileWithCollection {
    file: globalThis.File;
    collection: Collection;
}
export interface DataStream {
    stream: ReadableStream<Uint8Array>;
    chunkCount: number;
}

export function isDataStream(object: any): object is DataStream {
    return 'stream' in object;
}
export interface EncryptionResult {
    file: fileAttribute;
    key: string;
}
export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}


export interface MultipartUploadURLs {
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
    hasStaticThumbnail?: boolean;
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
    filename: string;
}
interface BackupedFile extends Omit<ProcessedFile, 'filename'> { }

export type MetadataMap = Map<string, ParsedMetaDataJSON>

export interface UploadFile extends BackupedFile {
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
    private cryptoWorkers = new Array<ComlinkWorker>(MAX_CONCURRENT_UPLOADS);
    private uploadURLs: UploadURL[] = [];
    private perFileProgress: number;
    private filesCompleted: number;
    private totalFileCount: number;
    private fileProgress: Map<string, number>;
    private metadataMap: Map<string, ParsedMetaDataJSON>;
    private filesToBeUploaded: FileWithCollection[];
    private progressBarProps;
    private failedFiles: FileWithCollection[];
    private existingFilesCollectionWise: Map<number, File[]>;
    private existingFiles: File[];
    private setFiles:SetFiles;
    public async uploadFiles(
        filesWithCollectionToUpload: FileWithCollection[],
        existingFiles: File[],
        progressBarProps,
        setFiles:SetFiles,
    ) {
        try {
            progressBarProps.setUploadStage(UPLOAD_STAGES.START);

            this.filesCompleted = 0;
            this.fileProgress = new Map<string, number>();
            this.failedFiles = [];
            this.metadataMap = new Map<string, ParsedMetaDataJSON>();
            this.progressBarProps = progressBarProps;
            this.existingFiles=existingFiles;
            this.existingFilesCollectionWise = sortFilesIntoCollections(existingFiles);
            this.updateProgressBarUI();
            this.setFiles=setFiles;
            const metadataFiles: globalThis.File[] = [];
            const actualFiles: FileWithCollection[] = [];
            filesWithCollectionToUpload.forEach((fileWithCollection) => {
                const file = fileWithCollection.file;
                if (file?.name.substr(0, 1) === '.') {
                    // ignore files with name starting with . (hidden files)
                    return;
                }
                if (file.name.slice(-4) === TYPE_JSON) {
                    metadataFiles.push(fileWithCollection.file);
                } else {
                    actualFiles.push(fileWithCollection);
                }
            });
            this.filesToBeUploaded = actualFiles;

            progressBarProps.setUploadStage(
                UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES,
            );
            this.totalFileCount = metadataFiles.length;
            this.perFileProgress = 100 / metadataFiles.length;
            this.filesCompleted = 0;

            for (const rawFile of metadataFiles) {
                const parsedMetaDataJSON=await parseMetadataJSON(rawFile);
                this.metadataMap.set(parsedMetaDataJSON.title, parsedMetaDataJSON);
                this.filesCompleted++;
                this.updateProgressBarUI();
            }

            progressBarProps.setUploadStage(UPLOAD_STAGES.START);
            this.totalFileCount = actualFiles.length;
            this.perFileProgress = 100 / actualFiles.length;
            this.filesCompleted = 0;
            this.updateProgressBarUI();
            try {
                // checking for any subscription related errors
                await NetworkClient.fetchUploadURLs(this.totalFileCount, this.uploadURLs);
            } catch (e) {
                logError(e, 'error fetching uploadURLs');
                const { parsedError, parsed } = parseError(e);
                if (parsed) {
                    throw parsedError;
                }
            }
            const uploadProcesses = [];
            for (
                let i = 0;
                i < MAX_CONCURRENT_UPLOADS;
                i++
            ) {
                if (this.filesToBeUploaded.length>0) {
                    const fileWithCollection= this.filesToBeUploaded.pop();
                    this.cryptoWorkers[i] = getDedicatedCryptoWorker();
                    uploadProcesses.push(
                        this.uploader(
                            await new this.cryptoWorkers[i].comlink(),
                            new FileReader(),
                            fileWithCollection,
                        ),
                    );
                }
            }
            progressBarProps.setUploadStage(UPLOAD_STAGES.UPLOADING);
            await Promise.all(uploadProcesses);
            progressBarProps.setUploadStage(UPLOAD_STAGES.FINISH);
            progressBarProps.setPercentComplete(FILE_UPLOAD_COMPLETED);
        } catch (e) {
            logError(e, 'uploading failed with error');
            this.filesToBeUploaded = [];
            throw e;
        } finally {
            for (let i = 0; i < MAX_CONCURRENT_UPLOADS; i++) {
                this.cryptoWorkers[i]?.worker.terminate();
            }
        }
    }

    private async uploader(
        worker: any,
        reader: FileReader,
        fileWithCollection: FileWithCollection,
    ) {
        const { file: rawFile, collection } = fileWithCollection;
        this.fileProgress.set(rawFile.name, 0);
        this.updateProgressBarUI();
        let file:FileInMemory=null;
        let encryptedFile: EncryptedFile=null;
        try {
            // read the file into memory
            file = await this.readFile(reader, rawFile, this.metadataMap);

            if (this.fileAlreadyInCollection(file, collection)) {
                // set progress to -2 indicating that file upload was skipped
                this.fileProgress.set(rawFile.name, FileUploadErrorCode.SKIPPED);
                this.updateProgressBarUI();
                await sleep(TwoSecondInMillSeconds);
                // remove completed files for file progress list
                this.fileProgress.delete(rawFile.name);
            } else {
                encryptedFile = await this.encryptFile(worker, file, collection.key);

                const backupedFile: BackupedFile = await this.uploadToBucket(
                    encryptedFile.file,
                );

                let uploadFile: UploadFile = this.getUploadFile(
                    collection,
                    backupedFile,
                    encryptedFile.fileKey,
                );


                const uploadedFile =await NetworkClient.uploadFile(uploadFile);
                const decryptedFile=await decryptFile(uploadedFile, collection);

                this.existingFiles.push(decryptedFile);
                this.existingFiles=sortFiles(this.existingFiles);
                await localForage.setItem('files', removeUnneccessaryFileProps(this.existingFiles));
                this.setFiles(this.existingFiles);

                uploadFile = null;

                this.fileProgress.delete(rawFile.name);
                this.filesCompleted++;
            }
        } catch (e) {
            logError(e, 'file upload failed');
            this.failedFiles.push(fileWithCollection);
            // set progress to -1 indicating that file upload failed but keep it to show in the file-upload list progress
            this.fileProgress.set(rawFile.name, FileUploadErrorCode.FAILED);
            handleError(e);
        } finally {
            file=null;
            encryptedFile=null;
        }
        this.updateProgressBarUI();

        if (this.filesToBeUploaded.length > 0) {
            await this.uploader(
                worker,
                reader,
                this.filesToBeUploaded.pop(),
            );
        }
    }
    async retryFailedFiles(localFiles:File[]) {
        await this.uploadFiles(this.failedFiles, localFiles, this.progressBarProps, this.setFiles);
    }

    private updateProgressBarUI() {
        const { setPercentComplete, setFileCounter, setFileProgress } =
            this.progressBarProps;
        setFileCounter({
            finished: this.filesCompleted,
            total: this.totalFileCount,
        });
        let percentComplete = this.perFileProgress * this.filesCompleted;
        if (this.fileProgress) {
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            for (const [_, progress] of this.fileProgress) {
                // filter  negative indicator values during percentComplete calculation
                if (progress < 0) {
                    continue;
                }
                percentComplete += (this.perFileProgress * progress) / 100;
            }
        }
        setPercentComplete(percentComplete);
        setFileProgress(this.fileProgress);
    }

    async readFile(reader: FileReader, receivedFile: globalThis.File, metadataMap:Map<string, ParsedMetaDataJSON>) {
        try {
            const fileType=getFileType(receivedFile);

            const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
                reader,
                receivedFile,
                fileType,
            );

            const originalName=getFileOriginalName(receivedFile);
            const googleMetadata=metadataMap.get(originalName);
            const extractedMetadata:MetadataObject =await extractMetatdata(reader, receivedFile, fileType);
            if (hasStaticThumbnail) {
                extractedMetadata.hasStaticThumbnail=true;
            }
            const metadata:MetadataObject={ ...extractedMetadata, ...googleMetadata };

            const filedata = await getFileData(reader, receivedFile);

            return {
                filedata,
                thumbnail,
                metadata,
            };
        } catch (e) {
            logError(e, 'error reading files');
            throw e;
        }
    }

    private fileAlreadyInCollection(
        newFile: FileInMemory,
        collection: Collection,
    ): boolean {
        const collectionFiles =
            this.existingFilesCollectionWise.get(collection.id) ?? [];
        for (const existingFile of collectionFiles) {
            if (this.areFilesSame(existingFile.metadata, newFile.metadata)) {
                return true;
            }
        }
        return false;
    }
    private areFilesSame(
        existingFile: MetadataObject,
        newFile: MetadataObject,
    ): boolean {
        if (
            existingFile.fileType === newFile.fileType &&
            existingFile.creationTime === newFile.creationTime &&
            existingFile.modificationTime === newFile.modificationTime &&
            existingFile.title === newFile.title
        ) {
            return true;
        } else {
            return false;
        }
    }


    private async encryptFile(
        worker: any,
        file: FileInMemory,
        encryptionKey: string,
    ): Promise<EncryptedFile> {
        try {
            const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(worker, file.filedata);

            const { file: encryptedThumbnail }: EncryptionResult =
                await worker.encryptThumbnail(file.thumbnail, fileKey);
            const { file: encryptedMetadata }: EncryptionResult =
                await worker.encryptMetadata(file.metadata, fileKey);

            const encryptedKey: B64EncryptionResult = await worker.encryptToB64(
                fileKey,
                encryptionKey,
            );

            const result: EncryptedFile = {
                file: {
                    file: encryptedFiledata,
                    thumbnail: encryptedThumbnail,
                    metadata: encryptedMetadata,
                    filename: file.metadata.title,
                },
                fileKey: encryptedKey,
            };
            return result;
        } catch (e) {
            logError(e, 'Error encrypting files');
            throw e;
        }
    }


    private async uploadToBucket(file: ProcessedFile): Promise<BackupedFile> {
        try {
            let fileObjectKey;
            if (isDataStream(file.file.encryptedData)) {
                const { chunkCount, stream } = file.file.encryptedData;
                const uploadPartCount = Math.ceil(
                    chunkCount / CHUNKS_COMBINED_FOR_UPLOAD,
                );
                const filePartUploadURLs = await NetworkClient.fetchMultipartUploadURLs(
                    uploadPartCount,
                );
                fileObjectKey = await NetworkClient.putFileInParts(
                    filePartUploadURLs,
                    stream,
                    file.filename,
                    uploadPartCount,
                    this.trackUploadProgress,
                );
            } else {
                const fileUploadURL = await this.getUploadURL();
                const progressTracker=this.trackUploadProgress.bind(this, file.filename);
                fileObjectKey = await NetworkClient.putFile(
                    fileUploadURL,
                    file.file.encryptedData,
                    progressTracker,
                );
            }
            const thumbnailUploadURL = await this.getUploadURL();
            const thumbnailObjectKey = await NetworkClient.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData as Uint8Array,
                ()=>null,
            );

            const backupedFile: BackupedFile = {
                file: {
                    decryptionHeader: file.file.decryptionHeader,
                    objectKey: fileObjectKey,
                },
                thumbnail: {
                    decryptionHeader: file.thumbnail.decryptionHeader,
                    objectKey: thumbnailObjectKey,
                },
                metadata: file.metadata,
            };
            return backupedFile;
        } catch (e) {
            logError(e, 'error uploading to bucket');
            throw e;
        }
    }

    private getUploadFile(
        collection: Collection,
        backupedFile: BackupedFile,
        fileKey: B64EncryptionResult,
    ): UploadFile {
        const uploadFile: UploadFile = {
            collectionID: collection.id,
            encryptedKey: fileKey.encryptedData,
            keyDecryptionNonce: fileKey.nonce,
            ...backupedFile,
        };
        uploadFile;
        return uploadFile;
    }


    private async getUploadURL() {
        if (this.uploadURLs.length === 0) {
            await NetworkClient.fetchUploadURLs(this.totalFileCount-this.filesCompleted, this.uploadURLs);
        }
        return this.uploadURLs.pop();
    }


    private trackUploadProgress(
        filename:string,
        percentPerPart = RANDOM_PERCENTAGE_PROGRESS_FOR_PUT(),
        index = 0,
    ) {
        const cancel={ exec: null };
        let timeout=null;
        const resetTimeout=()=>{
            if (timeout) {
                clearTimeout(timeout);
            }
            timeout=setTimeout(()=>cancel.exec(), 30*1000);
        };
        return {
            cancel,
            onUploadProgress: (event) => {
                filename &&
                    this.fileProgress.set(
                        filename,
                        Math.min(
                            Math.round(
                                percentPerPart * index +
                                (percentPerPart * event.loaded) /
                                event.total,
                            ),
                            98,
                        ),
                    );
                this.updateProgressBarUI();
                if (event.loaded===event.total) {
                    clearTimeout(timeout);
                } else {
                    resetTimeout();
                }
            },
        };
    }
}

export default new UploadService();
