/**
 * @file Photos app specific files DB. See: [Note: Files DB].
 */

import { LocalCollections } from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";

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
 * This updates the underlying storage of both normal (non-hidden) and hidden
 * collections (the split between normal and hidden is not at the database level
 * but is a filter when they are accessed).
 */
export const saveCollections = (collections: Collection[]) =>
    localForage.setItem("collections", collections);

/**
 * Return keys of (potentially deleted) collections referred to by trash items
 * present in our local database.
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
