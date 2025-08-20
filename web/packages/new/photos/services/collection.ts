import { ensureLocalUser } from "ente-accounts/services/user";
import { blobCache } from "ente-base/blob-cache";
import {
    boxSeal,
    boxSealOpen,
    decryptBox,
    encryptBox,
    generateKey,
} from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
import { groupFilesByCollectionID } from "ente-gallery/utils/file";
import {
    CollectionSubType,
    decryptRemoteCollection,
    RemoteCollection,
    RemotePublicURL,
    type Collection,
    type CollectionNewParticipantRole,
    type CollectionOrder,
    type CollectionPrivateMagicMetadataData,
    type CollectionPublicMagicMetadataData,
    type CollectionShareeMagicMetadataData,
    type CollectionType,
    type PublicURL,
} from "ente-media/collection";
import {
    decryptRemoteFile,
    FileDiffResponse,
    type EnteFile,
} from "ente-media/file";
import { ItemVisibility, metadataHash } from "ente-media/file-metadata";
import {
    createMagicMetadata,
    encryptMagicMetadata,
} from "ente-media/magic-metadata";
import { splitByPredicate } from "ente-utils/array";
import { z } from "zod/v4";
import { batched, type UpdateMagicMetadataRequest } from "./file";
import {
    removeCollectionIDLastSyncTime,
    saveCollectionFiles,
    saveCollectionLastSyncTime,
    saveCollections,
    saveCollectionsUpdationTime,
    savedCollectionFiles,
    savedCollectionLastSyncTime,
    savedCollections,
    savedCollectionsUpdationTime,
} from "./photos-fdb";
import { ensureUserKeyPair, getPublicKey } from "./user";

const uncategorizedCollectionName = "Uncategorized";
const defaultHiddenCollectionName = ".hidden";
export const defaultHiddenCollectionUserFacingName = "Hidden";
const favoritesCollectionName = "Favorites";

/**
 * Create a new album (a collection of type "album") on remote, and return its
 * local representation.
 *
 * Remote only, does not modify local state.
 *
 * @param albumName The name to use for the new album.
 */
export const createAlbum = (albumName: string) =>
    createCollection(albumName, "album");

/**
 * Create a new collection on remote, and return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * @param name The name of the new collection.
 *
 * @param type The type of the new collection.
 *
 * @param magicMetadataData Optional metadata to use as the collection's private
 * mutable metadata when creating the new collection.
 */
const createCollection = async (
    name: string,
    type: CollectionType,
    magicMetadataData?: CollectionPrivateMagicMetadataData,
): Promise<Collection> => {
    const collectionKey = await generateKey();
    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
        await encryptBox(collectionKey, await ensureMasterKeyFromSession());
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await encryptBox(new TextEncoder().encode(name), collectionKey);
    const magicMetadata = magicMetadataData
        ? await encryptMagicMetadata(
              createMagicMetadata(magicMetadataData),
              collectionKey,
          )
        : undefined;

    const remoteCollection = await postCollections({
        encryptedKey,
        keyDecryptionNonce,
        encryptedName,
        nameDecryptionNonce,
        type,
        ...(magicMetadata && { magicMetadata }),
    });

    return decryptRemoteKeyAndCollection(remoteCollection);
};

/**
 * Given a {@link RemoteCollection}, first obtain its decryption key, and then
 * use that to decrypt and return the collection itself.
 */
const decryptRemoteKeyAndCollection = async (collection: RemoteCollection) =>
    decryptRemoteCollection(collection, await decryptCollectionKey(collection));

/**
 * Return the decrypted collection key (as a base64 string) for the given
 * {@link RemoteCollection}.
 */
export const decryptCollectionKey = async (
    collection: RemoteCollection,
): Promise<string> => {
    const { owner, encryptedKey, keyDecryptionNonce } = collection;
    if (owner.id == ensureLocalUser().id) {
        // The collection key of collections owned by the user is encrypted with
        // the user's master key. The nonce will be present in such cases.
        return decryptBox(
            { encryptedData: encryptedKey, nonce: keyDecryptionNonce! },
            await ensureMasterKeyFromSession(),
        );
    } else {
        // The collection key of collections shared with the user is encrypted
        // with the user's public key.
        return boxSealOpen(encryptedKey, await ensureUserKeyPair());
    }
};

/**
 * Zod schema for a remote response containing a single collection.
 */
const CollectionResponse = z.object({ collection: RemoteCollection });

/**
 * Create a collection on remote with the provided data, and return the new
 * remote collection object returned by remote on success.
 */
const postCollections = async (
    collectionData: Partial<RemoteCollection>,
): Promise<RemoteCollection> => {
    const res = await fetch(await apiURL("/collections"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(collectionData),
    });
    ensureOk(res);
    return CollectionResponse.parse(await res.json()).collection;
};

/**
 * Fetch a collection from remote by its ID.
 *
 * Remote only, does not use or modify local state.
 *
 * This is not expected to be needed in the normal flow of things, since we
 * fetch collections en masse, and efficiently, using the collection diff
 * requests.
 *
 * @param collectionID The ID of the collection to fetch.
 *
 * @returns The collection obtained from remote after decrypting its contents.
 */
export const getCollectionByID = async (
    collectionID: number,
): Promise<Collection> => {
    const res = await fetch(await apiURL(`/collections/${collectionID}`), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const { collection } = CollectionResponse.parse(await res.json());
    return decryptRemoteKeyAndCollection(collection);
};

/**
 * Zod schema for a remote response containing a an array of collections.
 */
const CollectionsResponse = z.object({
    collections: z.array(RemoteCollection),
});

/**
 * An collection upsert or deletion obtained as a result of
 * {@link getCollections} invocation.
 *
 * Each change either contains the latest data associated with the collection
 * that has been created or updated, or has a flag set to indicate that the
 * corresponding collection has been deleted.
 */
export interface CollectionChange {
    /**
     * The ID of the collection.
     */
    id: number;
    /**
     * The added or updated collection, or `undefined` for deletions.
     *
     * - This will be set to the (decrypted) collection if it was added or
     *   updated on remote.
     *
     * - This will not be set if the corresponding collection was deleted on
     *   remote.
     */
    collection?: Collection;
    /**
     * Epoch microseconds denoting when this collection was last changed
     * (created or updated or deleted).
     */
    updationTime: number;
}

/**
 * Pull the latest collections from remote.
 *
 * This function uses a delta diff, pulling only changes since the timestamp
 * saved by the last pull.
 *
 * @returns the latest list of collections, reflecting both the state in our
 * local database and on remote.
 */
export const pullCollections = async (): Promise<Collection[]> => {
    const collections = await savedCollections();
    let sinceTime = (await savedCollectionsUpdationTime()) ?? 0;

    const changes = await getCollections(sinceTime);

    if (!changes.length) return collections;

    const collectionsByID = new Map(collections.map((c) => [c.id, c]));
    for (const { id, updationTime, collection } of changes) {
        sinceTime = Math.max(sinceTime, updationTime);
        if (collection) {
            collectionsByID.set(id, collection);
        } else {
            // Collection was deleted on remote.
            await removeCollectionIDLastSyncTime(id);
            collectionsByID.delete(id);
        }
    }

    const updatedCollections = [...collectionsByID.values()];

    await saveCollections(updatedCollections);
    await saveCollectionsUpdationTime(sinceTime);

    return updatedCollections;
};

/**
 * Fetch all collections that have been added or updated on remote since
 * {@link sinceTime}, with markers for those that have been deleted.
 *
 * @param sinceTime The {@link updationTime} of the latest collection that was
 * fetched in a previous set of changes. This allows us to resume fetching from
 * that point. Pass 0 to fetch from the beginning.
 *
 * @returns An array of {@link CollectionChange}s. It is guaranteed that there
 * will be at most one entry for a given collection in the result array. See:
 * [Note: Diff response will have at most one entry for an id]
 */
const getCollections = async (
    sinceTime: number,
): Promise<CollectionChange[]> => {
    const res = await fetch(await apiURL("/collections/v2", { sinceTime }), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const { collections } = CollectionsResponse.parse(await res.json());
    return Promise.all(
        collections.map(async (c) => ({
            id: c.id,
            updationTime: c.updationTime,
            collection: c.isDeleted
                ? undefined
                : await decryptRemoteKeyAndCollection(c),
        })),
    );
};

/**
 * Fetch all files from remote and update our local database.
 *
 * Each time it updates the local database, the {@link onSetCollectionFiles}
 * callback is also invoked to give the caller a chance to bring its own
 * in-memory state up to speed.
 *
 * @param collections The user's collections. These are assumed to be the latest
 * collections on remote (that is, the pull for collections should happen prior
 * to calling this function).
 *
 * @param onSetCollectionFiles An optional callback invoked when the locally
 * saved collection files were replaced by the provided {@link collectionFiles}.
 *
 * The callback is optional because we might be called in a context where we
 * just want to update the local database, and there is no other in-memory state
 * we need to keep in sync.
 *
 * The callback can be invoked multiple times for each pull (once for each batch
 * of changes received, for each collection that was updated).
 *
 * @returns true if one or more files were updated locally, false otherwise.
 */
export const pullCollectionFiles = async (
    collections: Collection[],
    onSetCollectionFiles: ((files: EnteFile[]) => void) | undefined,
) => {
    let didUpdateFiles = false;

    const savedFiles = await savedCollectionFiles();

    // Prune collections files for which we no longer have a collection.
    const collectionIDs = new Set(collections.map((c) => c.id));
    let files = savedFiles.filter((f) => collectionIDs.has(f.collectionID));

    // Update both the saved and in-memory files to reflect the pruning.
    if (files.length != savedFiles.length) {
        await saveCollectionFiles(files);
        onSetCollectionFiles?.(files);
        didUpdateFiles = true;
    }

    for (const collection of collections) {
        let sinceTime = (await savedCollectionLastSyncTime(collection)) ?? 0;
        if (sinceTime == collection.updationTime) {
            // The updationTime of a collection is guaranteed to be >= the
            // updationTime of any file in the collection.
            continue;
        }

        const [thisCollectionFiles, otherFiles] = splitByPredicate(
            files,
            (f) => f.collectionID == collection.id,
        );

        const thisCollectionFilesByID = new Map(
            thisCollectionFiles.map((f) => [f.id, f]),
        );

        while (true) {
            const { diff, hasMore } = await getCollectionDiff(
                collection.id,
                sinceTime,
            );
            if (!diff.length) break;

            for (const change of diff) {
                sinceTime = Math.max(sinceTime, change.updationTime);
                if (change.isDeleted) {
                    thisCollectionFilesByID.delete(change.id);
                } else {
                    const file = await decryptRemoteFile(
                        change,
                        collection.key,
                    );
                    await clearCachedThumbnailIfContentChanged(
                        thisCollectionFilesByID.get(change.id),
                        file,
                    );
                    thisCollectionFilesByID.set(change.id, file);
                }
            }

            files = otherFiles.concat([...thisCollectionFilesByID.values()]);

            await saveCollectionFiles(files);
            await saveCollectionLastSyncTime(collection, sinceTime);
            onSetCollectionFiles?.(files);
            didUpdateFiles = true;

            if (!hasMore) break;
        }

        // There might be a difference between the latest updation time of a
        // file in the collection, and the latest time of the collection itself,
        // if something about the collection itself changed, not the files in it
        // (e.g. if the collection was renamed).
        //
        // In such cases, advance the sync time to match the collection's update
        // time so we don't do an unnecessary collection diff the next time.
        await saveCollectionLastSyncTime(collection, collection.updationTime);
    }

    return didUpdateFiles;
};

/**
 * Fetch all files in the given collection have been created or updated since
 * {@link sinceTime}.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The ID of the collection whose updates we want to fetch.
 *
 * @param sinceTime The timestamp of most recently update for the collection
 * that we have already pulled. This serves both as a pagination mechanish, and
 * a way to fetch a delta diff the next time the client needs to pull changes
 * from remote.
 */
const getCollectionDiff = async (collectionID: number, sinceTime: number) => {
    const res = await fetch(
        await apiURL("/collections/v2/diff", { collectionID, sinceTime }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return FileDiffResponse.parse(await res.json());
};

/**
 * Clear cached thumbnail of an existing file if the thumbnail data has changed.
 *
 * This function in expected to be called when we are processing a collection
 * diff, updating our local state to reflect files that were updated on remote.
 * This is an opportune moment to invalidate any cached thumbnails for files
 * whose thumbnail content has changed.
 *
 * An example of when such invalidation is necessary:
 *
 * 1. Take a photo on mobile, and let it sync via the mobile app to us (web).
 * 2. Edit the photo outside of Ente (e.g. using Apple Photos).
 * 3. When the Ente mobile client next comes into foreground, it'll update the
 *    remote thumbnail for the existing file to reflect the changes.
 *
 * @param existingFile The {@link EnteFile} we had in our local database before
 * processing the diff response. Pass `undefined` to indicate that there was no
 * existing file corresponding to {@link updatedFile}; in such a case this
 * function is a no-op.
 *
 * @param updatedFile The update {@link EntneFile} (with the same file ID as the
 * {@link existingFile}) which we got in the diff response.
 */
const clearCachedThumbnailIfContentChanged = async (
    existingFile: EnteFile | undefined,
    updatedFile: EnteFile,
) => {
    if (!existingFile) return;

    // The hashes of the files differ, which indicates that the change was in
    // the file's contents, not the metadata itself, and thus we should refresh
    // the thumbnail.
    if (
        metadataHash(existingFile.metadata) !=
        metadataHash(updatedFile.metadata)
    ) {
        // This is an infrequent occurrence, so we lazily get the cache.
        const thumbnailCache = await blobCache("thumbs");
        await thumbnailCache.delete(updatedFile.id.toString());
    }
};

/**
 * Return all normal (non-hidden) collections that are present in our local
 * database.
 */
export const savedNormalCollections = (): Promise<Collection[]> =>
    savedCollections().then(
        (cs) => splitByPredicate(cs, isHiddenCollection)[1],
    );

/**
 * Return all hidden collections that are present in our local database.
 */
export const savedHiddenCollections = (): Promise<Collection[]> =>
    savedCollections().then(
        (cs) => splitByPredicate(cs, isHiddenCollection)[0],
    );

/**
 * Return a map of the (user-facing) collection name, indexed by collection ID.
 */
export const createCollectionNameByID = (collections: Collection[]) =>
    new Map(collections.map((c) => [c.id, collectionUserFacingName(c)]));

/**
 * Return the "user facing" name of the given collection.
 *
 * Usually this is the same as the collection name, but it might be a different
 * string for special collections like default hidden collections.
 */
export const collectionUserFacingName = (collection: Collection) =>
    isDefaultHiddenCollection(collection)
        ? defaultHiddenCollectionUserFacingName
        : collection.name;

/**
 * A CollectionFileItem represents a file in a API request to add, move or
 * restore files to a particular collection.
 */
interface CollectionFileItem {
    /**
     * The file's ID.
     */
    id: number;
    /**
     * The file's key (as a base64 string), encrypted with the key of the
     * collection to which it is being added or moved.
     */
    encryptedKey: string;
    /**
     * The nonce (as a base64 string) that was used during the encryption of
     * {@link encryptedKey}.
     */
    keyDecryptionNonce: string;
}

/**
 * Make a remote request to add the given {@link files} to the given
 * {@link collection}.
 *
 * Remote only, does not modify local state.
 */
export const addToCollection = async (
    collection: Collection,
    files: EnteFile[],
) =>
    batched(files, async (batchFiles) => {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/add-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    });

/**
 * Make a remote request to restore the given {@link files} to the given
 * {@link collection}.
 *
 * Remote only, does not modify local state.
 */
export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[],
) =>
    batched(files, async (batchFiles) => {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/restore-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    });

/**
 * Make a remote request to move the given {@link files} (which may be in
 * different collections) to the given {@link collection}.
 *
 * This is a higher level primitive than {@link moveFromCollection} that first
 * segregates the files into per-collection sets, and then performs
 * {@link moveFromCollection} for each such set.
 *
 * Remote only, does not modify local state.
 */
export const moveToCollection = async (
    collection: Collection,
    files: EnteFile[],
) =>
    Promise.all(
        groupFilesByCollectionID(files)
            .entries()
            .filter(([cid]) => cid != collection.id)
            .map(([cid, cf]) => moveFromCollection(cid, collection, cf)),
    );

/**
 * Make a remote request to move the given {@link files} from a collection (as
 * identified by its {@link fromCollectionID}) to the given
 * {@link toCollection}.
 *
 * Remote only, does not modify local state.
 */
export const moveFromCollection = async (
    fromCollectionID: number,
    toCollection: Collection,
    files: EnteFile[],
) =>
    batched(files, async (batchFiles) => {
        const encryptedFileKeys = await encryptWithCollectionKey(
            toCollection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/move-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    fromCollectionID: fromCollectionID,
                    toCollectionID: toCollection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    });

/**
 * Return an array of {@link CollectionFileItem}s, one for each file in
 * {@link files}, containing the corresponding file' ID and keys, but this time
 * encrypted using the key of the given {@link collection}.
 */
const encryptWithCollectionKey = async (
    collection: Collection,
    files: EnteFile[],
): Promise<CollectionFileItem[]> =>
    Promise.all(
        files.map(async (file) => {
            const box = await encryptBox(file.key, collection.key);
            return {
                id: file.id,
                encryptedKey: box.encryptedData,
                keyDecryptionNonce: box.nonce,
            };
        }),
    );

/**
 * Make a remote request to move the given {@link files} to trash.
 *
 * @param files The {@link EnteFile}s to move to trash. The API request needs
 * both a file ID and a collection ID, but there should be at most one entry for
 * a particular fileID in this array.
 *
 * Remote only, does not modify local state.
 */
export const moveToTrash = async (files: EnteFile[]) =>
    batched(files, async (batchFiles) =>
        ensureOk(
            await fetch(await apiURL("/files/trash"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    items: batchFiles.map((file) => ({
                        fileID: file.id,
                        collectionID: file.collectionID,
                    })),
                }),
            }),
        ),
    );

/**
 * Make a remote request to delete the given {@link fileIDs} from trash.
 *
 * Remote only, does not modify local state.
 */
export const deleteFromTrash = async (fileIDs: number[]) =>
    batched(fileIDs, async (batchIDs) =>
        ensureOk(
            await fetch(await apiURL("/trash/delete"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({ fileIDs: batchIDs }),
            }),
        ),
    );

/**
 * Remove the given files from the specified collection owned by the user.
 *
 * Reads local state but does not modify it. The effects are on remote.
 *
 * @param collection A collection (either owned by the user, or shared with the
 * user).
 *
 * @param files The files to remove from the collection. The files owned by the
 * user will be removed. If the collection is not owned by the user, then any
 * files that are not owned by the user will not be processed. In such cases,
 * this function will return a count less than the count of the provided files
 * (after having removed what can be removed).
 *
 * @returns The count of files that were processed. This can be less than the
 * count of the provided {@link files} if some files were not processed because
 * because they belong to other users (and {@link collection} also does not
 * belong to the current user).
 *
 * [Note: Removing files from a collection]
 *
 * There are three scenarios
 *
 *                             own file      shared file
 *     own collection             M               R
 *     others collection          R         not supported
 *
 *     M (move)   when both collection and file belongs to user
 *     R (remove) when only one of them belongs to the user
 *
 * The move operation is not supported across ownership boundaries. The remove
 * operation is only supported across ownership boundaries, but the user should
 * have ownership of either the file or collection (not both).
 *
 * In more detail, the above three scenarios can be described this way.
 *
 * 1. Move: If the user owns both the collection and the file they're trying to
 *    remove from the collection, then instead of a remove the client needs to
 *    move it to a different user owned collection in which it already exists
 *    (such a move acts as a remove). If it doesn't exist in any other user
 *    owned collection, then move it to the user's "Uncategorized" collection.
 *    The intent is that a "remove from collection" should not remove the last
 *    copy of a file (thus deleting it).
 *
 * 2. Remove: If the user does not own the file being removed, or owns the file
 *    being removed but does not own the collection from which it is being
 *    removed, they can remove it from the collection using the POST
 *    "/collections/v3/remove-files".
 *
 * 3. Not supported: Currently the possibility of removing a file the user does
 *    not own from a collection that the user does not own, even if they are a
 *    collaborator, is not supported.
 *
 * The "remove from collection" primitive is provided to the user both as a UI
 * action (on selecting files in a collection), and as an implicit action if the
 * user chooses the option to "keep files" when deleting a collection.
 *
 * This entire shebang is implemented by the following set of functions:
 *
 * 1. [Public] {@link removeFromCollection} - Handles both own and others
 *    collections by delegating to the one of the following functions.
 *
 * 2. [Public] {@link removeFromOwnCollection} - Handles both cases for own
 *    collections by delegating to either "Move" or "Remove"
 *
 * 3. [Private] {@link removeFromOthersCollection} - Handles both cases for
 *    other's collections by delegating to "Remove", then if needed, also
 *    throwing an error for the unsupported case.
 *
 * 4. [Private] {@link removeOwnFilesFromOwnCollection} implements the "Move".
 *
 * 5. [Private] {@link removeNonCollectionOwnerFiles} implements the "Remove".
 */
export const removeFromCollection = async (
    collection: Collection,
    files: EnteFile[],
): Promise<number> =>
    collection.owner.id == ensureLocalUser().id
        ? removeFromOwnCollection(collection.id, files)
        : removeFromOthersCollection(collection.id, files);

export const removeFromOwnCollection = async (
    collectionID: number,
    files: EnteFile[],
) => {
    const userID = ensureLocalUser().id;
    const [userFiles, nonUserFiles] = splitByPredicate(
        files,
        (f) => f.ownerID == userID,
    );
    if (userFiles.length) {
        await removeOwnFilesFromOwnCollection(collectionID, userFiles);
    }
    if (nonUserFiles.length) {
        await removeNonCollectionOwnerFiles(collectionID, nonUserFiles);
    }
    return files.length;
};

const removeFromOthersCollection = async (
    collectionID: number,
    files: EnteFile[],
) => {
    const userID = ensureLocalUser().id;
    const [userFiles] = splitByPredicate(files, (f) => f.ownerID == userID);
    if (userFiles.length) {
        await removeNonCollectionOwnerFiles(collectionID, userFiles);
    }
    return userFiles.length;
};

/**
 * Remove the given user owned files from the given collection also owned by the
 * user, ensuring that at least one user owned instance is retained for them
 * (either in a different user owned collection in which they already existed,
 * or in the user's "Uncategorized" collection as a fallback).
 *
 * Reads local state but does not modify it. The effects are on remote.
 *
 * This is used as a subroutine of [Note: Removing files from a collection].
 */
const removeOwnFilesFromOwnCollection = async (
    collectionID: number,
    filesToRemove: EnteFile[],
) => {
    const userID = ensureLocalUser().id;
    const collections = await savedCollections();
    const collectionFiles = await savedCollectionFiles();

    const collectionsByID = new Map(collections.map((c) => [c.id, c]));

    // This set keeps a running track of file IDs that still need to be removed.
    // It is seeded with the original set of files we were asked to remove.
    const filesToRemoveIDs = new Set(filesToRemove.map((f) => f.id));
    // A predicate that checks if the given file is still pending removal.
    const pendingRemove = (f: EnteFile) => filesToRemoveIDs.has(f.id);

    const collectionFilesToRemove = collectionFiles.filter(pendingRemove);
    const groups = groupFilesByCollectionID(collectionFilesToRemove);
    for (const [targetCollectionID, filesInCollection] of groups.entries()) {
        // Ignore the source collection itself.
        if (targetCollectionID == collectionID) continue;

        const targetCollection = collectionsByID.get(targetCollectionID)!;
        // We want a copy to exist in at least one other user owned collection.
        if (targetCollection.owner.id != userID) continue;
        // We'll move to uncategorized after the loop (if they still remain).
        if (targetCollection.type == "uncategorized") continue;

        const filesInCollectionToRemove =
            filesInCollection.filter(pendingRemove);
        if (!filesInCollectionToRemove.length) continue;

        // The file already exists in the target collection, but this acts as
        // "remove" from the source.
        await moveFromCollection(
            collectionID,
            targetCollection,
            filesInCollectionToRemove,
        );

        // Mark the files we just moved as been taken care of.
        filesInCollectionToRemove.forEach((f) => filesToRemoveIDs.delete(f.id));
    }

    // Any files that were not moved so far, move them to uncategorized,
    // creating uncategorized if needed.
    const remainingFiles = filesToRemove.filter(pendingRemove);
    if (remainingFiles.length) {
        const uncategorizedCollection =
            collections.find((c) => c.type == "uncategorized") ??
            (await createUncategorizedCollection());

        await moveFromCollection(
            collectionID,
            uncategorizedCollection,
            remainingFiles,
        );
    }
};

/**
 * Remove the provided files from the provided collection on remote.
 *
 * Only files which do not belong to the collection owner can be removed from
 * the collection using this endpoint. That is,
 *
 * - Either the user owns the collection and the all files being removed are
 *   owned by somebody else, or
 *
 * - The user owns all the files being removed, but the collection belongs to
 *   somebody else.
 *
 * If the collection owner wants to remove files owned by them, then their
 * client should first move those files first to other collections owned by the
 * collection owner.
 *
 * Remote only, does not modify local state.
 *
 * See also: [Note: Removing files from a collection].
 *
 * @param collectionID The ID of collection from which to remove the files.
 *
 * @param files A list of files which do not belong to the user, and which we
 * the user wants to remove from the given collection.
 */
const removeNonCollectionOwnerFiles = async (
    collectionID: number,
    files: EnteFile[],
) =>
    batched(files, async (batchFiles) =>
        ensureOk(
            await fetch(await apiURL("/collections/v3/remove-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID,
                    fileIDs: batchFiles.map((f) => f.id),
                }),
            }),
        ),
    );

/**
 * Delete a collection on remote.
 *
 * Reads local state but does not modify it. The effects are on remote.
 *
 * @param collectionID The ID of the collection to delete.
 *
 * @param opts Deletion options. In particular, if {@link keepFiles} is true,
 *  then the any of the user's files that only exist in this collection are
 *  first moved to another one of the user's collection (or Uncategorized if no
 *  such collection exists) before deleting the collection.
 *
 * See: [Note: Removing files from a collection]
 */
export const deleteCollection = async (
    collectionID: number,
    opts?: { keepFiles?: boolean },
) => {
    const keepFiles = opts?.keepFiles ?? false;

    if (keepFiles) {
        const collectionFiles = await savedCollectionFiles();
        await removeFromOwnCollection(
            collectionID,
            collectionFiles.filter((f) => f.collectionID == collectionID),
        );
    }

    ensureOk(
        await fetch(
            await apiURL(`/collections/v3/${collectionID}`, {
                collectionID,
                keepFiles,
            }),
            { method: "DELETE", headers: await authenticatedRequestHeaders() },
        ),
    );
};

/**
 * Rename a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The collection to rename.
 *
 * @param newName The new name of the collection
 */
export const renameCollection = async (
    collection: Collection,
    newName: string,
) => {
    if (collection.magicMetadata?.data.subType == CollectionSubType.quicklink) {
        // Convert quicklinks to a regular collection before giving them a name.
        await updateCollectionPrivateMagicMetadata(collection, {
            subType: CollectionSubType.default,
        });
    }
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await encryptBox(new TextEncoder().encode(newName), collection.key);
    await postCollectionsRename({
        collectionID: collection.id,
        encryptedName,
        nameDecryptionNonce,
    });
};

interface RenameRequest {
    collectionID: number;
    encryptedName: string;
    nameDecryptionNonce: string;
}

const postCollectionsRename = async (renameRequest: RenameRequest) =>
    ensureOk(
        await fetch(await apiURL("/collections/rename"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(renameRequest),
        }),
    );

/**
 * Change the visibility (normal, archived, hidden) of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This function works with both collections owned by the user, and collections
 * shared with the user.
 *
 * @param collection The collection whose visibility we want to change.
 *
 * @param visibility The new visibility (normal, archived, hidden).
 */
export const updateCollectionVisibility = async (
    collection: Collection,
    visibility: ItemVisibility,
) =>
    collection.owner.id == ensureLocalUser().id
        ? updateCollectionPrivateMagicMetadata(collection, { visibility })
        : updateCollectionShareeMagicMetadata(collection, { visibility });

/**
 * Change the pinned state of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This function works only for collections owned by the user.
 *
 * @param collection The collection whose order we want to change.
 *
 * @param order Whether on not the collection is pinned.
 */
export const updateCollectionOrder = async (
    collection: Collection,
    order: CollectionOrder,
) => updateCollectionPrivateMagicMetadata(collection, { order });

/**
 * Change the sort order of the files with a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This function works only for collections owned by the user.
 *
 * @param collection The collection whose file sort order we want to change.
 *
 * @param asc If true, then the files are sorted ascending (oldest first).
 * Otherwise they are sorted descending (newest first).
 */
export const updateCollectionSortOrder = async (
    collection: Collection,
    asc: boolean,
) => updateCollectionPublicMagicMetadata(collection, { asc });

/**
 * Update the private magic metadata of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The collection whose magic metadata we want to update.
 *
 * The existing magic metadata of this collection is used both to obtain the
 * current magic metadata version, and the existing contents on top of which the
 * updates are applied, so it is imperative that both these values are up to
 * sync with remote otherwise the update will fail.
 *
 * @param updates A non-empty subset of
 * {@link CollectionPrivateMagicMetadataData} entries.
 *
 * See: [Note: Magic metadata data cannot have nullish values]
 */
const updateCollectionPrivateMagicMetadata = async (
    { id, key, magicMetadata }: Collection,
    updates: CollectionPrivateMagicMetadataData,
) =>
    putCollectionsMagicMetadata({
        id,
        magicMetadata: await encryptMagicMetadata(
            createMagicMetadata(
                { ...magicMetadata?.data, ...updates },
                magicMetadata?.version,
            ),
            key,
        ),
    });

/**
 * Update the private magic metadata of a single collection on remote.
 */
const putCollectionsMagicMetadata = async (
    updateRequest: UpdateMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/collections/magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Update the public magic metadata of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This is a variant of {@link updateCollectionPrivateMagicMetadata} that works
 * with the {@link pubMagicMetadata} of a collection.
 */
const updateCollectionPublicMagicMetadata = async (
    { id, key, pubMagicMetadata }: Collection,
    updates: CollectionPublicMagicMetadataData,
) =>
    putCollectionsPublicMagicMetadata({
        id,
        magicMetadata: await encryptMagicMetadata(
            createMagicMetadata(
                { ...pubMagicMetadata?.data, ...updates },
                pubMagicMetadata?.version,
            ),
            key,
        ),
    });

/**
 * Update the public magic metadata of a single collection on remote.
 */
const putCollectionsPublicMagicMetadata = async (
    updateRequest: UpdateMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/collections/public-magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Update the per-sharee magic metadata of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This is a variant of {@link updateCollectionPrivateMagicMetadata} that works
 * with the {@link sharedMagicMetadata} of a collection.
 */
const updateCollectionShareeMagicMetadata = async (
    { id, key, sharedMagicMetadata }: Collection,
    updates: CollectionShareeMagicMetadataData,
) =>
    putCollectionsShareeMagicMetadata({
        id,
        magicMetadata: await encryptMagicMetadata(
            createMagicMetadata(
                { ...sharedMagicMetadata?.data, ...updates },
                sharedMagicMetadata?.version,
            ),
            key,
        ),
    });

/**
 * Update the sharee magic metadata of a single shared collection on remote.
 */
const putCollectionsShareeMagicMetadata = async (
    updateRequest: UpdateMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/collections/sharee-magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Create a new collection of type "favorites" for the user on remote, and
 * return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * Each user can have at most one collection of type "favorites" owned by them.
 * While this function does not enforce the constraint locally, it will fail
 * because remote will enforce the constraint and fail the request when we
 * attempt to create a second collection of type "favorites".
 */
const createFavoritesCollection = () =>
    createCollection(favoritesCollectionName, "favorites");

/**
 * Create a new collection of type "uncategorized" for the user on remote, and
 * return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * Each user can have at most one collection of type "uncategorized" owned by
 * them. While this function does not enforce the constraint locally, it will
 * fail because remote will enforce the constraint and fail the request when we
 * attempt to create a second collection of type "uncategorized".
 */
export const createUncategorizedCollection = () =>
    createCollection(uncategorizedCollectionName, "uncategorized");

/**
 * Return the user's own favorites collection if one is found in the local
 * database. Otherwise create a new one and return that.
 *
 * Reads local state but does not modify it. The effects are on remote.
 */
const savedOrCreateUserFavoritesCollection = async () =>
    (await savedUserFavoritesCollection()) ?? createFavoritesCollection();

/**
 * Return the user's own favorites collection, if any, present in the local
 * database.
 */
export const savedUserFavoritesCollection = async () => {
    const userID = ensureLocalUser().id;
    const collections = await savedCollections();
    return collections.find(
        (collection) =>
            // See: [Note: User and shared favorites]
            collection.type == "favorites" && collection.owner.id == userID,
    );
};

/**
 * Mark the provided {@link files} as the user's favorites by adding them to the
 * user's favorites collection.
 *
 * If the user doesn't yet have a favorites collection, it is created.
 *
 * Reads local state but does not modify it. The effects are on remote.
 */
export const addToFavoritesCollection = async (files: EnteFile[]) =>
    addToCollection(await savedOrCreateUserFavoritesCollection(), files);

export const removeFromFavoritesCollection = async (files: EnteFile[]) =>
    // Non-null assertion because if we get here and a favorites collection does
    // not already exist, then something is wrong.
    removeFromOwnCollection((await savedUserFavoritesCollection())!.id, files);

/**
 * Return the default hidden collection for the user if one is found in the
 * local database. Otherwise create a new one and return that.
 *
 * Reads local state but does not modify it. The effects are on remote.
 */
const savedOrCreateDefaultHiddenCollection = async () =>
    (await savedDefaultHiddenCollection()) ?? createDefaultHiddenCollection();

/**
 * Return the user's default hidden collection, if any, present in the
 * local database.
 */
const savedDefaultHiddenCollection = async () =>
    (await savedCollections()).find((collection) =>
        isDefaultHiddenCollection(collection),
    );

/**
 * Create a new collection with hidden visibility on remote, marking it as the
 * default hidden collection, and return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
const createDefaultHiddenCollection = () =>
    createCollection(defaultHiddenCollectionName, "album", {
        subType: CollectionSubType.defaultHidden,
        visibility: ItemVisibility.hidden,
    });

/**
 * Return true if the provided collection is the default hidden collection.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
export const isDefaultHiddenCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType == CollectionSubType.defaultHidden;

/**
 * Extract the IDs of all the "default" hidden collections.
 *
 * [Note: Multiple "default" hidden collections].
 *
 * Normally, there is only expected to be one such collection. But to provide
 * clients laxity in synchronization, we don't enforce this and instead allow
 * for multiple such default hidden collections to exist.
 */
export const findDefaultHiddenCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isDefaultHiddenCollection)
            .map((collection) => collection.id),
    );

/**
 * Return `true` if the given collection is hidden.
 *
 * Hidden collections are those that have their visibility set to hidden in the
 * collection's owner's private magic metadata.
 */
export const isHiddenCollection = (collection: Collection) =>
    collection.magicMetadata?.data.visibility == ItemVisibility.hidden;

/**
 * Return `true` if the given collection is archived.
 *
 * Archived collections are those that have their visibility set to hidden in the
 * collection's private magic metadata or per-sharee private metadata.
 */
export const isArchivedCollection = (collection: Collection) =>
    collection.magicMetadata?.data.visibility == ItemVisibility.archived ||
    collection.sharedMagicMetadata?.data.visibility == ItemVisibility.archived;

/**
 * Hide the provided {@link files} by moving them to the default hidden
 * collection.
 *
 * If the default hidden collection does not already exist, it is created.
 *
 * Reads local state but does not modify it. The effects are on remote.
 */
export const hideFiles = async (files: EnteFile[]) =>
    moveToCollection(await savedOrCreateDefaultHiddenCollection(), files);

/**
 * Share the provided collection with another Ente user.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The {@link Collection} to share.
 *
 * @param withUserEmail The email of the Ente user with whom to share it.
 *
 * @param role The desired role for the new participant.
 */
export const shareCollection = async (
    collection: Collection,
    withUserEmail: string,
    role: CollectionNewParticipantRole,
) => {
    const publicKey = await getPublicKey(withUserEmail);
    const encryptedKey = await boxSeal(collection.key, publicKey);

    ensureOk(
        await fetch(await apiURL("/collections/share"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({
                collectionID: collection.id,
                email: withUserEmail,
                role,
                encryptedKey,
            }),
        }),
    );
};

/**
 * Stop sharing a collection on remote with the given user.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection to stop sharing with the user
 * having the given {@link email}.
 *
 * @param email The email of the Ente user with whom to stop sharing.
 */
export const unshareCollection = async (collectionID: number, email: string) =>
    ensureOk(
        await fetch(await apiURL("/collections/unshare"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ collectionID, email }),
        }),
    );

/**
 * The subset of public URL attributes that can be customized by the user when
 * creating a link.
 */
export type CreatePublicURLAttributes = Pick<
    Partial<PublicURL>,
    "enableCollect" | "enableJoin" | "validTill" | "deviceLimit"
>;

/**
 * Create a new public link for the given collection.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection for which the public link should
 * be created.
 *
 * @param attributes Optional attributes to set when creating the public link.
 */
export const createPublicURL = async (
    collectionID: number,
    attributes?: CreatePublicURLAttributes,
): Promise<PublicURL> => {
    const res = await fetch(await apiURL("/collections/share-url"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({ collectionID, ...attributes }),
    });
    ensureOk(res);
    return z.object({ result: RemotePublicURL }).parse(await res.json()).result;
};

/**
 * The subset of public URL attributes that can be updated by the user after the
 * link has already been created.
 */
export type UpdatePublicURLAttributes = Omit<
    Partial<PublicURL>,
    "url" | "enablePassword"
> & { disablePassword?: boolean; passHash?: string };

/**
 * Update the attributes of an existing public link for a shared collection.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection whose public link to update.
 *
 * @param updates The public link attributes to modify. Only attributes
 * corresponding to entries with non nullish values will be updated, all the
 * other existing attributes will remain unmodified.
 *
 * @returns the updated public URL.
 */
export const updatePublicURL = async (
    collectionID: number,
    updates: UpdatePublicURLAttributes,
): Promise<PublicURL> => {
    const res = await fetch(await apiURL("/collections/share-url"), {
        method: "PUT",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({ collectionID, ...updates }),
    });
    ensureOk(res);
    return z.object({ result: RemotePublicURL }).parse(await res.json()).result;
};

/**
 * Delete the public link for the collection with given {@link collectionID}.
 *
 * Remote only, does not modify local state.
 */
export const deleteShareURL = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/share-url/${collectionID}`), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        }),
    );

/**
 * Leave a collection which had previously been shared with the user.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the shared collection to leave.
 */
export const leaveSharedCollection = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/leave/${collectionID}`), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );
