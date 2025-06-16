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
    ignore,
    RemoteCollectionUser,
    RemotePublicURL,
    type Collection2,
} from "ente-media/collection";
import { RemoteMagicMetadata } from "ente-media/magic-metadata";
import localForage from "ente-shared/storage/localForage";
import { nullishToEmpty } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Zod schema for a {@link Collection} saved in our local persistence.
 *
 * This is similar to {@link RemoteCollection}, but has significant differences
 * too in that it contains the decrypted fields, and some minor refinements.
 */
// TODO(C2): Use me
const LocalCollection = z.looseObject({
    id: z.number(),
    owner: RemoteCollectionUser,
    key: z.string(),
    name: z.string(),
    type: z.string(),
    sharees: z.array(RemoteCollectionUser).nullish().transform(nullishToEmpty),
    publicURLs: z.array(RemotePublicURL).nullish().transform(nullishToEmpty),
    updationTime: z.number(),
    magicMetadata: RemoteMagicMetadata.nullish().transform((mm) => {
        if (!mm) return undefined;
        // Old code used to save the header, however it's unnecessary so we drop
        // it on the next read. New code will not save it, so eventually this
        // special case can be removed. Note added Jun 2025 (tag: Migration).
        const { header, ...rest } = mm;
        ignore(header);
        const data = CollectionPrivateMagicMetadataData.parse(rest.data);
        return { ...rest, data };
    }),
    pubMagicMetadata: RemoteMagicMetadata.nullish().transform((mm) => {
        if (!mm) return undefined;
        const { header, ...rest } = mm;
        ignore(header);
        const data = CollectionPublicMagicMetadataData.parse(rest.data);
        return { ...rest, data };
    }),
    sharedMagicMetadata: RemoteMagicMetadata.nullish().transform((mm) => {
        if (!mm) return undefined;
        const { header, ...rest } = mm;
        ignore(header);
        const data = CollectionShareeMagicMetadataData.parse(rest.data);
        return { ...rest, data };
    }),
});

const LocalCollections = z.array(LocalCollection);

/**
 * Return all collections present in our local database.
 *
 * This includes both normal (non-hidden) and hidden collections.
 *
 * Use {@link saveCollections} to update the database.
 */
export const savedCollections = async (): Promise<Collection2[]> =>
    LocalCollections.parse(await localForage.getItem("collections"));

/**
 * Replace the list of collections stored in our local database.
 *
 * This updates the underlying storage of both normal (non-hidden) and hidden
 * collections (the split between normal and hidden is not at the database level
 * but is a filter when they are accessed).
 */
export const saveCollections = (collections: Collection2[]) =>
    localForage.setItem("collections", collections);
