import type { EnteFile, RemoteEnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";
import localForage from "ente-shared/storage/localForage";

export interface TrashItem extends Omit<EncryptedTrashItem, "file"> {
    file: EnteFile;
}

export interface EncryptedTrashItem {
    file: RemoteEnteFile;
    /**
     * `true` if the file no longer in trash because it was permanently deleted.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was permanently deleted.
     */
    isDeleted: boolean;
    /**
     * `true` if the file no longer in trash because it was restored to some
     * collection.
     *
     * This field is relevant when we obtain a trash item as part of the trash
     * diff. It indicates that the file which was previously in trash is no
     * longer in the trash because it was restored to a collection.
     */
    isRestored: boolean;
    deleteBy: number;
    createdAt: number;
    updatedAt: number;
}

export type Trash = TrashItem[];

export const TRASH = "file-trash";

export async function getLocalTrash() {
    const trash = (await localForage.getItem<Trash>(TRASH)) ?? [];
    return trash;
}

export async function getLocalTrashedFiles() {
    return getTrashedFiles(await getLocalTrash());
}

/**
 * A file augmented with the date when it will be permanently deleted.
 */
export type EnteTrashFile = EnteFile & {
    /**
     * Timestamp (epoch microseconds) when this file, which is already in trash,
     * will be permanently deleted.
     *
     * On being deleted by the user, files move to trash, will be permanently
     * deleted after 30 days of being moved to trash)
     */
    deleteBy?: number;
};

export const getTrashedFiles = (trash: Trash): EnteTrashFile[] =>
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
 * Return the IDs of all the files that are part of the trash as per our local
 * database.
 */
export const getLocalTrashFileIDs = () =>
    getLocalTrash().then((trash) => new Set(trash.map((f) => f.file.id)));
