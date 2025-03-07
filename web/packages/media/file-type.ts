/** The type of an {@link EnteFile}. */
export enum FileType {
    /** An image (e.g. JPEG). */
    image = 0,
    /** A video (e.g. MP4). */
    video = 1,
    /**
     * A live photo, aka motion photo.
     *
     * This is a combination of an image and a (short) video capturing the
     * before and after when the image was taken. We preserve it as a zip
     * containing both the parts.
     */
    livePhoto = 2,
    /**
     * An unknown file type.
     *
     * The exact value here doesn't matter (and won't likely match what we get
     * from remote). This instead is serving as a placeholder, forcing us to
     * deal with the scenario that an EnteFile's type can be different from one
     * of the above.
     */
    other = 3,
}

export interface FileTypeInfo {
    fileType: FileType;
    /**
     * A lowercased, standardized extension for files of the current type.
     *
     * TODO(MR): This in not valid for live photos.
     */
    extension: string;
    mimeType?: string;
    imageType?: string;
    videoType?: string;
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
