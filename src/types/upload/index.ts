import { FILE_TYPE } from 'constants/file';
import { fileAttribute } from 'types/file';

export interface DataStream {
    stream: ReadableStream<Uint8Array>;
    chunkCount: number;
}

export interface EncryptionResult {
    file: fileAttribute;
    key: string;
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
