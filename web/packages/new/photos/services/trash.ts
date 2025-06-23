import { dateFromEpochMicroseconds } from "ente-base/date";
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

export type TrashedEnteFile = EnteFile & {
    /**
     * `true` if this file is in trash (i.e. it has been deleted by the user,
     * and will be permanently deleted after 30 days of being moved to trash).
     */
    isTrashed?: boolean;
    /**
     * If {@link isTrashed} is `true`, then {@link deleteBy} contains the epoch
     * microseconds when this file will be permanently deleted.
     */
    deleteBy?: number;
};

/**
 * Return the date when the file will be deleted permanently. Only valid for
 * files that are in the user's trash.
 *
 * This is a convenience wrapper over the {@link deleteBy} property of a file,
 * converting that epoch microsecond value into a JavaScript date.
 */
export const enteFileDeletionDate = (file: TrashedEnteFile) =>
    dateFromEpochMicroseconds(file.deleteBy);

export function getTrashedFiles(trash: Trash): TrashedEnteFile[] {
    return sortTrashFiles(
        trash.map((trashedFile) => ({
            ...trashedFile.file,
            updationTime: trashedFile.updatedAt,
            deleteBy: trashedFile.deleteBy,
            isTrashed: true,
        })),
    );
}

const sortTrashFiles = (files: TrashedEnteFile[]) => {
    return files.sort((a, b) => {
        if (a.deleteBy === b.deleteBy) {
            const at = fileCreationTime(a);
            const bt = fileCreationTime(b);
            return at == bt
                ? b.metadata.modificationTime - a.metadata.modificationTime
                : bt - at;
        }
        return (a.deleteBy ?? 0) - (b.deleteBy ?? 0);
    });
};

/**
 * Return the IDs of all the files that are part of the trash as per our local
 * database.
 */
export const getLocalTrashFileIDs = () =>
    getLocalTrash().then((trash) => new Set(trash.map((f) => f.file.id)));
