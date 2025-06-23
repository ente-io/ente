/**
 * @file
 *
 * [Note: Files DB]
 *
 * Prior to us using idb for accessing IndexedDB, we used localForage (another
 * IndexedDB library) for that purpose (See `docs/storage.md` for more context).
 *
 * Our use of localForage was limited to a single IndexedDB database named
 * "ente-files" with a single (pertinent) table named "files". It stored more
 * than files though - files, collections, trash, their corresponding sync
 * times, and other bits and bobs.
 *
 * Since we've now switched to idb as our preferred IndexedDB library, the data
 * stored in this files table could be considered legacy in a sense. But such
 * would be an incorrect characterization - this code has no issues, and it
 * stores core data for us (files and collections are as core as it gets).
 *
 * So this table is not legacy or deprecated, and there is currently no strong
 * reason to migrate this data to another IndexedDB table (it works fine as it
 * is, really). However we do want to avoid adding more items here, and maybe
 * gradually move some of the "bits and bobs" elsewhere (e.g. KV DB).
 *
 * ---
 *
 * This file contains the common code and types. Application layer code should
 * usually be accessing the app specific files DB by importing the functions
 * from the following modules:
 *
 * - Photos app: `photos-fdb.ts`
 * - Public albums app: `public-albums-fdb.ts`
 *
 * Note that even though both of them refer to the same conceptual "files DB",
 * the actual storage is distinct since both the apps run on separate domains
 * and so have their separate IndexedDB storage.
 *
 * Still, the key names are (generally) distinct to reduce chances of confusion.
 */

import {
    CollectionPrivateMagicMetadataData,
    CollectionPublicMagicMetadataData,
    CollectionShareeMagicMetadataData,
    ignore,
    RemoteCollectionUser,
    RemotePublicURL,
} from "ente-media/collection";
import { RemoteFileInfo, RemoteFileObjectAttributes } from "ente-media/file";
import {
    FileMetadata,
    FilePrivateMagicMetadataData,
    FilePublicMagicMetadataData,
} from "ente-media/file-metadata";
import { nullishToEmpty, nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Return a Zod schema suitable for being used with the various magic metadata
 * fields of a file or a collection.
 */
const createMagicMetadataSchema = <T extends z.ZodType>(dataSchema: T) =>
    z
        .object({ version: z.number(), count: z.number(), data: dataSchema })
        .nullish()
        .transform(nullToUndefined);

/**
 * Zod schema for a {@link Collection} stored in our local database.
 *
 * This is similar to {@link RemoteCollection}, but it differs in that it
 * contains the decrypted values instead of the encrypted data and nonce pairs.
 * There are also some other minor nullish transforms.
 */
const LocalCollection = z
    .looseObject({
        id: z.number(),
        owner: RemoteCollectionUser,
        key: z.string(),
        name: z.string(),
        type: z.string(),
        sharees: z
            .array(RemoteCollectionUser)
            .nullish()
            .transform(nullishToEmpty),
        publicURLs: z
            .array(RemotePublicURL)
            .nullish()
            .transform(nullishToEmpty),
        updationTime: z.number(),
        magicMetadata: createMagicMetadataSchema(
            CollectionPrivateMagicMetadataData,
        ),
        pubMagicMetadata: createMagicMetadataSchema(
            CollectionPublicMagicMetadataData,
        ),
        sharedMagicMetadata: createMagicMetadataSchema(
            CollectionShareeMagicMetadataData,
        ),
    })
    .transform((c) => {
        // Old data stored locally contained fields which are no longer needed.
        // Do some zod gymnastics to drop these when reading (so that they're
        // not written back the next time). This code was added June 2025,
        // 1.7.14-beta, and can be removed after a bit (tag: Migration).
        const {
            encryptedKey,
            keyDecryptionNonce,
            encryptedName,
            nameDecryptionNonce,
            attributes,
            isDeleted,
            ...rest
        } = c;
        ignore([
            encryptedKey,
            keyDecryptionNonce,
            encryptedName,
            nameDecryptionNonce,
            attributes,
            isDeleted,
        ]);
        return rest;
    });

export const LocalCollections = z.array(LocalCollection);

/**
 * Zod schema for a {@link EnteFile} stored in our local database.
 *
 * This is similar to {@link RemoteEnteFile}, but it differs in that it contains
 * the decrypted values instead of the encrypted data and nonce pairs.
 */
export const LocalEnteFile = z.looseObject({
    id: z.number(),
    collectionID: z.number(),
    ownerID: z.number(),
    key: z.string(),
    file: RemoteFileObjectAttributes,
    thumbnail: RemoteFileObjectAttributes,
    info: RemoteFileInfo.nullish().transform(nullToUndefined),
    updationTime: z.number(),
    metadata: FileMetadata,
    magicMetadata: createMagicMetadataSchema(FilePrivateMagicMetadataData),
    pubMagicMetadata: createMagicMetadataSchema(FilePublicMagicMetadataData),
});

export const LocalEnteFiles = z.array(LocalEnteFile);
