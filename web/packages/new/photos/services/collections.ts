import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";
import { getCollections, isHiddenCollection } from "./collection";
import {
    savedCollections,
    savedHiddenCollectionIDs,
    saveHiddenCollectionIDs,
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

/**
 * Pull the latest collections from remote.
 *
 * This function uses a delta diff, pulling only changes since the timestamp
 * saved by the last pull.
 *
 * @returns
 *
 * 1. The latest list of collections, reflecting both the state in our local
 *    database and on remote; and
 *
 * 2. The IDs of the collections that are hidden.
 */
export const pullCollections = async (): Promise<{
    collections: Collection[];
    hiddenCollectionIDs: Set<number>;
}> => {
    const collections = await savedCollections();
    const hiddenCollectionIDs = await savedHiddenCollectionIDs();
    let sinceTime = await getCollectionUpdationTime();

    const changes = await getCollections(sinceTime);

    if (!changes.length) return { collections, hiddenCollectionIDs };

    const collectionsByID = new Map(collections.map((c) => [c.id, c]));
    for (const { id, updationTime, collection } of changes) {
        sinceTime = Math.max(sinceTime, updationTime);
        let removeSyncTime = false;
        if (collection) {
            collectionsByID.set(id, collection);

            const wasHidden = hiddenCollectionIDs.has(collection.id);
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

    const updatedCollections = [...collectionsByID.values()];
    const updatedHiddenCollectionIDs = new Set(
        updatedCollections
            .filter((collection) => isHiddenCollection(collection))
            .map((collection) => collection.id),
    );

    await localForage.setItem(COLLECTION_TABLE, updatedCollections);
    await localForage.setItem(COLLECTION_UPDATION_TIME, sinceTime);
    await saveHiddenCollectionIDs(updatedHiddenCollectionIDs);

    return {
        collections: updatedCollections,
        hiddenCollectionIDs: updatedHiddenCollectionIDs,
    };
};
