import { fileAttribute, FILE_TYPE } from '../fileService';
import { Collection } from '../collectionService';
import { logError } from 'utils/sentry';
import UploadHttpClient from './uploadHttpClient';
import {
    extractMetadata,
    getMetadataMapKey,
    ParsedMetaDataJSON,
} from './metadataService';
import { generateThumbnail } from './thumbnailService';
import {
    getFileOriginalName,
    getFileData,
    getFileType,
    FileTypeInfo,
} from './readFileService';
import { encryptFiledata } from './encryptionService';
import { ENCRYPTION_CHUNK_SIZE } from 'types';
import { uploadStreamUsingMultipart } from './multiPartUploadService';
import UIService from './uiService';
import { parseError } from 'utils/common/errorUtil';
import { MetadataMap } from './uploadManager';
import { fileIsHEIC } from 'utils/file';

// this is the chunk size of the un-encrypted file which is read and encrypted before uploading it as a single part.
export const MULTIPART_PART_SIZE = 20 * 1024 * 1024;

export const FILE_READER_CHUNK_SIZE = ENCRYPTION_CHUNK_SIZE;

export const FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART = Math.floor(
    MULTIPART_PART_SIZE / FILE_READER_CHUNK_SIZE
);

export interface UploadURL {
    url: string;
    objectKey: string;
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
    hasStaticThumbnail: boolean;
}

export interface FileWithMetadata
    extends Omit<FileInMemory, 'hasStaticThumbnail'> {
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

export interface UploadFile extends BackupedFile {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

class UploadService {
    private uploadURLs: UploadURL[] = [];
    private metadataMap: Map<string, ParsedMetaDataJSON>;
    private pendingUploadCount: number = 0;

    async init(fileCount: number, metadataMap: MetadataMap) {
        this.pendingUploadCount = fileCount;
        this.metadataMap = metadataMap;
        await this.preFetchUploadURLs();
    }

    async readFile(
        worker: any,
        rawFile: globalThis.File,
        fileTypeInfo: FileTypeInfo
    ): Promise<FileInMemory> {
        const isHEIC = fileIsHEIC(fileTypeInfo.exactType);

        const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
            worker,
            rawFile,
            fileTypeInfo.fileType,
            isHEIC
        );

        const filedata = await getFileData(worker, rawFile);

        return {
            filedata,
            thumbnail,
            hasStaticThumbnail,
        };
    }

    async getFileMetadata(
        worker: any,
        rawFile: File,
        collection: { id: number }
    ): Promise<MetadataObject> {
        const fileTypeInfo = await getFileType(worker, rawFile);

        const originalName = getFileOriginalName(rawFile);
        const googleMetadata =
            this.metadataMap.get(
                getMetadataMapKey(collection.id, originalName)
            ) ?? {};
        const extractedMetadata: MetadataObject = await extractMetadata(
            worker,
            rawFile,
            fileTypeInfo
        );

        for (const [key, value] of Object.entries(googleMetadata)) {
            if (!value) {
                continue;
            }
            extractedMetadata[key] = value;
        }
        return extractedMetadata;
    }

    async encryptFile(
        worker: any,
        file: FileWithMetadata,
        encryptionKey: string
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
                encryptionKey
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

    async uploadToBucket(file: ProcessedFile): Promise<BackupedFile> {
        try {
            let fileObjectKey: string = null;
            if (isDataStream(file.file.encryptedData)) {
                fileObjectKey = await uploadStreamUsingMultipart(
                    file.filename,
                    file.file.encryptedData
                );
            } else {
                const progressTracker = UIService.trackUploadProgress(
                    file.filename
                );
                const fileUploadURL = await this.getUploadURL();
                fileObjectKey = await UploadHttpClient.putFile(
                    fileUploadURL,
                    file.file.encryptedData,
                    progressTracker
                );
            }
            const thumbnailUploadURL = await this.getUploadURL();
            const thumbnailObjectKey = await UploadHttpClient.putFile(
                thumbnailUploadURL,
                file.thumbnail.encryptedData as Uint8Array,
                null
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
        fileKey: B64EncryptionResult
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
        if (this.uploadURLs.length === 0 && this.pendingUploadCount) {
            await this.fetchUploadURLs();
        }
        return this.uploadURLs.pop();
    }

    public async preFetchUploadURLs() {
        try {
            await this.fetchUploadURLs();
            // checking for any subscription related errors
        } catch (e) {
            const { parsedError, parsed } = parseError(e);
            if (parsed) {
                throw parsedError;
            }
        }
    }

    private async fetchUploadURLs() {
        await UploadHttpClient.fetchUploadURLs(
            this.pendingUploadCount,
            this.uploadURLs
        );
    }
}

export default new UploadService();
