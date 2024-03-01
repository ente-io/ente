import { ENCRYPTION_CHUNK_SIZE } from "@ente/shared/crypto/constants";
import { FILE_TYPE } from "constants/file";
import {
    FileTypeInfo,
    ImportSuggestion,
    Location,
    ParsedExtractedMetadata,
} from "types/upload";

// list of format that were missed by type-detection for some files.
export const WHITELISTED_FILE_FORMATS: FileTypeInfo[] = [
    { fileType: FILE_TYPE.IMAGE, exactType: "jpeg", mimeType: "image/jpeg" },
    { fileType: FILE_TYPE.IMAGE, exactType: "jpg", mimeType: "image/jpeg" },
    { fileType: FILE_TYPE.VIDEO, exactType: "webm", mimeType: "video/webm" },
    { fileType: FILE_TYPE.VIDEO, exactType: "mod", mimeType: "video/mpeg" },
    { fileType: FILE_TYPE.VIDEO, exactType: "mp4", mimeType: "video/mp4" },
    { fileType: FILE_TYPE.IMAGE, exactType: "gif", mimeType: "image/gif" },
    { fileType: FILE_TYPE.VIDEO, exactType: "dv", mimeType: "video/x-dv" },
    {
        fileType: FILE_TYPE.VIDEO,
        exactType: "wmv",
        mimeType: "video/x-ms-asf",
    },
    {
        fileType: FILE_TYPE.VIDEO,
        exactType: "hevc",
        mimeType: "video/hevc",
    },
    {
        fileType: FILE_TYPE.IMAGE,
        exactType: "raf",
        mimeType: "image/x-fuji-raf",
    },
    {
        fileType: FILE_TYPE.IMAGE,
        exactType: "orf",
        mimeType: "image/x-olympus-orf",
    },

    {
        fileType: FILE_TYPE.IMAGE,
        exactType: "crw",
        mimeType: "image/x-canon-crw",
    },
    {
        fileType: FILE_TYPE.VIDEO,
        exactType: "mov",
        mimeType: "video/quicktime",
    },
];

export const KNOWN_NON_MEDIA_FORMATS = ["xmp", "html", "txt"];

export const EXIFLESS_FORMATS = ["gif", "bmp"];

// this is the chunk size of the un-encrypted file which is read and encrypted before uploading it as a single part.
export const MULTIPART_PART_SIZE = 20 * 1024 * 1024;

export const FILE_READER_CHUNK_SIZE = ENCRYPTION_CHUNK_SIZE;

export const FILE_CHUNKS_COMBINED_FOR_A_UPLOAD_PART = Math.floor(
    MULTIPART_PART_SIZE / FILE_READER_CHUNK_SIZE,
);

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();

export const NULL_LOCATION: Location = { latitude: null, longitude: null };

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    EXTRACTING_METADATA,
    UPLOADING,
    CANCELLING,
    FINISH,
}

export enum UPLOAD_STRATEGY {
    SINGLE_COLLECTION,
    COLLECTION_PER_FOLDER,
}

export enum UPLOAD_RESULT {
    FAILED,
    ALREADY_UPLOADED,
    UNSUPPORTED,
    BLOCKED,
    TOO_LARGE,
    LARGER_THAN_AVAILABLE_STORAGE,
    UPLOADED,
    UPLOADED_WITH_STATIC_THUMBNAIL,
    ADDED_SYMLINK,
}

export enum PICKED_UPLOAD_TYPE {
    FILES = "files",
    FOLDERS = "folders",
    ZIPS = "zips",
}

export const MAX_FILE_SIZE_SUPPORTED = 4 * 1024 * 1024 * 1024; // 4 GB

export const LIVE_PHOTO_ASSET_SIZE_LIMIT = 20 * 1024 * 1024; // 20MB

export const NULL_EXTRACTED_METADATA: ParsedExtractedMetadata = {
    location: NULL_LOCATION,
    creationTime: null,
    width: null,
    height: null,
};

export const A_SEC_IN_MICROSECONDS = 1e6;

export const DEFAULT_IMPORT_SUGGESTION: ImportSuggestion = {
    rootFolderName: "",
    hasNestedFolders: false,
    hasRootLevelFileWithFolder: false,
};

export const BLACK_THUMBNAIL_BASE64 =
    "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEB" +
    "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQ" +
    "EBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARC" +
    "ACWASwDAREAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUF" +
    "BAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk" +
    "6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztL" +
    "W2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAA" +
    "AAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVY" +
    "nLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImK" +
    "kpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oAD" +
    "AMBAAIRAxEAPwD/AD/6ACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKAC" +
    "gAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoA" +
    "KACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACg" +
    "AoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKA" +
    "CgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAK" +
    "ACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoA" +
    "KACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAo" +
    "AKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgD/9k=";
