import { fileAttribute, FILE_TYPE } from 'services/fileService';
import { ENCRYPTION_CHUNK_SIZE } from 'types';

// this is the chunk size of the un-encrypted file which is read and encrypted before uploading it as a single part.
export const MULTIPART_PART_SIZE = 20 * 1024 * 1024;

export const FILE_READER_CHUNK_SIZE = ENCRYPTION_CHUNK_SIZE;

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
