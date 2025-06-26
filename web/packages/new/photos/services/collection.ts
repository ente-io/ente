import { ensureLocalUser, type User } from "ente-accounts/services/user";
import { blobCache } from "ente-base/blob-cache";
import {
    boxSeal,
    boxSealOpen,
    decryptBox,
    encryptBox,
    generateKey,
} from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
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
    type RemoteEnteFile,
} from "ente-media/file";
import { ItemVisibility, metadataHash } from "ente-media/file-metadata";
import {
    createMagicMetadata,
    encryptMagicMetadata,
} from "ente-media/magic-metadata";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import { batch, splitByPredicate } from "ente-utils/array";
import { z } from "zod/v4";
import { requestBatchSize, type UpdateMagicMetadataRequest } from "./file";
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
    const res = await fetch(
        await apiURL("/collections/v2", { sinceTime: sinceTime.toString() }),
        { headers: await authenticatedRequestHeaders() },
    );
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

export function getLatestVersionFiles(files: EnteFile[]) {
    const latestVersionFiles = new Map<string, EnteFile>();
    files.forEach((file) => {
        const uid = `${file.collectionID}-${file.id}`;
        const existingFile = latestVersionFiles.get(uid);
        if (!existingFile || existingFile.updationTime < file.updationTime) {
            latestVersionFiles.set(uid, file);
        }
    });
    return Array.from(latestVersionFiles.values()).filter(
        // TODO(RE):
        // (file) => !file.isDeleted,
        (file) => !("isDeleted" in file && file.isDeleted),
    );
}
/**
 * Fetch all files from remote and update our local database.
 *
 * If this is the initial read, or if the count of files we have differs from
 * the state of the local database (these two are expected to be the same case),
 * then the {@link onSetCollectionFiles} callback is first invoked to give the
 * caller a chance to bring its state up to speed.
 *
 * Then it calls {@link onAugmentCollectionFiles} as each batch of updates are
 * fetched (in addition to updating the local database).
 *
 * The callbacks are optional because we might be called in a context where we
 * just want to update the local database, and there is no other in-memory state
 * we need to keep in sync.
 *
 * @param collections The user's collections. These are assumed to be the latest
 * collections on remote (that is, the pull for collections should happen prior
 * to calling this function).
 *
 * @param onSetCollectionFiles An optional callback invoked when the locally
 * saved collection files were replaced by the provided {@link collectionFiles}.
 *
 * @param onAugmentCollectionFiles An optional callback when locally saved
 * collection files were augmented with the provided newly fetched
 * {@link collectionFiles}.
 *
 * @returns true if one or more files were updated locally, false otherwise.
 */
export const pullCollectionFiles = async (
    collections: Collection[],
    onSetCollectionFiles: ((files: EnteFile[]) => void) | undefined,
    onAugmentCollectionFiles: ((files: EnteFile[]) => void) | undefined,
) => {
    const localFiles = await savedCollectionFiles();
    let files = removeDeletedCollectionFiles(collections, localFiles);
    let didUpdateFiles = false;
    if (files.length !== localFiles.length) {
        await saveCollectionFiles(files);
        onSetCollectionFiles?.(files);
        didUpdateFiles = true;
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime =
            (await savedCollectionLastSyncTime(collection)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }

        const newFiles = await getFiles(
            collection,
            lastSyncTime,
            onAugmentCollectionFiles,
        );
        await clearCachedThumbnailsIfChanged(localFiles, newFiles);
        files = getLatestVersionFiles([...files, ...newFiles]);
        await saveCollectionFiles(files);
        didUpdateFiles = true;
        await saveCollectionLastSyncTime(collection, collection.updationTime);
    }
    return didUpdateFiles;
};

/**
 * Fetch all files in the given {@link collection} have been created or updated
 * since {@link sinceTime}.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The collection whose updates we want to fetch.
 *
 * @param sinceTime The timestamp of most recently update for the collection
 * that we have already pulled. This serves both as a pagination mechanish, and
 * a way to fetch a delta diff the next time the client needs to pull changes
 * from remote.
 */
const getCollectionDiff = async (collection: Collection, sinceTime: number) => {
    const res = await fetch(
        await apiURL("/collections/v2/diff", {
            collectionID: collection.id.toString(),
            sinceTime: sinceTime.toString(),
        }),
        { headers: await authenticatedRequestHeaders() },
    );
    ensureOk(res);
    return FileDiffResponse.parse(await res.json());
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    onFetchFiles: ((fs: EnteFile[]) => void) | undefined,
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/collections/v2/diff"),
                { collectionID: collection.id, sinceTime: time },
                { "X-Auth-Token": token },
            );

            const newDecryptedFilesBatch = await Promise.all(
                // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
                resp.data.diff.map(async (file: RemoteEnteFile) => {
                    if (!file.isDeleted) {
                        return await decryptRemoteFile(file, collection.key);
                    } else {
                        return file;
                    }
                }) as Promise<EnteFile>[],
            );
            decryptedFiles = [...decryptedFiles, ...newDecryptedFilesBatch];

            onFetchFiles?.(decryptedFiles);
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            if (resp.data.diff.length) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get files failed", e);
        throw e;
    }
};

const removeDeletedCollectionFiles = (
    collections: Collection[],
    files: EnteFile[],
) => {
    const syncedCollectionIds = new Set<number>();
    for (const collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

/**
 * Clear cached thumbnails for existing files if the thumbnail data has changed.
 *
 * This function in expected to be called when we are processing a collection
 * diff, updating our local state to reflect files that were updated on remote.
 * We use this as an opportune moment to invalidate any cached thumbnails which
 * have changed.
 *
 * An example of when such invalidation is necessary:
 *
 * 1. Take a photo on mobile, and let it sync via the mobile app to us (web).
 * 2. Edit the photo outside of Ente (e.g. using Apple Photos).
 * 3. When the Ente mobile client next comes into foreground, it'll update the
 *    remote thumbnail for the existing file to reflect the changes.
 *
 * @param existingFiles The {@link EnteFile}s we had in our local database
 * before processing the diff response.
 *
 * @param newFiles The {@link EnteFile}s which we got in the diff response.
 */
const clearCachedThumbnailsIfChanged = async (
    existingFiles: EnteFile[],
    newFiles: EnteFile[],
) => {
    if (newFiles.length == 0) {
        // Fastpath to no-op if nothing changes.
        return;
    }

    // TODO: This should be constructed once, at the caller (currently the
    // caller doesn't need this, but we'll only know for sure after we
    // consolidate all processing that happens during a diff parse).
    const existingFileByID = new Map(existingFiles.map((f) => [f.id, f]));

    for (const newFile of newFiles) {
        const existingFile = existingFileByID.get(newFile.id);
        const m1 = existingFile?.metadata;
        const m2 = newFile.metadata;
        // TODO: Add an extra truthy check the EnteFile type is null safe
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (!m1 || !m2) continue;
        // Both files exist, have metadata, but their hashes differ, which
        // indicates that the change was in the file's contents, not the
        // metadata itself, and thus we should refresh the thumbnail.
        if (metadataHash(m1) != metadataHash(m2)) {
            // This is an infrequent occurrence, so we lazily get the cache.
            const thumbnailCache = await blobCache("thumbs");
            const key = newFile.id.toString();
            await thumbnailCache.delete(key);
        }
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

export interface AddToCollectionRequest {
    collectionID: number;
    files: CollectionFileItem[];
}

export interface MoveToCollectionRequest {
    fromCollectionID: number;
    toCollectionID: number;
    files: CollectionFileItem[];
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
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
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
    }
};

/**
 * Make a remote request to restore the given {@link files} to the given
 * {@link collection}.
 *
 * Remote only, does not modify local state.
 */
export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
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
    }
};

/**
 * Make a remote request to move the given {@link files} from a collection (as
 * identified by its {@link fromCollectionID}) to the given
 * {@link toCollection}.
 *
 * Remote only, does not modify local state.
 */
export const moveToCollection = async (
    fromCollectionID: number,
    toCollection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
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
    }
};

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
export const moveToTrash = async (files: EnteFile[]) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
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
        );
    }
};

/**
 * Make a remote request to delete the given {@link fileIDs} from trash.
 *
 * Remote only, does not modify local state.
 */
export const deleteFromTrash = async (fileIDs: number[]) => {
    for (const batchIDs of batch(fileIDs, requestBatchSize)) {
        ensureOk(
            await fetch(await apiURL("/trash/delete"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({ fileIDs: batchIDs }),
            }),
        );
    }
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
export const createFavoritesCollection = () =>
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
 * Create a new collection with hidden visibility on remote, marking it as the
 * default hidden collection, and return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
export const createDefaultHiddenCollection = () =>
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

export const isHiddenCollection = (collection: Collection) =>
    collection.magicMetadata?.data.visibility == ItemVisibility.hidden;

/**
 * Return true if this is a collection that the user doesn't own.
 */
export const isIncomingShare = (collection: Collection, user: User) =>
    collection.owner.id !== user.id;

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
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
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
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
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
