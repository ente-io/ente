import { ENCRYPTION_CHUNK_SIZE } from 'constants/crypto';
import { FILE_TYPE } from 'constants/file';
import { Location, ParsedExtractedMetadata } from 'types/upload';

// list of format that were missed by type-detection for some files.
export const FORMAT_MISSED_BY_FILE_TYPE_LIB = [
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpeg', mimeType: 'image/jpeg' },
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpg', mimeType: 'image/jpeg' },
    { fileType: FILE_TYPE.VIDEO, exactType: 'webm', mimeType: 'video/webm' },
];

// this is the chunk size of the un-encrypted file which is read and encrypted before uploading it as a single part.
export const MULTIPART_PART_SIZE = 20 * 1024 * 1024;

export const FILE_READER_CHUNK_SIZE = ENCRYPTION_CHUNK_SIZE;

export const FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART = Math.floor(
    MULTIPART_PART_SIZE / FILE_READER_CHUNK_SIZE
);

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();

export const NULL_LOCATION: Location = { latitude: null, longitude: null };

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    EXTRACTING_METADATA,
    UPLOADING,
    FINISH,
}

export enum FileUploadResults {
    FAILED,
    ALREADY_UPLOADED,
    UNSUPPORTED,
    BLOCKED,
    TOO_LARGE,
    LARGER_THAN_AVAILABLE_STORAGE,
    UPLOADED,
}

export const MAX_FILE_SIZE_SUPPORTED = 5 * 1024 * 1024 * 1024; // 5 GB

export const MAX_NODE_SUPPORTED_FILE_SIZE = 2 * 1024 * 1024 * 1024; // 2 GB

export const LIVE_PHOTO_ASSET_SIZE_LIMIT = 20 * 1024 * 1024; // 20MB

export const NULL_EXTRACTED_METADATA: ParsedExtractedMetadata = {
    location: NULL_LOCATION,
    creationTime: null,
};

export const A_SEC_IN_MICROSECONDS = 1e6;
