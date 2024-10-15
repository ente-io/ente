import { type Metadata, ItemVisibility } from "./file-metadata";

// TODO: Audit this file.

export interface MetadataFileAttributes {
    encryptedData: string;
    decryptionHeader: string;
}

export interface S3FileAttributes {
    objectKey: string;
    decryptionHeader: string;
}

export interface FileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface MagicMetadataCore<T> {
    version: number;
    count: number;
    header: string;
    data: T;
}

export type EncryptedMagicMetadata = MagicMetadataCore<string>;

export interface EncryptedEnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    metadata: MetadataFileAttributes;
    info: FileInfo | undefined;
    magicMetadata: EncryptedMagicMetadata;
    pubMagicMetadata: EncryptedMagicMetadata;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
    updationTime: number;
}

/**
 * A File.
 *
 * An EnteFile represents a file in Ente. It does not contain the actual data.
 *
 * To disambiguate it from the web {@link File} type, we prefix it with Ente.
 *
 * All files have an id (numeric) that is unique across all the files stored by
 * an Ente instance. Each file is also always associated with a collection, and
 * has an owner (both of these linkages are stored as the corresponding numeric
 * IDs within the EnteFile structure).
 */
export interface EnteFile
    extends Omit<
        EncryptedEnteFile,
        | "metadata"
        | "pubMagicMetadata"
        | "magicMetadata"
        | "encryptedKey"
        | "keyDecryptionNonce"
    > {
    metadata: Metadata;
    magicMetadata: FileMagicMetadata;
    /**
     * The envelope containing the public magic metadata associated with this
     * file.
     *
     * In almost all cases, files will have associated public magic metadata
     * since newer clients have something or the other they need to add to it.
     * But its presence is not guaranteed.
     */
    pubMagicMetadata?: FilePublicMagicMetadata;
    isTrashed?: boolean;
    /**
     * The base64 encoded encryption key associated with this file.
     *
     * This key is used to encrypt both the file's contents, and any associated
     * data (e.g., metadatum, thumbnail) for the file.
     */
    key: string;
    src?: string;
    srcURLs?: SourceURLs;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    deleteBy?: number;
    isSourceLoaded?: boolean;
    conversionFailed?: boolean;
    isConverted?: boolean;
}

export interface LivePhotoSourceURL {
    image: () => Promise<string | undefined>;
    video: () => Promise<string | undefined>;
}

export interface LoadedLivePhotoSourceURL {
    image: string;
    video: string;
}

export interface SourceURLs {
    url: string | LivePhotoSourceURL | LoadedLivePhotoSourceURL;
    isOriginal: boolean;
    isRenderable: boolean;
    type: "normal" | "livePhoto";
    /**
     * Best effort attempt at obtaining the MIME type.
     *
     * Known cases where it is missing:
     *
     * - Live photos (these have a different code path for obtaining the URL).
     * - A video that is passes the isPlayable test in the browser.
     *
     */
    mimeType?: string;
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}

export interface FileWithUpdatedMagicMetadata {
    file: EnteFile;
    updatedMagicMetadata: FileMagicMetadata;
}

export interface FileWithUpdatedPublicMagicMetadata {
    file: EnteFile;
    updatedPublicMagicMetadata: FilePublicMagicMetadata;
}

export interface FileMagicMetadataProps {
    /**
     * The visibility of the file
     *
     * The file's visibility is user specific attribute, and thus we keep it in
     * the private magic metadata. This allows the file's owner to share a file
     * and edit its visibility without making revealing their visibility
     * preference to the people with whom they have shared the file.
     */
    visibility?: ItemVisibility;
    filePaths?: string[];
}

export type FileMagicMetadata = MagicMetadataCore<FileMagicMetadataProps>;

export interface FilePublicMagicMetadataProps {
    /**
     * Modified value of the date time associated with an {@link EnteFile}.
     *
     * Epoch microseconds.
     */
    editedTime?: number;
    /**
     * Edited name of the {@link EnteFile}.
     *
     * If the user edits the name of the file within Ente, then the edits are
     * saved in this field.
     */
    editedName?: string;
    /**
     * A arbitrary textual caption / description that the user has attached to
     * the {@link EnteFile}.
     */
    caption?: string;
    uploaderName?: string;
    /**
     * Width of the image / video, in pixels.
     */
    w?: number;
    /**
     * Height of the image / video, in pixels.
     */
    h?: number;
    /**
     * Edited latitude for the {@link EnteFile}.
     *
     * If the user edits the location (latitude and longitude) of a file within
     * Ente, then the edits will be stored as the {@link lat} and {@link long}
     * properties in the file's public magic metadata.
     */
    lat?: number;
    /**
     * Edited longitude for the {@link EnteFile}.
     *
     * See {@link long}.
     */
    long?: number;
}

export type FilePublicMagicMetadata =
    MagicMetadataCore<FilePublicMagicMetadataProps>;

export interface TrashItem extends Omit<EncryptedTrashItem, "file"> {
    file: EnteFile;
}

export interface EncryptedTrashItem {
    file: EncryptedEnteFile;
    isDeleted: boolean;
    isRestored: boolean;
    deleteBy: number;
    createdAt: number;
    updatedAt: number;
}

export type Trash = TrashItem[];

/**
 * @returns a string to use as an identifier when logging information about the
 * given {@link file}. The returned string contains the file name (for ease of
 * debugging) and the file ID (for exactness).
 */
export const fileLogID = (file: EnteFile) =>
    // TODO: Remove this when file/metadata types have optionality annotations.
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    `file ${file.metadata.title ?? "-"} (${file.id})`;

/**
 * Update the immutable fields of an (in-memory) {@link EnteFile} with any edits
 * that the user has made to their corresponding mutable metadata fields.
 *
 * This function updates a single file, see {@link mergeMetadata} for a
 * convenience function to run it on an array of files.
 *
 * [Note: File name for local EnteFile objects]
 *
 * The title property in a file's metadata is the original file's name. The
 * metadata of a file cannot be edited. So if later on the file's name is
 * changed, then the edit is stored in the `editedName` property of the public
 * metadata of the file.
 *
 * This function merges these edits onto the file object that we use locally.
 * Effectively, post this step, the file's metadata.title can be used in lieu of
 * its filename.
 */
export const mergeMetadata1 = (file: EnteFile): EnteFile => {
    const mutableMetadata = file.pubMagicMetadata?.data;
    if (mutableMetadata) {
        const { editedTime, editedName, lat, long } = mutableMetadata;
        if (editedTime) file.metadata.creationTime = editedTime;
        if (editedName) file.metadata.title = editedName;
        // Use (lat, long) only if both are present and nonzero.
        if (lat && long) {
            file.metadata.latitude = lat;
            file.metadata.longitude = long;
        }
    }

    // In a very rare cases (have found only one so far, a very old file in
    // Vishnu's account, uploaded by an initial dev version of Ente) the photo
    // has no modification time. Gracefully handle such cases.
    if (!file.metadata.modificationTime)
        file.metadata.modificationTime = file.metadata.creationTime;

    return file;
};

/**
 * Update the in-memory representation of an array of {@link EnteFile} to
 * reflect user edits since the file was uploaded.
 *
 * This is a list variant of {@link mergeMetadata1}.
 */
export const mergeMetadata = (files: EnteFile[]) =>
    files.map((file) => mergeMetadata1(file));

export const hasFileHash = (file: Metadata) =>
    !!file.hash || (!!file.imageHash && !!file.videoHash);
