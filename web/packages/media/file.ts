import { sharedCryptoWorker } from "@/base/crypto";
import { dateFromEpochMicroseconds } from "@/base/date";
import log from "@/base/log";
import { type Metadata, ItemVisibility } from "./file-metadata";
import { FileType } from "./file-type";

// TODO: Audit this file.

export interface MetadataFileAttributes {
    encryptedData: string;
    decryptionHeader: string;
}

/**
 * Attributes about an object uploaded to S3.
 *
 * TODO: Split between fields needed during upload, and the fields we get back
 * from remote in the /diff response.
 */
export interface S3FileAttributes {
    /**
     * Upload only: This should be present during upload, but is not returned
     * back from remote in the /diff response.
     */
    objectKey: string;
    /**
     * Upload and diff: This is present both during upload and also returned by
     * remote in the /diff response.
     */
    decryptionHeader: string;
    /**
     * The size of the file, in bytes.
     *
     * For both file and thumbnails, the client also sends the size of the
     * encrypted file (as per the client) while creating a new object on remote.
     * This allows the server to validate that the size of the objects is same
     * as what client is reporting.
     *
     * Upload only: This should be present during upload, but is not returned
     * back from remote in the /diff response.
     */
    size: number;
}

/**
 * Static information associated with a file.
 */
export interface FileInfo {
    /**
     * The size of the file (in bytes).
     */
    fileSize: number;
    /**
     * The size of the thumbnail associated with the file (in bytes).
     */
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
    /**
     * The file's globally unique ID.
     *
     * The file's ID is a integer assigned by remote as the identifier for an
     * {@link EnteFile} when it is created. It is globally unique across all
     * files stored by an Ente instance, and is not scoped to the current user.
     */
    id: number;
    /**
     * The ID of the collection with which this file as associated.
     *
     * The same file (ID) may be associated with multiple collectionID, in which
     * case there will be multiple {@link EnteFile} entries for each
     * ({@link id}, {@link collectionID}) pair. See: [Note: Collection File].
     */
    collectionID: number;
    /**
     * The ID of the user who owns the file.
     */
    ownerID: number;
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    /**
     * Static metadata associated with a file.
     *
     * See: [Note: Metadatum].
     */
    metadata: MetadataFileAttributes;
    /**
     * Static, remote visible, information associated with a file.
     *
     * This is information about storage used by the file and its metadata (in
     * the future if needed). Unlike {@link metadata} which is E2EE, the
     * {@link FileInfo} is remote visible for bookkeeping purposes.
     *
     * Files uploaded by very old versions of Ente might not have this structure
     * present.
     */
    info: FileInfo | undefined;
    /**
     * Private mutable metadata associated with a file.
     *
     * See: [Note: Metadatum].
     */
    magicMetadata: EncryptedMagicMetadata;
    /**
     * Public mutable metadata associated with a file.
     *
     * See: [Note: Metadatum].
     */
    pubMagicMetadata: EncryptedMagicMetadata;
    /**
     * The file's encryption key (as a base64 string), encrypted by the key of
     * the collection to which it belongs.
     *
     * (note: This is always present. retaining this note until we remove
     * nullability uncertainity from the types).
     */
    encryptedKey: string;
    /**
     * The nonce (as a base64 string) that was used when encrypting the file's
     * encryption key.
     *
     * (note: This is always present. retaining this note until we remove
     * nullability uncertainity from the types).
     */
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
 *
 * While the file ID is unique, we'd can still have multiple entries for each
 * file ID in our local state, one per collection IDs to which the file belongs.
 * That is, the uniqueness is across the (fileID, collectionID) pairs. See
 * [Note: Collection File].
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
    /**
     * `true` if this file is in trash (i.e. it has been deleted by the user,
     * and will be permanently deleted after 30 days of being moved to trash).
     */
    isTrashed?: boolean;
    /**
     * If this is a file in trash, then {@link deleteBy} contains the epoch
     * microseconds when this file will be permanently deleted.
     */
    deleteBy?: number;
    /**
     * The base64 representation of the decrypted encryption key associated with
     * this file.
     *
     * This key is used to encrypt both the file's contents, and any associated
     * data (e.g., metadatum, thumbnail) for the file.
     */
    key: string;
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
    /** See {@link PublicMagicMetadata} in file-metadata.ts */
    dateTime?: string;
    /** See {@link PublicMagicMetadata} in file-metadata.ts */
    offsetTime?: string;
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
 * Return the date when the file will be deleted permanently. Only valid for
 * files that are in the user's trash.
 *
 * This is a convenience wrapper over the {@link deleteBy} property of a file,
 * converting that epoch microsecond value into a JavaScript date.
 */
export const enteFileDeletionDate = (file: EnteFile) =>
    dateFromEpochMicroseconds(file.deleteBy);

export async function decryptFile(
    file: EncryptedEnteFile,
    collectionKey: string,
): Promise<EnteFile> {
    try {
        const worker = await sharedCryptoWorker();
        const {
            encryptedKey,
            keyDecryptionNonce,
            metadata,
            magicMetadata,
            pubMagicMetadata,
            ...restFileProps
        } = file;
        const fileKey = await worker.decryptB64(
            encryptedKey,
            keyDecryptionNonce,
            collectionKey,
        );
        const fileMetadata = await worker.decryptMetadataJSON({
            encryptedDataB64: metadata.encryptedData,
            decryptionHeaderB64: metadata.decryptionHeader,
            keyB64: fileKey,
        });
        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        /* eslint-disable @typescript-eslint/no-unnecessary-condition */
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                data: await worker.decryptMetadataJSON({
                    encryptedDataB64: magicMetadata.data,
                    decryptionHeaderB64: magicMetadata.header,
                    keyB64: fileKey,
                }),
            };
        }
        /* eslint-disable @typescript-eslint/no-unnecessary-condition */
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                data: await worker.decryptMetadataJSON({
                    encryptedDataB64: pubMagicMetadata.data,
                    decryptionHeaderB64: pubMagicMetadata.header,
                    keyB64: fileKey,
                }),
            };
        }
        return {
            ...restFileProps,
            key: fileKey,
            // @ts-expect-error TODO: Need to use zod here.
            metadata: fileMetadata,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            magicMetadata: fileMagicMetadata,
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            pubMagicMetadata: filePubMagicMetadata,
        };
    } catch (e) {
        log.error("file decryption failed", e);
        throw e;
    }
}

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

    // In very rare cases (have found only one so far, a very old file in
    // Vishnu's account, uploaded by an initial dev version of Ente) the photo
    // has no modification time. Gracefully handle such cases.
    if (!file.metadata.modificationTime)
        file.metadata.modificationTime = file.metadata.creationTime;

    // In very rare cases (again, some files shared with Vishnu's account,
    // uploaded by dev builds) the photo might not have a file type. Gracefully
    // handle these too. The file ID threshold is an arbitrary cutoff so that
    // this graceful handling does not mask new issues.
    if (!file.metadata.fileType && file.id < 100000000)
        file.metadata.fileType = FileType.image;

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
