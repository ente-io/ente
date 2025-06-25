import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";
import { getCollections, isHiddenCollection } from "./collection";
import { savedCollections } from "./photos-fdb";

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
    const localCollections = await savedCollections();
    let sinceTime = await getCollectionUpdationTime();

    const changes = await getCollections(sinceTime);
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
