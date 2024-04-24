export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    LIVE_PHOTO,
    OTHERS,
}

export interface FileTypeInfo {
    fileType: FILE_TYPE;
    /**
     * A lowercased, standardized extension for files of the current type.
     *
     * TODO(MR): This in not valid for LIVE_PHOTO.
     *
     * See https://github.com/sindresorhus/file-type/blob/main/core.d.ts for the
     * full list of values this property can have.
     */
    extension: string;
    mimeType?: string;
    imageType?: string;
    videoType?: string;
}

// list of format that were missed by type-detection for some files.
export const KnownFileTypeInfos: FileTypeInfo[] = [
    { fileType: FILE_TYPE.IMAGE, extension: "jpeg", mimeType: "image/jpeg" },
    { fileType: FILE_TYPE.IMAGE, extension: "jpg", mimeType: "image/jpeg" },
    { fileType: FILE_TYPE.VIDEO, extension: "webm", mimeType: "video/webm" },
    { fileType: FILE_TYPE.VIDEO, extension: "mod", mimeType: "video/mpeg" },
    { fileType: FILE_TYPE.VIDEO, extension: "mp4", mimeType: "video/mp4" },
    { fileType: FILE_TYPE.IMAGE, extension: "gif", mimeType: "image/gif" },
    { fileType: FILE_TYPE.VIDEO, extension: "dv", mimeType: "video/x-dv" },
    {
        fileType: FILE_TYPE.VIDEO,
        extension: "wmv",
        mimeType: "video/x-ms-asf",
    },
    {
        fileType: FILE_TYPE.VIDEO,
        extension: "hevc",
        mimeType: "video/hevc",
    },
    {
        fileType: FILE_TYPE.IMAGE,
        extension: "raf",
        mimeType: "image/x-fuji-raf",
    },
    {
        fileType: FILE_TYPE.IMAGE,
        extension: "orf",
        mimeType: "image/x-olympus-orf",
    },

    {
        fileType: FILE_TYPE.IMAGE,
        extension: "crw",
        mimeType: "image/x-canon-crw",
    },
    {
        fileType: FILE_TYPE.VIDEO,
        extension: "mov",
        mimeType: "video/quicktime",
    },
];

export const KnownNonMediaFileExtensions = ["xmp", "html", "txt"];
