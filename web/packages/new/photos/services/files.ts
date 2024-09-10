import { blobCache } from "@/base/blob-cache";
import { FileType } from "@/media/file-type";
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

/**
 * Clear cached thumbnails for existing files if the thumbnail data has changed.
 *
 * This function in expected to be called when we are processing a collection
 * diff, updating our local state to reflect files that were updated on remote.
 * We use this as an opportune moment to invalidate any cached thumbnails which
 * have changed.
 *
 * An example of when such invalidation is necessary:
 *
 * 1. Take a photo on mobile, and let it sync via the mobile app to us (web).
 * 2. Edit the photo outside of Ente (e.g. using Apple Photos).
 * 3. When the Ente mobile client next comes into foreground, it'll update the
 *    remote thumbnail for the existing file to reflect the changes.
 *
 * @param existingFiles The {@link EnteFile}s we had in our local database
 * before processing the diff response.
 *
 * @param newFiles The {@link EnteFile}s which we got in the diff response.
 */
export const clearCachedThumbnailsIfChanged = async (
    existingFiles: EnteFile[],
    newFiles: EnteFile[],
) => {
    if (newFiles.length == 0) {
        // Fastpath to no-op if nothing changes.
        return;
    }

    // TODO: This should be constructed once, at the caller (currently the
    // caller doesn't need this, but we'll only know for sure after we
    // consolidate all processing that happens during a diff parse).
    const existingFileByID = new Map(existingFiles.map((f) => [f.id, f]));

    for (const newFile of newFiles) {
        const existingFile = existingFileByID.get(newFile.id);
        const m1 = existingFile?.metadata;
        const m2 = newFile.metadata;
        // TODO: Add an extra truthy check the EnteFile type is null safe
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (!m1 || !m2) continue;
        // Both files exist, have metadata, but their (appropriate) hashes
        // differ, which indicates that the change was in the file's contents,
        // not the metadata itself, and thus we should refresh the thumbnail.
        if (
            m1.fileType == FileType.livePhoto
                ? m1.imageHash != m2.imageHash
                : m1.hash != m2.hash
        ) {
            // This is an infrequent occurrence, so we lazily get the cache.
            const thumbnailCache = await blobCache("thumbs");
            const key = newFile.id.toString();
            await thumbnailCache.delete(key);
        }
    }
};
