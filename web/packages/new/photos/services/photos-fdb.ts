/**
 * @file Photos app specific files DB. See: [Note: Files DB].
 */

import {
    LocalCollections,
    LocalEnteFile,
    LocalTimestamp,
    transformFilesIfNeeded,
} from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import localForage from "ente-shared/storage/localForage";
import { z } from "zod/v4";
import type { TrashItem } from "./trash";

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
export const saveCollections = async (collections: Collection[]) => {
    await localForage.setItem("collections", collections);
};

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
export const saveTrashItemCollectionKeys = async (
    cks: TrashItemCollectionKey[],
) => {
    await localForage.setItem("deleted-collection", cks);
};

/**
 * Return all files present in our local database.
 *
 * This includes both normal (non-hidden) and hidden files. If you're interested
 * only in one type (normal or hidden), then it is more efficient to use
 * {@link savedNormalFiles} or {@link savedHiddenFiles} to obtain them; this
 * method is only a convenience to concatenate the two.
 */
export const savedFiles = async (): Promise<EnteFile[]> =>
    Promise.all([savedNormalFiles(), savedHiddenFiles()]).then((f) => f.flat());

/**
 * Return all normal (non-hidden) files present in our local database.
 *
 * Use {@link saveNormalFiles} to update the database.
 */
export const savedNormalFiles = async (): Promise<EnteFile[]> =>
    // [Note: Avoiding Zod parsing for large DB arrays]
    //
    // Zod can be used to validate that the value we read from the DB is indeed
    // the same as the type we expect, but for potentially very large arrays,
    // this has an overhead that is perhaps not justified when dealing with DB
    // entries we ourselves wrote.
    //
    // For example (as a non-rigorous benchmark) parsing 200k files took one
    // second. Zod is fast, just that these arrays are big and might be accessed
    // frequently, and the schemas are, while not too complicated, non-trivial.
    //
    // As an optimization, we skip the runtime check here and cast. This might
    // not be the most optimal choice in the future, so (a) use it sparingly,
    // and (b) mark all such cases with the title of this note.
    transformFilesIfNeeded(
        (await localForage.getItem<EnteFile[]>("files")) ?? [],
    );

/**
 * Replace the list of files stored in our local database.
 *
 * This is the setter corresponding to {@link savedNormalFiles}.
 */
export const saveNormalFiles = async (files: EnteFile[]) => {
    await localForage.setItem("files", transformFilesIfNeeded(files));
};

/**
 * Return all hidden files present in our local database.
 *
 * Use {@link saveNormalFiles} to update the database.
 */
export const savedHiddenFiles = async (): Promise<EnteFile[]> =>
    // See: [Note: Avoiding Zod parsing for large DB arrays]
    transformFilesIfNeeded(
        (await localForage.getItem<EnteFile[]>("hidden-files")) ?? [],
    );

/**
 * Replace the list of files stored in our local database.
 *
 * This is the setter corresponding to {@link savedNormalFiles}.
 */
export const saveHiddenFiles = async (files: EnteFile[]) => {
    await localForage.setItem("hidden-files", transformFilesIfNeeded(files));
};

/**
 * Zod schema for a trash entry saved in our local database.
 */
const LocalTrashItem = z.looseObject({
    file: LocalEnteFile,
    updatedAt: z.number(),
    deleteBy: z.number(),
});

/**
 * Return all trash entries present in our local database.
 *
 * Use {@link saveTrashItems} to update the database
 */
export const savedTrashItems = async (): Promise<TrashItem[]> =>
    LocalTrashItem.array().parse(
        (await localForage.getItem("file-trash")) ?? [],
    );

/**
 * Replace the list of trash items stored in our local database.
 *
 * This is the setter corresponding to {@link savedTrashItems}.
 */
export const saveTrashItems = async (trashItems: TrashItem[]) => {
    await localForage.setItem("file-trash", trashItems);
};

/**
 * Return the updatedAt of the latest trash items we have obtained from remote.
 *
 * Use {@link saveTrashLastUpdatedAt} to update the database.
 */
export const savedTrashLastUpdatedAt = async (): Promise<number | undefined> =>
    LocalTimestamp.parse(await localForage.getItem("trash-time"));

/**
 * Update the updatedAt of the latest trash items we have obtained from remote.
 *
 * This is the setter corresponding to {@link savedTrashLastUpdatedAt}.
 */
export const saveTrashLastUpdatedAt = async (updatedAt: number) => {
    await localForage.setItem("trash-time", updatedAt);
};
