import { RemoteEnteFile, type EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import { z } from "zod/v4";
import { savedTrashItems } from "./photos-fdb";

/**
 * A trash item indicates a file in trash.
 *
 * On being deleted by the user, files move to trash, and gain this associated
 * trash item, which we can fetch with correspoding diff APIs etc. Files will be
 * permanently deleted after 30 days of being moved to trash, but can be
 * restored or permanently deleted before that by explicit user action.
 *
 * See: [Note: File lifecycle]
 */
export interface TrashItem {
    file: EnteFile;
    /**
     * Timestamp (epoch microseconds) when the trash entry was last updated.
     */
    updatedAt: number;
    /**
     * Timestamp (epoch microseconds) when the file will be permanently deleted.
     */
    deleteBy: number;
}

/**
 * Zod schema for a trash item that we receive from remote.
 */
const RemoteTrashItem = z.looseObject({
    file: RemoteEnteFile,
    /**
     * `true` if the file no longer in trash because it was permanently deleted.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was permanently deleted.
     */
    isDeleted: z.boolean(),
    /**
     * `true` if the file no longer in trash because it was restored to some
     * collection.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was restored to a collection.
     */
    isRestored: z.boolean(),
    updatedAt: z.number(),
    deleteBy: z.number(),
});

export type RemoteTrashItem = z.infer<typeof RemoteTrashItem>;

export async function getLocalTrashedFiles() {
    return getTrashedFiles(await savedTrashItems());
}

/**
 * A file augmented with the date when it will be permanently deleted.
 */
export type EnteTrashFile = EnteFile & {
    /**
     * Timestamp (epoch microseconds) when this file, which is already in trash,
     * will be permanently deleted.

     */
    deleteBy?: number;
};

export const getTrashedFiles = (trash: TrashItem[]): EnteTrashFile[] =>
    sortTrashFiles(
        trash.map(({ file, updatedAt, deleteBy }) => ({
            ...file,
            updationTime: updatedAt,
            deleteBy,
        })),
    );

const sortTrashFiles = (files: EnteTrashFile[]) =>
    files.sort((a, b) => {
        if (a.deleteBy === b.deleteBy) {
            const at = fileCreationTime(a);
            const bt = fileCreationTime(b);
            return at == bt
                ? b.metadata.modificationTime - a.metadata.modificationTime
                : bt - at;
        }
        return (a.deleteBy ?? 0) - (b.deleteBy ?? 0);
    });

/**
 * Return the IDs of all the files that are part of the trash in our local
 * database.
 */
export const getLocalTrashFileIDs = () =>
    savedTrashItems().then((items) => new Set(items.map((f) => f.file.id)));
