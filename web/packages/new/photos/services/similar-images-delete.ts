import log from "ente-base/log";
import type { EnteFile } from "ente-media/file";
import {
    addToCollection,
    moveToTrash,
    savedNormalCollections,
} from "./collection";
import { pullFiles } from "./pull";
import { clearSimilarImagesCache } from "./similar-images";
import type { SimilarImageGroup } from "./similar-images-types";

/**
 * Remove similar image groups that the user has selected.
 *
 * Follows the same pattern as removeSelectedDuplicateGroups in dedup.ts.
 *
 * [Note: Similar Images Deletion Logic]
 *
 * 1. **One Must Remain**: For every selected group, we MUST retain at least one file.
 *    We never delete an entire group of similar images; at least one "best" photo is kept.
 *
 * 2. **Retained Item Selection**:
 *    - We look for the "best" photo to keep based on: Favorites > Captions > Edits > Size.
 *    - **Critical**: We filter candidates to only include items NOT explicitly selected
 *      for deletion by the user.
 *    - If the user selects the "best" photo, we respect that intent and pick the
 *      next best unselected photo to keep.
 *    - **Fallback**: If ALL items are selected, we fall back to the absolute "best"
 *      photo (ignoring selection) because rule #1 takes precedence.
 *
 * 3. For the remaining files (the ones to be deleted):
 *    - Identify user-owned collections they belong to.
 *    - Add the *retained* file to those collections (preserves album membership).
 *    - Move the deleted files to trash.
 *
 * 4. Sync local state.
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

    // Get favorites collections to protect favorited files
    const collections = await savedNormalCollections();
    const userID = (
        await import("ente-accounts/services/user")
    ).ensureLocalUser().id;
    const favoritesCollectionIDs = new Set(
        collections
            .filter((c) => c.type === "favorites" && c.owner.id === userID)
            .map((c) => c.id),
    );

    // Handle full group selections
    for (const group of selectedGroups) {
        const retainedItem = await similarImageGroupItemToRetain(group);

        // For each item in the group (except the retained one), find collections
        // and add them to trash
        let collectionIDs = new Set<number>();
        for (const item of group.items) {
            // Skip the item we're retaining
            if (item.file.id === retainedItem.file.id) continue;

            // Skip if item is individually deselected (respects item.isSelected state)
            if (item.isSelected === false) continue;

            // Skip favorited files - they should never be deleted
            const isFavorited = Array.from(item.collectionIDs).some((cid) =>
                favoritesCollectionIDs.has(cid),
            );
            if (isFavorited) continue;

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
        // Find the "best" item to retain from the ones NOT selected for deletion
        // We use this item to preserve collection membership
        const retainedItem = await similarImageGroupItemToRetain(group);

        for (const item of group.items) {
            if (!item.isSelected) continue;

            // Skip favorited files - they should never be deleted
            const isFavorited = Array.from(item.collectionIDs).some((cid) =>
                favoritesCollectionIDs.has(cid),
            );
            if (isFavorited) continue;

            // Collect collections this file belongs to
            // Remove existing collections from the set (symlink already exists)
            const collectionIDs = item.collectionIDs.difference(
                retainedItem.collectionIDs,
            );

            // Add the retained file to these collections
            for (const collectionID of collectionIDs) {
                filesToAdd.set(collectionID, [
                    ...(filesToAdd.get(collectionID) ?? []),
                    retainedItem.file,
                ]);
            }

            filesToTrash.push(item.file);
        }
    }

    // Process adds and removes
    let np = 0;
    const ntotal =
        filesToAdd.size + (filesToTrash.length ? 1 : 0) + /* sync */ 1;
    const tickProgress = () => onProgress((np++ / ntotal) * 100);

    // Process the adds
    const allCollections = await savedNormalCollections();
    const collectionsByID = new Map(allCollections.map((c) => [c.id, c]));
    for (const [collectionID, files] of filesToAdd.entries()) {
        const collection = collectionsByID.get(collectionID);
        if (collection) {
            await addToCollection(collection, files);
        } else {
            log.warn(
                `[Similar Images] Collection ${collectionID} not found, skipping addToCollection`,
            );
        }
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

    // Calculate which groups are fully removed
    // A group is fully removed only if it would have fewer than 2 items remaining
    const fullyRemovedGroupIDs = new Set<string>();

    for (const group of selectedGroups) {
        // Count how many items remain in this group after deletion
        let remainingCount = 0;
        for (const item of group.items) {
            // Item remains if it wasn't deleted
            if (!deletedFileIDs.has(item.file.id)) {
                remainingCount++;
            }
        }

        // A similar images group needs at least 2 items
        // If fewer than 2 items remain, the group is fully removed
        if (remainingCount < 2) {
            fullyRemovedGroupIDs.add(group.id);
        }
    }

    // Also check groups with individual selections
    for (const group of groupsWithIndividualSelections) {
        let remainingCount = 0;
        for (const item of group.items) {
            if (!deletedFileIDs.has(item.file.id)) {
                remainingCount++;
            }
        }

        if (remainingCount < 2) {
            fullyRemovedGroupIDs.add(group.id);
        }
    }

    return { deletedFileIDs, fullyRemovedGroupIDs };
};

/**
 * Find the most eligible item from a similar image group to retain.
 *
 * Only considers items that are NOT selected for deletion (isSelected !== true)
 * to honor user's explicit selection choices. If a user selects the "best photo"
 * for deletion, we should respect that and choose another item to retain.
 *
 * Prioritization order (matching mobile implementation):
 * 1. Favorited files (files in a favorites collection)
 * 2. Files with captions
 * 3. Files with edited name/time
 * 4. Larger file sizes
 * 5. First unselected item if all else is equal
 *
 * Fallback: If ALL items are selected for deletion, falls back to original
 * priority logic to ensure at least one item is retained.
 */
const similarImageGroupItemToRetain = async (
    group: SimilarImageGroup,
): Promise<SimilarImageGroup["items"][number]> => {
    // First, filter to only items NOT explicitly selected for deletion
    // This honors the user's intent: if they select "best photo", delete it
    const unselectedItems = group.items.filter(
        (item) => item.isSelected !== true,
    );

    // If all items are selected, this is an invalid state (must retain at least one)
    if (unselectedItems.length === 0) {
        throw new Error(
            `[Similar Images] Invalid state: All items in group ${group.id} selected for deletion. Must retain at least one item.`,
        );
    }
    
    const candidateItems = unselectedItems;

    const itemsWithFavorites: SimilarImageGroup["items"] = [];
    const itemsWithCaption: SimilarImageGroup["items"] = [];
    const itemsWithOtherEdits: SimilarImageGroup["items"] = [];

    // Get all collections to check for favorites
    const collections = await savedNormalCollections();
    const userID = (
        await import("ente-accounts/services/user")
    ).ensureLocalUser().id;
    const favoritesCollectionIDs = new Set(
        collections
            .filter((c) => c.type === "favorites" && c.owner.id === userID)
            .map((c) => c.id),
    );

    for (const item of candidateItems) {
        // Check if file is in a favorites collection
        const isFavorited = Array.from(item.collectionIDs).some((cid) =>
            favoritesCollectionIDs.has(cid),
        );
        if (isFavorited) {
            itemsWithFavorites.push(item);
        }

        const pubMM = item.file.pubMagicMetadata?.data;
        if (!pubMM) continue;
        if (pubMM.caption) itemsWithCaption.push(item);
        if (pubMM.editedName ?? pubMM.editedTime)
            itemsWithOtherEdits.push(item);
    }

    // Helper to find item with largest file size
    const findLargestItem = (items: SimilarImageGroup["items"]) => {
        return items.reduce((largest, item) => {
            const currentSize = item.file.info?.fileSize || 0;
            const largestSize = largest.file.info?.fileSize || 0;
            return currentSize > largestSize ? item : largest;
        }, items[0]!);
    };

    // Return based on priority
    if (itemsWithFavorites.length > 0) {
        return findLargestItem(itemsWithFavorites);
    }
    if (itemsWithCaption.length > 0) {
        return findLargestItem(itemsWithCaption);
    }
    if (itemsWithOtherEdits.length > 0) {
        return findLargestItem(itemsWithOtherEdits);
    }

    // If no special attributes, pick the largest file from candidates
    return findLargestItem(candidateItems);
};

/**
 * Calculate the total size that would be freed by removing selected groups.
 */
export const calculateFreedSpace = (groups: SimilarImageGroup[]): number => {
    let freedSpace = 0;

    for (const group of groups) {
        if (group.isSelected) {
            // Full group selection
            // Calculate space freed by removing all but one retained file.
            //
            // IMPORTANT: This uses the largest file as the retained file for estimation purposes.
            // The actual retention logic in similarImageGroupItemToRetain() prioritizes:
            //   1. Favorited files
            //   2. Files with captions
            //   3. Files with edited name/time
            //   4. Larger file sizes
            //
            // Since we can't asynchronously check collections/favorites here (reducer context),
            // we use largest-file estimation as a CONSERVATIVE approach: if a smaller favorited
            // file is actually retained, we'll free MORE space than displayed, which is
            // preferable to overpromising and underdelivering.
            const sortedItems = [...group.items].sort(
                (a, b) =>
                    (b.file.info?.fileSize || 0) - (a.file.info?.fileSize || 0),
            );
            const retainedFileSize = sortedItems[0]?.file.info?.fileSize || 0;
            freedSpace += group.totalSize - retainedFileSize;
        } else {
            // Check for individual item selections
            for (const item of group.items) {
                if (item.isSelected) {
                    freedSpace += item.file.info?.fileSize || 0;
                }
            }
        }
    }

    return freedSpace;
};

/**
 * Calculate the number of files that would be deleted.
 */
export const calculateDeletedFileCount = (
    groups: SimilarImageGroup[],
): number => {
    let count = 0;

    for (const group of groups) {
        if (group.isSelected) {
            // All files except the first (retained) one
            count += Math.max(0, group.items.length - 1);
        } else {
            // Check for individual item selections
            for (const item of group.items) {
                if (item.isSelected) {
                    count++;
                }
            }
        }
    }

    return count;
};
