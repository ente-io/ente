/**
 * @file Public albums app specific files DB. See: [Note: Files DB].
 */

import {
    LocalCollections,
    LocalEnteFiles,
    transformFilesIfNeeded,
} from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import localForage from "ente-shared/storage/localForage";
import { z } from "zod/v4";

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

const LocalSavedPublicCollectionFilesEntry = z.object({
    /**
     * The collection, identified by its access token.
     *
     * See: [Note: Public album access token]
     */
    collectionUID: z.string(),
    files: LocalEnteFiles,
});

type LocalSavedPublicCollectionFilesEntry = z.infer<
    typeof LocalSavedPublicCollectionFilesEntry
>;

/**
 * Return all files for a public collection present in our local database.
 *
 * Use {@link savePublicCollectionFiles} to update the database.
 *
 * @param accessToken The access token of the public album whose files we want.
 */
export const savedPublicCollectionFiles = async (
    accessToken: string,
): Promise<EnteFile[]> => {
    type ES = LocalSavedPublicCollectionFilesEntry[];
    // See: [Note: Avoiding Zod parsing for large DB arrays] for why we use an
    // (implied) cast here instead of parsing using the Zod schema.
    const entries = await localForage.getItem<ES>("public-collection-files");
    const entry = (entries ?? []).find((e) => e.collectionUID == accessToken);
    return transformFilesIfNeeded(entry ? entry.files : []);
};
