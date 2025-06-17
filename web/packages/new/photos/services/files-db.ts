/**
 * @file
 *
 * [Note: Files DB]
 *
 * Prior to us using idb for accessing IndexedDB, we used localForage (another
 * IndexedDB library) for that purpose (See `docs/storage.md` for more context).
 *
 * Our use of localForage was limited to a single IndexedDB table named "files".
 * It stored more than files though - files, collections, trash, and their
 * corresponding sync times.
 *
 * Since we've now switched to IDB as our preferred IndexedDB library, the data
 * stored in this files table could be considered legacy in a sense. But such
 * would be an incorrect characterization - this code has no issues, and it
 * stores core data for us (files and collections are as core as it gets).
 *
 * So this table is not legacy or deprecated, and there is currently no strong
 * reason to migrate this data to another IndexedDB table (it works fine as it
 * is, really). However we do want to avoid adding more items here.
 */

import {
    CollectionPrivateMagicMetadataData,
    CollectionPublicMagicMetadataData,
    CollectionShareeMagicMetadataData,
    RemoteCollectionUser,
    RemotePublicURL,
    type Collection,
} from "ente-media/collection";
import localForage from "ente-shared/storage/localForage";
import { nullishToEmpty, nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Zod schema for a {@link Collection} saved in our local persistence.
 *
 * This is similar to {@link RemoteCollection}, but has both significant
 * differences in that it contains the decrypted fields, and some minor tweaks.
 */
const LocalCollection = z.looseObject({
    id: z.number(),
    owner: RemoteCollectionUser,
    key: z.string(),
    name: z.string(),
    type: z.string(),
    sharees: z.array(RemoteCollectionUser).nullish().transform(nullishToEmpty),
    publicURLs: z.array(RemotePublicURL).nullish().transform(nullishToEmpty),
    updationTime: z.number(),
    magicMetadata: z
        .object({
            version: z.number(),
            count: z.number(),
            data: CollectionPrivateMagicMetadataData,
        })
        .nullish()
        .transform(nullToUndefined),
    pubMagicMetadata: z
        .object({
            version: z.number(),
            count: z.number(),
            data: CollectionPublicMagicMetadataData,
        })
        .nullish()
        .transform(nullToUndefined),
    sharedMagicMetadata: z
        .object({
            version: z.number(),
            count: z.number(),
            data: CollectionShareeMagicMetadataData,
        })
        .nullish()
        .transform(nullToUndefined),
});

const LocalCollections = z.array(LocalCollection);

/**
 * Return all collections present in our local database.
 *
 * This includes both normal (non-hidden) and hidden collections.
 *
 * Use {@link saveCollections} to update the database.
 */
export const savedCollections = async (): Promise<Collection[]> =>
    LocalCollections.parse(await localForage.getItem("collections"));

/**
 * Replace the list of collections stored in our local database.
 *
 * This updates the underlying storage of both normal (non-hidden) and hidden
 * collections (the split between normal and hidden is not at the database level
 * but is a filter when they are accessed).
 */
export const saveCollections = (collections: Collection[]) =>
    localForage.setItem("collections", collections);
