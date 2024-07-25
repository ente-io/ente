import localForage from "@ente/shared/storage/localForage";
import { type EnteFile, type Trash } from "../types/file";
import { mergeMetadata } from "../utils/file";

const FILES_TABLE = "files";
const HIDDEN_FILES_TABLE = "hidden-files";

/**
 * Return all files that we know about locally, both "normal" and "hidden".
 */
export const getAllLocalFiles = async () =>
    (await getLocalFiles("normal")).concat(await getLocalFiles("hidden"));

/**
 * Return all files that we know about locally. By default it returns only
 * "normal" (i.e. non-"hidden") files, but it can be passed the {@link type}
 * "hidden" to get it to instead return hidden files that we know about locally.
 */
export const getLocalFiles = async (type: "normal" | "hidden" = "normal") => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    const files: EnteFile[] =
        (await localForage.getItem<EnteFile[]>(tableName)) ?? [];
    return files;
};

/**
 * Update the files that we know about locally.
 *
 * Sibling of {@link getLocalFiles}.
 */
export const setLocalFiles = async (
    type: "normal" | "hidden",
    files: EnteFile[],
) => {
    const tableName = type === "normal" ? FILES_TABLE : HIDDEN_FILES_TABLE;
    await localForage.setItem(tableName, files);
};

export const TRASH = "file-trash";

export async function getLocalTrash() {
    const trash = (await localForage.getItem<Trash>(TRASH)) ?? [];
    return trash;
}

export async function getLocalTrashedFiles() {
    return getTrashedFiles(await getLocalTrash());
}

export function getTrashedFiles(trash: Trash): EnteFile[] {
    return sortTrashFiles(
        mergeMetadata(
            trash.map((trashedFile) => ({
                ...trashedFile.file,
                updationTime: trashedFile.updatedAt,
                deleteBy: trashedFile.deleteBy,
                isTrashed: true,
            })),
        ),
    );
}

const sortTrashFiles = (files: EnteFile[]) => {
    return files.sort((a, b) => {
        if (a.deleteBy === b.deleteBy) {
            if (a.metadata.creationTime === b.metadata.creationTime) {
                return (
                    b.metadata.modificationTime - a.metadata.modificationTime
                );
            }
            return b.metadata.creationTime - a.metadata.creationTime;
        }
        return (a.deleteBy ?? 0) - (b.deleteBy ?? 0);
    });
};
