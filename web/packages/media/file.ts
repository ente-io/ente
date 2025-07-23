import { decryptBox, decryptMetadataJSON } from "ente-base/crypto";
import log from "ente-base/log";
import { nullishToBlank, nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { ignore } from "./collection";
import {
    fileFileName,
    FileMetadata,
    FilePrivateMagicMetadataData,
    FilePublicMagicMetadataData,
} from "./file-metadata";
import { FileType } from "./file-type";
import {
    decryptMagicMetadata,
    RemoteMagicMetadata,
    type MagicMetadata,
} from "./magic-metadata";

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
 *
 * [Note: File lifecycle]
 *
 * 1. **Normal**: A file starts off by belonging to at least one collection. It
 *    can then be added to additional collections, each of which will be an
 *    EnteFile with a distinct (fileID, collectionID) pair.
 *
 * 2. **Trash**: If the user deletes the file, then the file moves to trash.
 *    Such files will have {@link isDeleted} `true` in their
 *    {@link RemoteEnteFile} entries when we perform a collection diff to let
 *    the client know that the corresponding file is no longer part of the
 *    collection.
 *
 *    Such files will now be returned as part of the trash diff, with both
 *    {@link isDeleted} and {@link isRestored} set to `false` for their trash
 *    entry.
 *
 * 3. **Restore**: If the the user were to restore the file before permanent
 *    deletion, then it effectively works as moving a normal file to an normal
 *    collection. In particular, if we were to restore the file back to one of
 *    the collections it was part of pre-trash, and then fetch the collection
 *    diff for that collection, we would get back the same file object, except
 *    with {@link isDeleted} will now be `false`.
 *
 *    The trash entry for restored files will have {@link isRestored} set to
 *    `true` to notify clients that an item that was previously in trash is no
 *    longer there because it has been restored.
 *
 * 4. **Permanent deletion**: If the file remains in trash for 30 days, or if
 *    the user explictly permanently deletes it from the trash, or if the user
 *    explicitly clears the trash, then it will get permanently deleted.
 *
 *    The trash entry for such permanently deleted files will have
 *    {@link isDeleted} set to `true` to notify clients that an item that was
 *    previously in trash is no longer there because it has been permanently
 *    deleted.
 *
 *    When a file is permanently deleted, remote will scrub off data from its
 *    fields. See: [Note: Optionality of remote file fields].
 */
export interface EnteFile {
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
     * Information pertaining to the encrypted S3 object that has the file's
     * contents.
     */
    file: FileObjectAttributes;
    /**
     * Information pertaining to the encrypted S3 object that has the contents
     * of the file's thumbnail.
     */
    thumbnail: FileObjectAttributes;
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
    /**
     * The last time the file was updated (epoch microseconds).
     *
     * (e.g. magic metadata updates).
     */
    updationTime: number;
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
    metadata: FileMetadata;
    /**
     * Private mutable metadata associated with the file that is only visible to
     * the owner of the file.
     *
     * See: [Note: Metadatum]
     */
    magicMetadata?: MagicMetadata<FilePrivateMagicMetadataData>;
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
    pubMagicMetadata?: MagicMetadata<FilePublicMagicMetadataData>;
}

/**
 * Attributes about an object related to an {@link EnteFile}.
 *
 * - The file's contents,
 *
 * - The file's thumbnail's contents.
 */
export interface FileObjectAttributes {
    /**
     * The decryption header that was used when encrypting the objects's
     * contents (with the file's key) before uploading them to S3 remote.
     */
    decryptionHeader: string;
}

export const RemoteFileObjectAttributes = z.looseObject({
    /**
     * The decryption header (base64 string) used when encrypting the object.
     *
     * For permanently deleted files, this will still be present, but remote may
     * scrub it to a blank string or a placeholder.
     */
    decryptionHeader: z.string(),
});

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

export const RemoteFileInfo = z.looseObject({
    fileSize: z.number(),
    thumbSize: z.number(),
});

const RemoteFileMetadata = z.object({
    /**
     * The metadata JSON object associated with the file, encrypted using the
     * file's key.
     *
     * Base64 encoded.
     *
     * There is one case when this will be not be present - for permanently
     * deleted files when we get them as part of a trash diff (see the longer
     * note about this below):
     *
     * [Note: Optionality of remote file fields]
     *
     * When a file is permanently deleted, remote will scrub off data from its
     * fields (either by nulling them outright, or inserting placeholders,
     * depending on the remote schema).
     *
     * So a {@link RemoteEnteFile} object present in the trash item of a
     * permanently deleted file in the trash diff response (i.e. a trash item
     * with {@link isDeleted} is set to `true`) may not have the fields which we
     * normally would expect to always be there for files.
     *
     * This is not a problem in code flow since the client will not even attempt
     * to decrypt or use such file entries, so the absence of these fields has
     * no impact. However, it does impact JSON validation, which might
     * preemptively (and unnecessarily) fail for such {@link RemoteEnteFile}s.
     *
     * Luckily, this is simple to handle since most of the data in a
     * {@link RemoteEnteFile} is already optional. The only tweak we require is
     * handling missing {@link encryptedData} of the {@link RemoteEnteFile}'s
     * {@link metadata} field in such cases. We could mark it as a optional too,
     * but since we anyways shouldn't be using this field, so for convenience of
     * the upstream types, we transform such missing values to a blank string.
     */
    encryptedData: z.string().nullish().transform(nullishToBlank),
    /**
     * The base64 encoded decryption header that was used during encryption of
     * {@link encryptedData}.
     *
     * For permanently deleted files, this will still be present, but remote may
     * scrub it to a blank string or a placeholder.
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
    file: RemoteFileObjectAttributes,
    thumbnail: RemoteFileObjectAttributes,
    info: RemoteFileInfo.nullish().transform(nullToUndefined),
    updationTime: z.number(),
    /**
     * Removal marker in diff responses.
     *
     * This is set to `true` in the collection diff response to indicate files
     * that are no longer part of the collection.
     *
     * - They may have been removed from the collection.
     *
     * - They have been deleted (either moved to trash, or permanently deleted).
     */
    isDeleted: z.boolean().nullish().transform(nullToUndefined),
    metadata: RemoteFileMetadata,
    magicMetadata: RemoteMagicMetadata.nullish().transform(nullToUndefined),
    pubMagicMetadata: RemoteMagicMetadata.nullish().transform(nullToUndefined),
});

export type RemoteEnteFile = z.infer<typeof RemoteEnteFile>;

/**
 * Zod schema for a response for various "/diff" APIs that return changes since
 * a provided timestamp.
 *
 * - "/collections/v2/diff"
 * - "/public-collection/diff"
 * - "/cast/diff"
 */
export const FileDiffResponse = z.object({
    /**
     * A batch of changes (upserts or deletions).
     *
     * See also: [Note: Diff response will have at most one entry for an id].
     */
    diff: RemoteEnteFile.array(),
    /**
     * If `true`, then there are more changes that can be fetched by doing
     * another of the same API call, this time passing it the latest from
     * amongst the timestamps of entries in {@link diff}.
     */
    hasMore: z.boolean(),
});

/**
 * Decrypt a remote file using the provided {@link collectionKey}.
 *
 * @param file The remote file to decrypt.
 *
 * @param collectionKey The base64 encoded key of the collection to which this
 * file belongs. It is needed to decrypt the file's key (which in turn is needed
 * to decrypt the file's contents and other encrypted fields).
 *
 * @returns A decrypted {@link EnteFile}.
 */
export const decryptRemoteFile = async (
    remoteFile: RemoteEnteFile,
    collectionKey: string,
): Promise<EnteFile> => {
    // RemoteEnteFile is a looseObject, and we want to retain that semantic for
    // the parsed EnteFile. Mention all fields that we want to explicitly drop
    // or transform, passthrough the rest unchanged in the return value.
    //
    // See: [Note: Use looseObject when parsing JSON that will get persisted].
    const {
        id,
        encryptedKey,
        keyDecryptionNonce,
        isDeleted,
        metadata: encryptedMetadata,
        magicMetadata: encryptedMagicMetadata,
        pubMagicMetadata: encryptedPubMagicMetadata,
        ...rest
    } = remoteFile;

    // This flag is relevant only in the diff response, where it indicates that
    // the file should be removed from the corresponding collection. We would've
    // already acted on that information, so drop it from our local state.
    ignore(isDeleted);

    const key = await decryptBox(
        { encryptedData: encryptedKey, nonce: keyDecryptionNonce },
        collectionKey,
    );

    const metadataJSON = await decryptMetadataJSON(encryptedMetadata, key);
    const metadata = FileMetadata.parse(
        transformDecryptedMetadataJSON(id, metadataJSON),
    );

    let magicMetadata: EnteFile["magicMetadata"];
    if (encryptedMagicMetadata) {
        const genericMM = await decryptMagicMetadata(
            encryptedMagicMetadata,
            key,
        );
        const data = FilePrivateMagicMetadataData.parse(genericMM.data);
        magicMetadata = { ...genericMM, data };
    }

    let pubMagicMetadata: EnteFile["pubMagicMetadata"];
    if (encryptedPubMagicMetadata) {
        const genericMM = await decryptMagicMetadata(
            encryptedPubMagicMetadata,
            key,
        );
        const data = FilePublicMagicMetadataData.parse(genericMM.data);
        pubMagicMetadata = { ...genericMM, data };
    }

    return { ...rest, id, key, metadata, magicMetadata, pubMagicMetadata };
};

/**
 * Apply some transforms to gracefully handle metadata from old clients.
 *
 * @param metadataJSON The decrypted and parsed metadata JSON. Since TypeScript
 * does not have a native JSON type, this is typed as an `unknown`.
 *
 * @returns A JSON object with any transformations applied, if needed.
 */
export const transformDecryptedMetadataJSON = (
    fileID: number,
    metadataJSON: unknown,
) => {
    // The file ID threshold is an arbitrary cutoff so that this graceful
    // handling does not mask new issues.
    if (fileID > 100000000) return metadataJSON;

    if (typeof metadataJSON != "object") return metadataJSON;
    if (!metadataJSON) return metadataJSON;

    // In very rare cases (have found only one so far, a very old file in
    // Vishnu's account, uploaded by an initial dev version of Ente) the photo
    // has no modification time. Gracefully handle such cases.
    if (
        !("modificationTime" in metadataJSON) ||
        !metadataJSON.modificationTime
    ) {
        if ("creationTime" in metadataJSON) {
            log.info(`Patching metadata modification time for file ${fileID}`);
            (metadataJSON as Record<string, unknown>).modificationTime =
                metadataJSON.creationTime;
        }
    }

    // In very rare cases (again, some files shared with Vishnu's account,
    // uploaded by dev builds) the photo might not have a file type. Gracefully
    // handle these too.
    if (
        !("fileType" in metadataJSON) ||
        typeof metadataJSON.fileType != "number"
    ) {
        log.info(`Patching metadata file type for file ${fileID}`);
        (metadataJSON as Record<string, unknown>).fileType = FileType.image;
    }

    return metadataJSON;
};

/**
 * A short identifier for a file in log messages.
 *
 * e.g. "file flower.png (827233681)"
 *
 * @returns a string to use as an identifier when logging information about the
 * given {@link file}. The returned string contains the file name (for ease of
 * debugging) and the file ID (for exactness).
 */
export const fileLogID = (file: EnteFile) =>
    `file ${fileFileName(file)} (${file.id})`;
