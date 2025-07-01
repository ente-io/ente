import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { Collection } from "ente-media/collection";
import {
    decryptRemoteFile,
    RemoteEnteFile,
    type EnteFile,
} from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { z } from "zod/v4";
import { getCollectionByID } from "./collection";
import {
    savedTrashItemCollectionKeys,
    savedTrashItems,
    savedTrashLastUpdatedAt,
    saveTrashItemCollectionKeys,
    saveTrashItems,
    saveTrashLastUpdatedAt,
} from "./photos-fdb";

/**
 * A trash item indicates a file in trash.
 *
 * On being deleted by the user, files move to trash, and gain this associated
 * trash item, which we can fetch with correspoding diff APIs etc. Files will be
 * permanently deleted after 30 days of being moved to trash, but can be
 * restored or permanently deleted before that by explicit user action.
 *
 * See: [Note: File lifecycle]
 */
export interface TrashItem {
    file: EnteFile;
    /**
     * Timestamp (epoch microseconds) when the trash entry was last updated.
     */
    updatedAt: number;
    /**
     * Timestamp (epoch microseconds) when the trash item (along with its
     * associated {@link EnteFile}) will be permanently deleted.
     */
    deleteBy: number;
}

/**
 * Zod schema for a trash item that we receive from remote.
 */
const RemoteTrashItem = z.looseObject({
    file: RemoteEnteFile,
    /**
     * `true` if the file no longer in trash because it was permanently deleted.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was permanently deleted.
     */
    isDeleted: z.boolean(),
    /**
     * `true` if the file no longer in trash because it was restored to some
     * collection.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was restored to a collection.
     */
    isRestored: z.boolean(),
    updatedAt: z.number(),
    deleteBy: z.number(),
});

export type RemoteTrashItem = z.infer<typeof RemoteTrashItem>;

/**
 * Update our locally saved data about the files and collections in trash by
 * pulling changes from remote.
 *
 * This function uses a delta diff, pulling only changes since the timestamp
 * saved by the last pull.
 *
 * @param collections All the (non-deleted) collections that we know about
 * locally.
 *
 * @param onSetTrashedItems A callback invoked when the locally persisted trash
 * items are updated. This can be used for the UI to also update its state.
 *
 * This callback can be invoked multiple times during the pull (once for each
 * batch that gets pulled and processed). Each time, it gets passed a list of
 * all the items that are present in trash (in an arbitrary order).
 *
 * @param onPruneDeletedFileIDs A callback invoked when files that were
 * previously in trash have now been permanently deleted. This can be used by
 * other subsystems to prune data referring to files that now have been deleted
 * permanently.
 *
 * This callback can be invoked multiple times during the pull (once for each
 * batch that gets processed).
 */
export const pullTrash = async (
    collections: Collection[],
    onSetTrashedItems: ((trashItems: TrashItem[]) => void) | undefined,
    onPruneDeletedFileIDs: (deletedFileIDs: Set<number>) => Promise<void>,
): Promise<void> => {
    // Data structures:
    //
    // `collectionKeyByID` is a map from collection ID => collection key.
    //
    // It is prefilled with all the non-deleted collections available locally
    // (`collections`), and all keys of collections that trash items refererred
    // to the last time we synced (`trashItemCollectionKeys`).
    //
    // > See: [Note: Trash item collection keys]
    //
    // As we iterate over the trash items, if we find a collection whose key is
    // not present in the map, then we fetch that collection from remote, add
    // its entry to the map, and also updated the persisted value corresponding
    // to `trashItemCollectionKeys`.
    //
    // When we're done, we use `collectionKeyByID` to derive a filtered list of
    // keys that are still referred to by the current set of trash items, and
    // set this filtered list as the persisted value of
    // `trashItemCollectionKeys`.

    const collectionKeyByID = new Map(collections.map((c) => [c.id, c.key]));
    const trashItemCollectionKeys = await savedTrashItemCollectionKeys();
    for (const { id, key } of trashItemCollectionKeys) {
        collectionKeyByID.set(id, key);
    }

    // Trash items, indexed by the file ID of the file they correspond to.
    const trashItemsByID = new Map(
        (await savedTrashItems()).map((t) => [t.file.id, t]),
    );
    let sinceTime = (await savedTrashLastUpdatedAt()) ?? 0;

    while (true) {
        const { diff, hasMore } = await getTrashDiff(sinceTime);
        if (!diff.length) break;

        // IDs of files that we encounter in this batch that have been
        // permanently deleted.
        const deletedFileIDs = new Set<number>();
        for (const change of diff) {
            sinceTime = Math.max(sinceTime, change.updatedAt);
            const fileID = change.file.id;
            if (change.isDeleted) deletedFileIDs.add(fileID);
            if (change.isDeleted || change.isRestored) {
                trashItemsByID.delete(fileID);
            } else {
                const collectionID = change.file.collectionID;
                let collectionKey = collectionKeyByID.get(collectionID);
                if (!collectionKey) {
                    // See: [Note: Trash item collection keys]
                    const collection = await getCollectionByID(collectionID);
                    collectionKey = collection.key;
                    collectionKeyByID.set(collectionID, collectionKey);
                    trashItemCollectionKeys.push({
                        id: collectionID,
                        key: collectionKey,
                    });
                    await saveTrashItemCollectionKeys(trashItemCollectionKeys);
                }
                trashItemsByID.set(fileID, {
                    ...change,
                    file: await decryptRemoteFile(change.file, collectionKey),
                });
            }
        }

        const trashItems = [...trashItemsByID.values()];
        onSetTrashedItems?.(trashItems);
        await saveTrashItems(trashItems);
        await saveTrashLastUpdatedAt(sinceTime);
        if (deletedFileIDs.size) await onPruneDeletedFileIDs(deletedFileIDs);
        if (!hasMore) break;
    }

    const trashCollectionIDs = new Set(
        [...trashItemsByID.values()].map((item) => item.file.collectionID),
    );
    await saveTrashItemCollectionKeys(
        [...collectionKeyByID.entries()]
            .filter(([id]) => trashCollectionIDs.has(id))
            .map(([id, key]) => ({ id, key })),
    );
};

/**
 * See {@link FileDiffResponse} for general semantics of diff responses.
 */
const TrashDiffResponse = z.object({
    diff: RemoteTrashItem.array(),
    hasMore: z.boolean(),
});

/**
 * Fetch all trash items that have been created or updated since
 * {@link sinceTime}.
 *
 * Remote only, does not modify local state.
 *
 * @param sinceTime The {@link updatedAt} of the most recently updated trash
 * item we have previously fetched from remote. This serves both as a pagination
 * mechanish, and a way to fetch a delta diff the next time the client needs to
 * pull changes from remote.
 */
const getTrashDiff = async (sinceTime: number) => {
    const res = await fetch(await apiURL("/trash/v2/diff", { sinceTime }), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return TrashDiffResponse.parse(await res.json());
};

/**
 * Sort trash items such that the items which were recently deleted are first.
 *
 * This is a variant of {@link sortFiles}; it sorts {@link items} in place and
 * also returns a reference to the same mutated arrays.
 *
 * Items are sorted in descending order of their time to deletion (that is, the
 * items which were the most recently deleted will be at the top). For items
 * with the same time to deletion, the ordering is in descending order of the
 * item's file's modification or creation date.
 */
export const sortTrashItems = (trashItems: TrashItem[]) =>
    trashItems.sort((a, b) => {
        if (a.deleteBy == b.deleteBy) {
            const af = a.file;
            const bf = b.file;
            const at = fileCreationTime(af);
            const bt = fileCreationTime(bf);
            return at == bt
                ? bf.metadata.modificationTime - af.metadata.modificationTime
                : bt - at;
        }
        return b.deleteBy - a.deleteBy;
    });

/**
 * Return the IDs of all the files that are part of the trash in our local
 * database.
 */
export const savedTrashItemFileIDs = () =>
    savedTrashItems().then((items) => new Set(items.map((f) => f.file.id)));

/**
 * Delete all the items in trash, permanently deleting the files corresponding
 * to them.
 *
 * This updates both remote and our local database.
 */
export const emptyTrash = async () => {
    await postTrashEmpty((await savedTrashLastUpdatedAt()) ?? 0);
    await saveTrashItems([]);
};

/**
 * Delete all the items in trash on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param lastUpdatedAt The {@link updatedAt} value of the most recent item in
 * trash for the user that we know about locally. Remote will only delete trash
 * entries with updatedAt timestamp <= this provided lastUpdatedAt.
 *
 * The user's trash is cleaned up in an async manner. This timestamp is used to
 * ensure that newly trashed files are not deleted due to delay in the async
 * operation, and that out of sync clients (who have a stale lastUpdatedAt)
 * do not cause deletion of newer files that they don't know about locally.
 */
const postTrashEmpty = async (lastUpdatedAt: number) =>
    ensureOk(
        await fetch(await apiURL("/trash/empty"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ lastUpdatedAt }),
        }),
    );
