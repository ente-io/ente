import { blobCache } from "@/base/blob-cache";
import { mergeMetadata, type EnteFile, type Trash } from "@/media/file";
import { FileType } from "@/media/file-type";
import localForage from "@ente/shared/storage/localForage";

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

/**
 * Sort the given list of {@link EnteFile}s in place.
 *
 * Like the JavaScript Array#sort, this method modifies the {@link files}
 * argument. It sorts {@link files} in place, and then returns a reference to
 * the same mutated array.
 *
 * By default, files are sorted so that the newest one is first. The optional
 * {@link sortAsc} flag can be set to `true` to sort them so that the oldest one
 * is first.
 */
export const sortFiles = (files: EnteFile[], sortAsc = false) => {
    // Sort based on the time of creation time of the file.
    //
    // For files with same creation time, sort based on the time of last
    // modification.
    const factor = sortAsc ? -1 : 1;
    return files.sort((a, b) => {
        if (a.metadata.creationTime === b.metadata.creationTime) {
            return (
                factor *
                (b.metadata.modificationTime - a.metadata.modificationTime)
            );
        }
        return factor * (b.metadata.creationTime - a.metadata.creationTime);
    });
};

/**
 * File IDs themselves are unique across all the files for the user (in fact,
 * they're unique across all the files in an Ente instance). However, we still
 * can have multiple entries for the same file ID in our local database because
 * the unit of account is not actually a file, but a "Collection File": a
 * collection and file pair.
 *
 * For example, if the same file is symlinked into two collections, then we will
 * have two "Collection File" entries for it, both with the same file ID, but
 * with different collection IDs.
 *
 * This function returns files such that only one of these entries (the newer
 * one in case of dupes) is returned.
 */
export const uniqueFilesByID = (files: EnteFile[]) => {
    const seen = new Set<number>();
    return files.filter(({ id }) => {
        if (seen.has(id)) return false;
        seen.add(id);
        return true;
    });
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
