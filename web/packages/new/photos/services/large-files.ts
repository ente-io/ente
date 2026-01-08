import { ensureLocalUser } from "ente-accounts/services/user";
import { newID } from "ente-base/id";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import {
    createCollectionNameByID,
    moveToTrash,
    savedNormalCollections,
} from "./collection";
import { savedCollectionFiles } from "./photos-fdb";
import { pullFiles } from "./pull";

/**
 * Minimum file size (in bytes) to be considered a "large" file.
 *
 * This matches the mobile implementation: 10 MB.
 */
export const MIN_LARGE_FILE_SIZE = 10 * 1024 * 1024;

/**
 * Filter type for large files.
 */
export type LargeFileFilter = "all" | "photos" | "videos";

/**
 * A large file as shown in the UI.
 */
export interface LargeFileItem {
    /**
     * A nanoid for this item.
     *
     * This can be used as the key when rendering the item in a list.
     */
    id: string;
    /**
     * The underlying file.
     */
    file: EnteFile;
    /**
     * The size of the file in bytes.
     */
    size: number;
    /**
     * The name of the collection to which this file belongs.
     */
    collectionName: string;
    /**
     * `true` if the user has marked this item for deletion.
     */
    isSelected: boolean;
}

/**
 * Find files larger than {@link MIN_LARGE_FILE_SIZE} in the user's library.
 *
 * @param filter The type of files to include (all, photos, or videos).
 *
 * @returns An array of {@link LargeFileItem} sorted by file size (descending).
 */
export const findLargeFiles = async (
    filter: LargeFileFilter,
): Promise<LargeFileItem[]> => {
    const userID = ensureLocalUser().id;

    // Get collections and create a name lookup map.
    const normalCollections = await savedNormalCollections();
    const normalOwnedCollections = normalCollections.filter(
        ({ owner }) => owner.id == userID,
    );
    const allowedCollectionIDs = new Set(
        normalOwnedCollections.map(({ id }) => id),
    );
    const collectionNameByID = createCollectionNameByID(normalOwnedCollections);

    // Get all collection files.
    const collectionFiles = await savedCollectionFiles();

    // Track files we've already added (by file ID) to avoid duplicates
    // when the same file exists in multiple collections.
    const seenFileIDs = new Set<number>();
    const largeFiles: LargeFileItem[] = [];

    for (const file of collectionFiles) {
        // Skip files not in allowed collections.
        if (!allowedCollectionIDs.has(file.collectionID)) continue;

        // Skip files not owned by the user.
        if (file.ownerID != userID) continue;

        // Skip files already processed (same file in different collection).
        if (seenFileIDs.has(file.id)) continue;

        // Get file size.
        const size = file.info?.fileSize;
        if (!size || size < MIN_LARGE_FILE_SIZE) continue;

        // Apply filter.
        if (!matchesFilter(file, filter)) continue;

        seenFileIDs.add(file.id);

        const collectionName = collectionNameByID.get(file.collectionID) ?? "";

        largeFiles.push({
            id: newID("lf_"),
            file,
            size,
            collectionName,
            isSelected: false,
        });
    }

    // Sort by size descending (largest first).
    largeFiles.sort((a, b) => b.size - a.size);

    return largeFiles;
};

/**
 * Check if a file matches the given filter.
 */
const matchesFilter = (file: EnteFile, filter: LargeFileFilter): boolean => {
    switch (filter) {
        case "all":
            return true;
        case "photos":
            return (
                file.metadata.fileType === FileType.image ||
                file.metadata.fileType === FileType.livePhoto
            );
        case "videos":
            return file.metadata.fileType === FileType.video;
    }
};

/**
 * Delete selected large files by moving them to trash.
 *
 * @param largeFiles The list of large file items.
 * @param onProgress A function called with progress percentage (0-100).
 *
 * @returns A set of IDs of the items that were deleted.
 */
export const deleteSelectedLargeFiles = async (
    largeFiles: LargeFileItem[],
    onProgress: (progress: number) => void,
): Promise<Set<string>> => {
    const selectedItems = largeFiles.filter((item) => item.isSelected);
    const filesToTrash = selectedItems.map((item) => item.file);

    if (filesToTrash.length === 0) {
        return new Set();
    }

    let np = 0;
    const ntotal = 2; // trash + sync
    const tickProgress = () => onProgress((np++ / ntotal) * 100);

    // Move files to trash.
    await moveToTrash(filesToTrash);
    tickProgress();

    // Sync local state.
    await pullFiles();
    tickProgress();

    return new Set(selectedItems.map((item) => item.id));
};
