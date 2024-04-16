import { FILE_TYPE } from "constants/file";
import { FileTypeInfo } from "types/upload";

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
];

export const KNOWN_NON_MEDIA_FORMATS = ["xmp", "html", "txt"];
