import { FILE_TYPE } from 'constants/file';
import { UPLOAD_STAGES } from 'constants/upload';
import { Collection } from 'types/collection';
import { fileAttribute } from 'types/file';

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

export interface Metadata {
    title: string;
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
    fileType: FILE_TYPE;
    hasStaticThumbnail?: boolean;
}

export interface Location {
    latitude: number;
    longitude: number;
}

export interface ParsedMetadataJSON {
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
}

export interface MultipartUploadURLs {
    objectKey: string;
    partURLs: string[];
    completeURL: string;
}

export interface FileTypeInfo {
    fileType: FILE_TYPE;
    exactType: string;
}

export interface ProgressUpdater {
    setPercentComplete: React.Dispatch<React.SetStateAction<number>>;
    setFileCounter: React.Dispatch<
        React.SetStateAction<{
            finished: number;
            total: number;
        }>
    >;
    setUploadStage: React.Dispatch<React.SetStateAction<UPLOAD_STAGES>>;
    setFileProgress: React.Dispatch<React.SetStateAction<Map<string, number>>>;
    setUploadResult: React.Dispatch<React.SetStateAction<Map<string, number>>>;
}

export interface FileWithCollection {
    file: File;
    collectionID?: number;
    collection?: Collection;
}

export interface MetadataAndFileTypeInfo {
    metadata: Metadata;
    fileTypeInfo: FileTypeInfo;
}

export type MetadataAndFileTypeInfoMap = Map<string, MetadataAndFileTypeInfo>;
export type ParsedMetadataJSONMap = Map<string, ParsedMetadataJSON>;

export interface UploadURL {
    url: string;
    objectKey: string;
}

export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

export interface FileInMemory {
    filedata: Uint8Array | DataStream;
    thumbnail: Uint8Array;
    hasStaticThumbnail: boolean;
}

export interface FileWithMetadata
    extends Omit<FileInMemory, 'hasStaticThumbnail'> {
    metadata: Metadata;
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
