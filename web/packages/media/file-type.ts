export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    LIVE_PHOTO,
    OTHERS,
}

export interface FileTypeInfo {
    fileType: FILE_TYPE;
    exactType: string;
    mimeType?: string;
    imageType?: string;
    videoType?: string;
}

// list of format that were missed by type-detection for some files.
export const KnownFileTypeInfos: FileTypeInfo[] = [
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

export const KnownNonMediaFileExtensions = ["xmp", "html", "txt"];
