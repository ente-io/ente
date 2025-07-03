/**
 * @file
 *
 * [Note: Files DB]
 *
 * Prior to us using idb for accessing IndexedDB, we used localForage (another
 * IndexedDB library) for that purpose (See `docs/storage.md` for more context).
 *
 * Our use of localForage was (and is) limited to:
 *
 * - A single IndexedDB database named "ente-files" containing
 *
 *   - A single table named "files"
 *
 * It stored more than files though - files, collections, trash, their
 * corresponding sync times, and other bits and bobs related to them.
 *
 * > Note: File contents themselves are not stored in IndexedDB, only
 * > {@link EnteFile}s.
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
 * and so have their separate IndexedDB storage and thus separate files tables.
 *
 * Still, the key names are distinct to reduce chances of confusion: the public
 * albums app stores data in keys prefixed with "public-".
 */

import { haveWindow } from "ente-base/env";
import log from "ente-base/log";
import {
    CollectionPrivateMagicMetadataData,
    CollectionPublicMagicMetadataData,
    CollectionShareeMagicMetadataData,
    ignore,
    RemoteCollectionUser,
    RemotePublicURL,
} from "ente-media/collection";
import {
    RemoteFileInfo,
    RemoteFileObjectAttributes,
    transformDecryptedMetadataJSON,
    type EnteFile,
} from "ente-media/file";
import {
    FileMetadata,
    FilePrivateMagicMetadataData,
    FilePublicMagicMetadataData,
} from "ente-media/file-metadata";
import type { MagicMetadata } from "ente-media/magic-metadata";
import { nullishToEmpty, nullToUndefined } from "ente-utils/transform";
import localForage from "localforage";
import { z } from "zod/v4";

if (haveWindow()) {
    localForage.config({
        name: "ente-files",
        version: 1.0,
        storeName: "files",
    });
}

/**
 * Reexport localForage for use by (and only by):
 * - photos-fdb.ts
 * - public-albums-fdb.ts
 * - migration.ts
 */
export { localForage };

/**
 * Return `true` if we can access IndexedDB.
 *
 * This is used as a pre-flight check, to notify the user if they're using a
 * browser or extension that is preventing the app from using IndexedDB (which
 * is necessary for local storage of collections and files metadata).
 */
export const canAccessIndexedDB = async () => {
    try {
        await localForage.ready();
        return true;
    } catch (e) {
        log.error("IndexDB is not accessible", e);
        return false;
    }
};

/**
 * Clear any data stored in files DB.
 *
 * This is meant to be called during the logout sequence.
 */
export const clearFilesDB = () => localForage.clear();

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

/**
 * Apply transformations when reading files from the DB.
 *
 * There are two parts to it -
 *
 * 1. the required part (patching old entries that might be present in the local
 *    database),
 * 2. the optional part (removing some unused fields).
 *
 * Part 1 ---
 *
 * Transform metadata in legacy files that might be present in the local
 * database. Note that this will not be needed for files that are fetched
 * afresh, since the corresponding transform is already done during
 * {@link decryptRemoteFile}; this is only for handling potentially items that
 * might've been already present locally.
 *
 * Part 2 ---
 *
 * Remove unused fields from the file objects when reading them.
 *
 * This is similar to the transformation we perform when reading collections
 * from the database, to discard fields that are no longer forwarded when we
 * parse the remote object, and thus will not be present in the local DB either
 * when going forward. They might be present for the existing entries in DB
 * though, which is why these functions are needed.
 *
 * However, since unlike collections, we don't route the files through Zod when
 * reading. So instead we do it using this function. Effectively, the end result
 * should be the same. In any case, doing this cleanup has no functional impact.
 *
 * Both parts added June 2025, 1.7.14-beta, prune eventually (tag: Migration).
 */
export const transformFilesIfNeeded = (files: EnteFile[]) =>
    isFilesTransformNeeded(files) ? files.map(transformFile) : files;

// Preflight check to turn the potentially non-trivial overhead (~50ms for 200k
// files if everything runs through transformFile) into an effective no-op
// (2-3ms) for the majority happy paths which don't need any transform.
const isFilesTransformNeeded = (
    files: (EnteFile & { isDeleted?: unknown })[],
) =>
    !!files.find(
        (file) =>
            "isDeleted" in file ||
            !file.metadata.modificationTime ||
            typeof file.metadata.fileType != "number",
    );

const transformFile = (file: EnteFile & { isDeleted?: unknown }) => {
    const {
        isDeleted,
        metadata: origMetadata,
        magicMetadata,
        pubMagicMetadata,
        ...rest
    } = file;
    ignore(isDeleted);
    // We live with the cast here since this migration code should eventually be
    // removed. The cast is needed because in the original context,
    // transformDecryptedMetadataJSON acts on arbitrary JSON objects that have
    // not yet been validated to be of type FileMetadata.
    const metadata = transformDecryptedMetadataJSON(
        file.id,
        origMetadata,
    ) as FileMetadata;
    if (magicMetadata) {
        delete (magicMetadata as MagicMetadata & { header?: unknown }).header;
    }
    if (pubMagicMetadata) {
        delete (pubMagicMetadata as MagicMetadata & { header?: unknown })
            .header;
    }
    return {
        ...rest,
        metadata,
        magicMetadata,
        pubMagicMetadata,
    } satisfies EnteFile;
};

/**
 * A convenience Zod schema for a nullish number, with `null`s being transformed
 * to `undefined`.
 *
 * This is convenient when parsing the various timestamps we keep corresponding
 * to top level keys in the files DB. Don't use elsewhere!
 */
export const LocalTimestamp = z.number().nullish().transform(nullToUndefined);
