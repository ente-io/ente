import { type Collection } from "ente-media/collection";
import { getCollections } from "./collection";
import {
    removeCollectionIDLastSyncTime,
    saveCollections,
    saveCollectionsUpdationTime,
    savedCollections,
    savedCollectionsUpdationTime,
} from "./photos-fdb";

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
