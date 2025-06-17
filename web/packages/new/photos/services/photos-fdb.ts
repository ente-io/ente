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
