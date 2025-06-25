import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";
import { getCollections } from "./collection";
import { savedCollections } from "./photos-fdb";

const COLLECTION_TABLE = "collections";
const COLLECTION_UPDATION_TIME = "collection-updation-time";

export const getCollectionLastSyncTime = async (collection: Collection) =>
    (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;

export const setCollectionLastSyncTime = async (
    collection: Collection,
    time: number,
) => await localForage.setItem<number>(`${collection.id}-time`, time);

export const removeCollectionIDLastSyncTime = async (collectionID: number) =>
    await localForage.removeItem(`${collectionID}-time`);

export const getCollectionUpdationTime = async (): Promise<number> =>
    (await localForage.getItem<number>(COLLECTION_UPDATION_TIME)) ?? 0;

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
    let sinceTime = await getCollectionUpdationTime();

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

    await localForage.setItem(COLLECTION_TABLE, updatedCollections);
    await localForage.setItem(COLLECTION_UPDATION_TIME, sinceTime);

    return updatedCollections;
};
