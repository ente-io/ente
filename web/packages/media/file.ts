import { sharedCryptoWorker } from "ente-base/crypto";
import { dateFromEpochMicroseconds } from "ente-base/date";
import log from "ente-base/log";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { type Metadata, ItemVisibility } from "./file-metadata";
import { FileType } from "./file-type";
import { RemoteMagicMetadata } from "./magic-metadata";

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
     * The same file (ID) may be associated with multiple collectionID, each of
     * which will come and stay as distinct {@link EnteFile} instances - all of
     * which will have the same {@link id} but distinct {@link collectionID}.
     *
     * So the ({@link id}, {@link collectionID}) pair is a primary key, not the
     * {@link id} on its own. See: [Note: Collection file].
     */
    collectionID: number;
    /**
     * The ID of the Ente user who owns the file.
     *
     * Files uploaded by non users on public links belong to the owner of the
     * collection who created the public link (See {@link uploaderName} in
     * {@link FilePublicMagicMetadataData}).
     */
    ownerID: number;
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    metadata: RemoteFileMetadata;
    /**
     * Static, remote visible, information associated with a file.
     *
     * This is information about storage used by the file and its thumbnail.
     * Unlike {@link metadata} which is E2EE, the {@link FileInfo} is remote
     * visible for bookkeeping purposes.
     *
     * Files uploaded by very old versions of Ente might not have this field.
     */
    info?: FileInfo;
    magicMetadata: EncryptedMagicMetadata;
    pubMagicMetadata: EncryptedMagicMetadata;
    /**
     * The file's encryption key (as a base64 string), encrypted by the key of
     * the collection to which it belongs.
     *
     * (note: This is always present. retaining this note until we remove
     * nullability uncertainty from the types).
     */
    encryptedKey: string;
    /**
     * The nonce (as a base64 string) that was used when encrypting the file's
     * encryption key.
     *
     * (note: This is always present. retaining this note until we remove
     * nullability uncertainty from the types).
     */
    keyDecryptionNonce: string;
    isDeleted: boolean;
    /**
     * The last time the file was updated (epoch microseconds).
     *
     * (e.g. magic metadata updates).
     */
    updationTime: number;
}

/**
 * A File.
 *
 * An EnteFile represents a file in Ente. It does not contain the actual data.
 *
 * It is named with an "Ente" prefix to disambiguate it from the web's native
 * {@link File} type.
 *
 * All files have an id (numeric) that is unique across all the files stored by
 * an Ente instance. Each file is also always associated with a collection, and
 * has an owner (both of these linkages are stored as the corresponding numeric
 * IDs within the EnteFile structure).
 *
 * > For shared files, the owner of the file is not necessarily the owner of all
 * > the collections to which the file belongs.
 *
 * While the file ID is unique, we'd can still have multiple entries for each
 * file ID in our local state, one for each {@link Collection} to which the file
 * belongs. That is, the uniqueness is across the (fileID, collectionID) pairs.
 * See [Note: Collection file].
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
    /**
     * The file's key.
     *
     * This is the base64 representation of the decrypted encryption key
     * associated with this file. When we get the file from remote (as a
     * {@link RemoteEnteFile}), the file key itself would have been encrypted by
     * the key of the {@link Collection} to which this file belongs.
     *
     * This key is used to encrypt both the file's contents, and any associated
     * data (e.g., metadatum, thumbnail) for the file.
     */
    key: string;
    /**
     * Public static metadata associated with a file.
     *
     * This is the immutable metadata that gets associated with a file when it
     * is uploaded, and there after cannot be changed.
     *
     * It is visible to all users with whom the file gets shared.
     *
     * > {@link pubMagicMetadata} contains fields that override fields present
     * > in the metadata. Clients overlay those atop the metadata fields, and
     * > thus they can be used to implement edits.
     *
     * See: [Note: Metadatum].
     */
    metadata: Metadata;
    /**
     * Private mutable metadata associated with the file that is only visible to
     * the owner of the file.
     *
     * See: [Note: Metadatum]
     */
    magicMetadata?: FileMagicMetadata;
    /**
     * Public mutable metadata associated with the file that is visible to all
     * users with whom the file has been shared.
     *
     * While in almost all cases, files will have associated public magic
     * metadata since newer clients have something or the other they need to add
     * to it, its presence is not guaranteed.
     *
     * See: [Note: Metadatum]
     */
    pubMagicMetadata?: FilePublicMagicMetadata;
    /**
     * `true` if this file is in trash (i.e. it has been deleted by the user,
     * and will be permanently deleted after 30 days of being moved to trash).
     */
    isTrashed?: boolean;
    /**
     * If {@link isTrashed} is `true`, then {@link deleteBy} contains the epoch
     * microseconds when this file will be permanently deleted.
     */
    deleteBy?: number;
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

const RemoteFileInfo = z.looseObject({
    fileSize: z.number(),
    thumbSize: z.number(),
});

const RemoteFileMetadata = z.object({
    /**
     * The metadata JSON object associated with the file, encrypted using the
     * file's key.
     *
     * Base64 encoded.
     */
    encryptedData: z.string(),
    /**
     * The base64 encoded decryption header that was used during encryption of
     * {@link encryptedData}.
     */
    decryptionHeader: z.string(),
});

export type RemoteFileMetadata = z.infer<typeof RemoteFileMetadata>;

/**
 * Zod schema for a {@link EnteFile} as represented in our interactions with
 * remote.
 *
 * The contents of the fields are encrypted by the file's key (which itself is
 * encrypted by the key of the collection that contains the file). EnteFile is
 * the decrypted local representation.
 *
 * See: [Note: Use looseObject when parsing JSON that will get persisted]
 */
// TODO(RE): Use me
export const RemoteEnteFile = z.looseObject({
    id: z.number(),
    collectionID: z.number(),
    ownerID: z.number(),
    /**
     * The file's key, encrypted using the key of the collection that contains
     * the file.
     *
     * Base64 encoded.
     */
    encryptedKey: z.string(),
    /**
     * The nonce to use when decrypting {@link encryptedKey}.
     *
     * Base64 encoded.
     */
    keyDecryptionNonce: z.string(),
    file: z.unknown(),
    thumbnail: z.unknown(),
    info: RemoteFileInfo.nullish().transform(nullToUndefined),
    updationTime: z.number(),
    /**
     * Tombstone marker.
     *
     * This is set to true in the diff response to indicate files which have
     * been deleted and should thus be pruned by the client locally.
     */
    isDeleted: z.boolean().nullish().transform(nullToUndefined),
    metadata: RemoteFileMetadata,
    magicMetadata: RemoteMagicMetadata.nullish().transform(nullToUndefined),
    pubMagicMetadata: RemoteMagicMetadata.nullish().transform(nullToUndefined),
    isTrashed: z.boolean().nullish().transform(nullToUndefined),
    deleteBy: z.number().nullish().transform(nullToUndefined),
});

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
export type FilePrivateMagicMetadata =
    MagicMetadataCore<FileMagicMetadataProps>;

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
        const fileKey = await worker.decryptBox(
            { encryptedData: encryptedKey, nonce: keyDecryptionNonce },
            collectionKey,
        );
        const fileMetadata = await worker.decryptMetadataJSON(
            metadata,
            fileKey,
        );

        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        /* eslint-disable @typescript-eslint/no-unnecessary-condition */
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                data: await worker.decryptMetadataJSON(
                    {
                        encryptedData: magicMetadata.data,
                        decryptionHeader: magicMetadata.header,
                    },
                    fileKey,
                ),
            };
        }
        /* eslint-disable @typescript-eslint/no-unnecessary-condition */
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                data: await worker.decryptMetadataJSON(
                    {
                        encryptedData: pubMagicMetadata.data,
                        decryptionHeader: pubMagicMetadata.header,
                    },
                    fileKey,
                ),
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
