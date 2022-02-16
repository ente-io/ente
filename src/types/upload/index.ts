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
    imageType?: string;
    videoType?: string;
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
    setFileProgress: React.Dispatch<React.SetStateAction<Map<number, number>>>;
    setUploadResult: React.Dispatch<React.SetStateAction<Map<number, number>>>;
    setFilenames: React.Dispatch<React.SetStateAction<Map<number, string>>>;
}

export interface UploadAsset {
    isLivePhoto?: boolean;
    file?: File;
    livePhotoAssets?: LivePhotoAssets;
}
export interface LivePhotoAssets {
    image: globalThis.File;
    video: globalThis.File;
}

export interface FileWithCollection extends UploadAsset {
    localID: number;
    collection?: Collection;
    collectionID?: number;
}
export interface MetadataAndFileTypeInfo {
    metadata: Metadata;
    fileTypeInfo: FileTypeInfo;
}

export type MetadataAndFileTypeInfoMap = Map<number, MetadataAndFileTypeInfo>;
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
    localID: number;
}

export interface EncryptedFile {
    file: ProcessedFile;
    fileKey: B64EncryptionResult;
}
export interface ProcessedFile {
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: fileAttribute;
    localID: number;
}
export interface BackupedFile extends Omit<ProcessedFile, 'localID'> {}

export interface UploadFile extends BackupedFile {
    collectionID: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}
