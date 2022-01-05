import { ENCRYPTION_CHUNK_SIZE } from 'constants/crypto';
import { FILE_TYPE } from 'constants/file';

// list of format that were missed by type-detection for some files.
export const FORMAT_MISSED_BY_FILE_TYPE_LIB = [
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpeg' },
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpg' },
    { fileType: FILE_TYPE.VIDEO, exactType: 'webm' },
];

// this is the chunk size of the un-encrypted file which is read and encrypted before uploading it as a single part.
export const MULTIPART_PART_SIZE = 20 * 1024 * 1024;

export const FILE_READER_CHUNK_SIZE = ENCRYPTION_CHUNK_SIZE;

export const FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART = Math.floor(
    MULTIPART_PART_SIZE / FILE_READER_CHUNK_SIZE
);

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();
