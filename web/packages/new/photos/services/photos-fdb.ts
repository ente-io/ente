/**
 * @file Photos app specific files DB. See: [Note: Files DB].
 */

import { LocalCollections } from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";
import { z } from "zod/v4";

/**
 * Return all collections present in our local database.
 *
 * This includes both normal (non-hidden) and hidden collections.
 *
 * Use {@link saveCollections} to update the database.
 */
export const savedCollections = async (): Promise<Collection[]> =>
    // TODO:
    //
    // See: [Note: strict mode migration]
    //
    // We need to add the cast here, otherwise we get a tsc error when this
    // file is imported in the photos app.
    LocalCollections.parse(
        (await localForage.getItem("collections")) ?? [],
    ) as Collection[];

/**
 * Replace the list of collections stored in our local database.
 *
 * This is the setter corresponding to {@link savedCollections}.
 *
 * This updates the underlying storage of both normal (non-hidden) and hidden
 * collections (the split between normal and hidden is not at the database level
 * but is a filter when they are accessed).
 */
export const saveCollections = (collections: Collection[]) =>
    localForage.setItem("collections", collections);

const TrashItemCollectionKey = z.object({
    /**
     * Collection ID.
     */
    id: z.number(),
    /**
     * Decrypted collection key.
     */
    key: z.string(),
});

const TrashItemCollectionKeys = TrashItemCollectionKey.array();

export type TrashItemCollectionKey = z.infer<typeof TrashItemCollectionKey>;

/**
 * Return keys of collections (including potentially deleted ones) referred to
 * by trash items present in our local database.
 *
 * Use {@link saveTrashItemCollectionKeys} to update the database.
 *
 * [Note: Trash item collection keys]
 *
 * Trash items are erstwhile files, and like collection files, they need a
 * collection key to decrypt them.
 *
 * However, it is possible that the collection which contained the file was also
 * deleted. Such deleted collections will not be present in the list returned by
 * {@link savedCollections}.
 *
 * So to still be able to access the collection keys in order to process the
 * trash item, we separately save a list of {collectionID, collectionKey} pairs.
 *
 * - This list contains only collectionsIDs for which there is a corresponding
 *   local trash item.
 *
 * - During each trash sync, this list is seeded using {@link savedCollections}.
 *   Then, whenever we encounter a collection which is not present locally
 *   (since it might've been deleted), we fetch it from remote and add an entry
 *   for it in {@link savedTrashItemCollectionKeys}.
 *
 * - Once the sync completes, we updated this list to retain only entries that
 *   are still referred to by items remaining in the trash.
 */
export const savedTrashItemCollectionKeys = async (): Promise<
    TrashItemCollectionKey[]
> =>
    TrashItemCollectionKeys.parse(
        // This key name is not accurate, these are not deleted collections but
        // collections referred to by deleted items (so they can include deleted
        // collections, but not exclusively).
        //
        // But since the use of this key name is localized to this file so we
        // let the original name be.
        (await localForage.getItem("deleted-collection")) ?? [],
    );

/**
 * Replace the list of trash item collection keys stored in our local database.
 *
 * This is the setter corresponding to {@link saveTrashItemCollectionKeys}.
 */
export const saveTrashItemCollectionKeys = (cks: TrashItemCollectionKey[]) =>
    localForage.setItem("deleted-collection", cks);
