import { fileAttribute } from '../fileService';
import { Collection } from '../collectionService';
import { FILE_TYPE } from 'pages/gallery';
import { logError } from 'utils/sentry';
import NetworkClient from './networkClient';
import { extractMetatdata, ParsedMetaDataJSON } from './metadataService';
import { generateThumbnail } from './thumbnailService';
import {
    getFileType,
    getFileOriginalName,
    getFileData,
} from './readFileService';
import { encryptFiledata } from './encryptionService';
import { ENCRYPTION_CHUNK_SIZE } from 'types';
import { uploadStreamUsingMultipart } from './s3Service';

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();
export const MIN_STREAM_FILE_SIZE = 20 * 1024 * 1024;
export const CHUNKS_COMBINED_FOR_A_UPLOAD_PART = Math.floor(
    MIN_STREAM_FILE_SIZE / ENCRYPTION_CHUNK_SIZE,
);

export enum FileUploadResults {
    FAILED = -1,
    SKIPPED = -2,
    UNSUPPORTED = -3,
    BLOCKED = -4,
    UPLOADED = 100,
}

export interface UploadURL {
    url: string;
    objectKey: string;
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

export interface FileInMemory {
    filedata: Uint8Array | DataStream;
    thumbnail: Uint8Array;
    metadata: MetadataObject;
}

export interface EncryptedFile {
    file: ProcessedFile;
    fileKey: B64EncryptionResult;
}
export interface ProcessedFile {
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
    filename: string;
}
export interface BackupedFile extends Omit<ProcessedFile, 'filename'> {}

export type MetadataMap = Map<string, ParsedMetaDataJSON>;

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
    private uploadURLs: UploadURL[] = [];
    private pendingFilesUploads: number;
    private metadataMap: Map<string, ParsedMetaDataJSON>;

    async readFile(reader: FileReader, receivedFile: globalThis.File) {
        try {
            const fileType = getFileType(receivedFile);

            const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
                reader,
                receivedFile,
                fileType,
            );

            const originalName = getFileOriginalName(receivedFile);
            const googleMetadata = this.metadataMap.get(originalName);
            const extractedMetadata: MetadataObject = await extractMetatdata(
                reader,
                receivedFile,
                fileType,
            );
            if (hasStaticThumbnail) {
                extractedMetadata.hasStaticThumbnail = true;
            }
            const metadata: MetadataObject = {
                ...extractedMetadata,
                ...googleMetadata,
            };

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

    async encryptFile(
        worker: any,
        file: FileInMemory,
        encryptionKey: string,
    ): Promise<EncryptedFile> {
        try {
            const { key: fileKey, file: encryptedFiledata } =
                await encryptFiledata(worker, file.filedata);

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

    async uploadToBucket(
        file: ProcessedFile,
        trackUploadProgress,
    ): Promise<BackupedFile> {
        try {
            let fileObjectKey: string = null;
            if (isDataStream(file.file.encryptedData)) {
                const progressTracker = trackUploadProgress;
                fileObjectKey = await uploadStreamUsingMultipart(
                    file.filename,
                    file.file.encryptedData,
                    progressTracker,
                );
            } else {
                const progressTracker = trackUploadProgress.bind(
                    null,
                    file.filename,
                );
                const fileUploadURL = await this.getUploadURL();
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
                () => null,
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

    getUploadFile(
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
            await NetworkClient.fetchUploadURLs(
                this.pendingFilesUploads,
                this.uploadURLs,
            );
        }
        return this.uploadURLs.pop();
    }
}

export default new UploadService();
