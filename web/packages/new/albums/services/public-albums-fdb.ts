/**
 * @file Public albums app specific files DB. See: [Note: Files DB].
 */

import { LocalCollections } from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";

/**
 * Return all public collections present in our local database.
 *
 * Use {@link savePublicCollections} to update the database.
 */
export const savedPublicCollections = async (): Promise<Collection[]> =>
    // TODO:
    //
    // See: [Note: strict mode migration]
    //
    // We need to add the cast here, otherwise we get a tsc error when this
    // file is imported in the photos app.
    LocalCollections.parse(
        (await localForage.getItem("public-collections")) ?? [],
    ) as Collection[];

/**
 * Replace the list of public collections stored in our local database.
 *
 * This is the setter corresponding to {@link savedPublicCollections}.
 */
export const savePublicCollections = (collections: Collection[]) =>
    localForage.setItem("public-collections", collections);
