// TODO: Audit this file
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { type Collection } from "ente-media/collection";
import { decryptRemoteFile, type EnteFile } from "ente-media/file";
import {
    getLocalTrash,
    getTrashedFiles,
    TRASH,
    type EncryptedTrashItem,
    type Trash,
} from "ente-new/photos/services/trash";
import HTTPService from "ente-shared/network/HTTPService";
import localForage from "ente-shared/storage/localForage";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import {
    getCollectionByID,
    getCollectionChanges,
    isHiddenCollection,
} from "./collection";
import {
    savedCollections,
    savedTrashItemCollectionKeys,
    saveTrashItemCollectionKeys,
} from "./photos-fdb";

const COLLECTION_TABLE = "collections";
const HIDDEN_COLLECTION_IDS = "hidden-collection-ids";
const COLLECTION_UPDATION_TIME = "collection-updation-time";

export const getLocalCollections = async (
    type: "normal" | "hidden" = "normal",
): Promise<Collection[]> => {
    const collections = await savedCollections();
    return type == "normal"
        ? collections.filter((c) => !isHiddenCollection(c))
        : collections.filter((c) => isHiddenCollection(c));
};

export const getCollectionLastSyncTime = async (collection: Collection) =>
    (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;

export const setCollectionLastSyncTime = async (
    collection: Collection,
    time: number,
) => await localForage.setItem<number>(`${collection.id}-time`, time);

export const removeCollectionIDLastSyncTime = async (collectionID: number) =>
    await localForage.removeItem(`${collectionID}-time`);

export const getHiddenCollectionIDs = async (): Promise<number[]> =>
    (await localForage.getItem<number[]>(HIDDEN_COLLECTION_IDS)) ?? [];

export const getCollectionUpdationTime = async (): Promise<number> =>
    (await localForage.getItem<number>(COLLECTION_UPDATION_TIME)) ?? 0;

export const getLatestCollections = async (
    type: "normal" | "hidden" = "normal",
): Promise<Collection[]> => {
    const collections = await getAllLatestCollections();
    return type == "normal"
        ? collections.filter((c) => !isHiddenCollection(c))
        : collections.filter((c) => isHiddenCollection(c));
};

export const getAllLatestCollections = async (): Promise<Collection[]> => {
    const collections = await syncCollections();
    return collections;
};

export const syncCollections = async () => {
    const localCollections = await savedCollections();
    let sinceTime = await getCollectionUpdationTime();

    const changes = await getCollectionChanges(sinceTime);
    if (!changes.length) return localCollections;

    const hiddenCollectionIDs = await getHiddenCollectionIDs();

    const collectionsByID = new Map(localCollections.map((c) => [c.id, c]));
    for (const { id, updationTime, collection } of changes) {
        sinceTime = Math.max(sinceTime, updationTime);
        let removeSyncTime = false;
        if (collection) {
            collectionsByID.set(id, collection);

            const wasHidden = hiddenCollectionIDs.includes(collection.id);
            const isHidden = isHiddenCollection(collection);
            // If hidden state changes.
            removeSyncTime = wasHidden != isHidden;
        } else {
            // Collection was deleted on remote.
            collectionsByID.delete(id);

            removeSyncTime = true;
        }

        if (removeSyncTime) {
            await removeCollectionIDLastSyncTime(id);
        }
    }

    const collections = [...collectionsByID.values()];
    const updatedHiddenCollectionIDs = collections
        .filter((collection) => isHiddenCollection(collection))
        .map((collection) => collection.id);

    await localForage.setItem(COLLECTION_TABLE, collections);
    await localForage.setItem(COLLECTION_UPDATION_TIME, sinceTime);
    await localForage.setItem(
        HIDDEN_COLLECTION_IDS,
        updatedHiddenCollectionIDs,
    );

    return collections;
};

const TRASH_TIME = "trash-time";

async function getLastTrashSyncTime() {
    return (await localForage.getItem<number>(TRASH_TIME)) ?? 0;
}

/**
 * Update our locally saved data about the files and collections in trash by
 * syncing with remote.
 *
 * The sync uses a diff-based mechanism that syncs forward from the last sync
 * time (also persisted).
 *
 * @param collections All the (non-deleted) collections that we know about
 * locally.
 *
 * @param onUpdateTrashFiles A callback invoked when the locally persisted trash
 * items are updated. This can be used for the UI to also update its state. This
 * callback can be invoked multiple times during the sync (once for each batch
 * that gets processed).
 *
 * @param onPruneDeletedFileIDs A callback invoked when files that were
 * previously in trash have now been permanently deleted. This can be used by
 * other subsystems to prune data referring to files that now have been deleted
 * permanently. This callback can be invoked multiple times during the sync
 * (once for each batch that gets processed).
 */
export async function syncTrash(
    collections: Collection[],
    onUpdateTrashFiles: ((files: EnteFile[]) => void) | undefined,
    onPruneDeletedFileIDs: (deletedFileIDs: Set<number>) => Promise<void>,
): Promise<void> {
    const trash = await getLocalTrash();
    const sinceTime = await getLastTrashSyncTime();

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

    let updatedTrash: Trash = [...trash];
    try {
        let time = sinceTime;

        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/trash/v2/diff"),
                { sinceTime: time },
                { "X-Auth-Token": token },
            );
            const deletedFileIDs = new Set<number>();
            // #Perf: This can be optimized by running the decryption in parallel
            for (const trashItem of resp.data.diff as EncryptedTrashItem[]) {
                const collectionID = trashItem.file.collectionID;
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
                if (trashItem.isDeleted) {
                    deletedFileIDs.add(trashItem.file.id);
                }
                if (!trashItem.isDeleted && !trashItem.isRestored) {
                    const decryptedFile = await decryptRemoteFile(
                        trashItem.file,
                        collectionKey,
                    );
                    updatedTrash.push({ ...trashItem, file: decryptedFile });
                } else {
                    updatedTrash = updatedTrash.filter(
                        (item) => item.file.id !== trashItem.file.id,
                    );
                }
            }

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updatedAt;
            }

            onUpdateTrashFiles?.(getTrashedFiles(updatedTrash));
            if (deletedFileIDs.size > 0) {
                await onPruneDeletedFileIDs(deletedFileIDs);
            }
            await localForage.setItem(TRASH, updatedTrash);
            await localForage.setItem(TRASH_TIME, time);
        } while (resp.data.hasMore);
    } catch (e) {
        log.error("Get trash files failed", e);
    }

    const trashCollectionIDs = new Set(
        updatedTrash.map((item) => item.file.collectionID),
    );
    await saveTrashItemCollectionKeys(
        [...collectionKeyByID.entries()]
            .filter(([id]) => trashCollectionIDs.has(id))
            .map(([id, key]) => ({ id, key })),
    );
}

export const emptyTrash = async () => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const lastUpdatedAt = await getLastTrashSyncTime();

        await HTTPService.post(
            await apiURL("/trash/empty"),
            { lastUpdatedAt },
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            null,
            { "X-Auth-Token": token },
        );
    } catch (e) {
        log.error("empty trash failed", e);
        throw e;
    }
};

export const clearLocalTrash = async () => {
    await localForage.setItem(TRASH, []);
};
