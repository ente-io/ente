import type { EnteFile } from "ente-media/file";
import {
    addToCollection,
    moveToTrash,
    savedNormalCollections,
} from "./collection";
import { clearSimilarImagesCache } from "./similar-images";
import { pullFiles } from "./pull";
import type { SimilarImageGroup } from "./similar-images-types";

/**
 * Remove similar image groups that the user has selected.
 *
 * Follows the same pattern as removeSelectedDuplicateGroups in dedup.ts.
 *
 * [Note: Similar Images Deletion Logic]
 *
 * 1. For each selected group, identify the file to retain (prefer files with
 *    captions or edits).
 * 2. For the remaining files, identify user-owned collections they belong to.
 * 3. Add the retained file to those collections as a symlink.
 * 4. Move the other files to trash.
 * 5. Sync local state.
 *
 * @param similarImageGroups A list of similar image groups with selection state.
 * @param onProgress A function called with progress percentage (0-100).
 * @returns An object containing the IDs of deleted files and fully removed groups.
 */
export const removeSelectedSimilarImageGroups = async (
    similarImageGroups: SimilarImageGroup[],
    onProgress: (progress: number) => void,
): Promise<{
    deletedFileIDs: Set<number>;
    fullyRemovedGroupIDs: Set<string>;
}> => {
    const selectedGroups = similarImageGroups.filter((g) => g.isSelected);
    const groupsWithIndividualSelections = similarImageGroups.filter(
        (g) => !g.isSelected && g.items.some((item) => item.isSelected),
    );

    // Identify files to add to collections and files to trash
    const filesToAdd = new Map<number, EnteFile[]>();
    const filesToTrash: EnteFile[] = [];

    // Handle full group selections
    for (const group of selectedGroups) {
        const retainedItem = similarImageGroupItemToRetain(group);

        // For each item in the group (except the retained one), find collections
        // and add them to trash
        let collectionIDs = new Set<number>();
        for (const item of group.items) {
            // Skip the item we're retaining
            if (item.file.id === retainedItem.file.id) continue;

            // Collect all collection IDs this file belongs to
            collectionIDs = collectionIDs.union(item.collectionIDs);

            // Move the file to trash
            filesToTrash.push(item.file);
        }

        // Remove existing collections from the set (symlink already exists)
        collectionIDs = collectionIDs.difference(retainedItem.collectionIDs);

        // Add the retained file to these collections
        for (const collectionID of collectionIDs) {
            filesToAdd.set(collectionID, [
                ...(filesToAdd.get(collectionID) ?? []),
                retainedItem.file,
            ]);
        }
    }

    // Handle individual item selections
    for (const group of groupsWithIndividualSelections) {
        for (const item of group.items) {
            if (!item.isSelected) continue;

            // Simply move individually selected items to trash
            // No symlink creation needed since we're not retaining anything
            filesToTrash.push(item.file);
        }
    }

    // Process adds and removes
    let np = 0;
    const ntotal =
        filesToAdd.size +
        (filesToTrash.length ? 1 : 0) +
        /* sync */ 1;
    const tickProgress = () => onProgress((np++ / ntotal) * 100);

    // Process the adds
    const collections = await savedNormalCollections();
    const collectionsByID = new Map(collections.map((c) => [c.id, c]));
    for (const [collectionID, files] of filesToAdd.entries()) {
        await addToCollection(collectionsByID.get(collectionID)!, files);
        tickProgress();
    }

    // Process the removes
    if (filesToTrash.length) {
        await moveToTrash(filesToTrash);
        tickProgress();
    }

    // Sync local state
    await pullFiles();
    tickProgress();

    // Clear the similar images cache since files were deleted
    await clearSimilarImagesCache();

    // Return IDs of deleted files so UI can update
    const deletedFileIDs = new Set(filesToTrash.map((f) => f.id));
    const fullyRemovedGroupIDs = new Set(selectedGroups.map((g) => g.id));

    return { deletedFileIDs, fullyRemovedGroupIDs };
};

/**
 * Find the most eligible item from a similar image group to retain.
 *
 * Give preference to files which have a caption or edited name/time,
 * otherwise pick arbitrarily.
 */
const similarImageGroupItemToRetain = (
    group: SimilarImageGroup,
): SimilarImageGroup["items"][number] => {
    const itemsWithCaption: SimilarImageGroup["items"] = [];
    const itemsWithOtherEdits: SimilarImageGroup["items"] = [];

    for (const item of group.items) {
        const pubMM = item.file.pubMagicMetadata?.data;
        if (!pubMM) continue;
        if (pubMM.caption) itemsWithCaption.push(item);
        if (pubMM.editedName ?? pubMM.editedTime)
            itemsWithOtherEdits.push(item);
    }

    // Return the first item with a caption, or first with edits, or first item
    return itemsWithCaption[0] ?? itemsWithOtherEdits[0] ?? group.items[0]!;
};

/**
 * Calculate the total size that would be freed by removing selected groups.
 */
export const calculateFreedSpace = (
    groups: SimilarImageGroup[],
): number => {
    let freedSpace = 0;

    for (const group of groups) {
        if (!group.isSelected) continue;

        // Calculate space freed by removing all but the first (retained) file
        const retainedFileSize = group.items[0]?.file.info?.fileSize || 0;
        freedSpace += group.totalSize - retainedFileSize;
    }

    return freedSpace;
};

/**
 * Calculate the number of files that would be deleted.
 */
export const calculateDeletedFileCount = (groups: SimilarImageGroup[]): number => {
    let count = 0;

    for (const group of groups) {
        if (!group.isSelected) continue;
        // All files except the first (retained) one
        count += Math.max(0, group.items.length - 1);
    }

    return count;
};
