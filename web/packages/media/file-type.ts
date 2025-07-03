/**
 * The type of an {@link EnteFile}.
 *
 * This is an object containing symbolic constant. There is also an eraseable
 * TypeScript type type with the same name, {@link FileType}.
 */
export const FileType = {
    /**
     * An image (e.g. JPEG).
     */
    image: 0,
    /**
     * A video (e.g. MP4).
     */
    video: 1,
    /**
     * A live photo, aka motion photo.
     *
     * This is a combination of an image and a (short) video capturing the
     * before and after when the image was taken. We preserve it as a zip
     * containing both the parts.
     */
    livePhoto: 2,
} as const;

/**
 * The type of an {@link EnteFile}.
 *
 * This is an eraseable TypeScript type. There is also a {@link FileType} object
 * with the same name that contains the corresponding symbolic constants.
 */
export type FileType = (typeof FileType)[keyof typeof FileType];

export interface FileTypeInfo {
    fileType: FileType;
    /**
     * A lowercased, standardized extension for files of the current type.
     *
     * For live photos, this is set to the extension of the image component of
     * the live photo.
     */
    extension: string;
    mimeType?: string;
}

// list of format that were missed by type-detection for some files.
export const KnownFileTypeInfos: FileTypeInfo[] = [
    { fileType: FileType.image, extension: "jpeg", mimeType: "image/jpeg" },
    { fileType: FileType.image, extension: "jpg", mimeType: "image/jpeg" },
    { fileType: FileType.video, extension: "webm", mimeType: "video/webm" },
    { fileType: FileType.video, extension: "mod", mimeType: "video/mpeg" },
    { fileType: FileType.video, extension: "mp4", mimeType: "video/mp4" },
    { fileType: FileType.image, extension: "gif", mimeType: "image/gif" },
    { fileType: FileType.video, extension: "dv", mimeType: "video/x-dv" },
    { fileType: FileType.video, extension: "wmv", mimeType: "video/x-ms-asf" },
    { fileType: FileType.video, extension: "hevc", mimeType: "video/hevc" },
    {
        fileType: FileType.image,
        extension: "raf",
        mimeType: "image/x-fuji-raf",
    },
    {
        fileType: FileType.image,
        extension: "orf",
        mimeType: "image/x-olympus-orf",
    },
    {
        fileType: FileType.image,
        extension: "crw",
        mimeType: "image/x-canon-crw",
    },
    { fileType: FileType.video, extension: "mov", mimeType: "video/quicktime" },
];

export const KnownNonMediaFileExtensions = ["xmp", "html", "txt"];
