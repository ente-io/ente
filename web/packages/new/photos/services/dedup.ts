import type { EnteFile } from "@/media/file";
import { createCollectionNameByID } from "./collection";
import { getLocalCollections } from "./collections";
import { getLocalFiles, uniqueFilesByID } from "./files";
import { newID } from "@/base/id";

/**
 * A group of duplicates as shown in the UI.
 */
export interface DuplicateGroup {
    /**
     * A nanoid for this group.
     *
     * This can be used as the key when rendering the group in a list.
     */
    id: string;
    /**
     * Files which our algorithm has determined to be duplicates of each other.
     *
     * These are sorted by the collectionName.
     */
    items: {
        /**
         * The underlying collection file.
         */
        file: EnteFile;
        /**
         * The name of the collection to which this file belongs.
         */
        collectionName: string;
    }[];
    /**
     * The size (in bytes) of each item in the group.
     */
    itemSize: number;
    /**
     * The number of files that will be pruned if the user decides to dedup this
     * group.
     */
    prunableCount: number;
    /**
     * The size (in bytes) that can be saved if the user decides to dedup this
     * group.
     */
    prunableSize: number;
    /**
     * `true` if the user has marked this group for deduping.
     */
    isSelected: boolean;
}

/**
 * Find exact duplicates in the user's library, and return them in groups that
 * can then be deduped keeping only one entry in each group.
 *
 * [Note: Deduplication logic]
 *
 * Detecting duplicates:
 *
 * 1. Identify and divide files into multiple groups based on (size + hash).
 *
 * 2. By default select all group, with option to unselect individual groups or
 *    all groups.
 *
 * Pruning duplicates:
 *
 * When user presses the dedup button with some selected groups,
 *
 * 1. Identify and select the file which we don't want to delete (preferring
 *    file with caption or edited time).
 *
 * 2. For the remaining files identify the collection owned by the user in which
 *    the remaining files are present.
 *
 * 3. Add the file that we don't plan to delete to such collections as a
 *    symlink.
 *
 * 4. Delete the remaining files.
 */
export const deduceDuplicates = async () => {
    const collectionFiles = await getLocalFiles();
    const files = uniqueFilesByID(collectionFiles);

    const filesByHash = new Map<string, EnteFile[]>();
    for (const file of files) {
        let hash = file.metadata.hash;
        if (!hash && file.metadata.imageHash && file.metadata.videoHash)
            hash = `${file.metadata.imageHash}_${file.metadata.hash}`;
        if (!hash) {
            // Some very old files uploaded by ancient versions of Ente might
            // not have hashes. Ignore these.
            continue;
        }

        filesByHash.set(hash, [...(filesByHash.get(hash) ?? []), file]);
    }

    const collectionNameByID = createCollectionNameByID(
        await getLocalCollections(),
    );

    const duplicateGroups: DuplicateGroup[] = [];

    for (const potentialDuplicates of filesByHash.values()) {
        if (potentialDuplicates.length < 2) continue;
        const size = potentialDuplicates[0]?.info?.fileSize;
        if (!size) continue;
        const duplicates = potentialDuplicates.filter(
            (file) => file.info?.fileSize == size,
        );
        const items = duplicates
            .map((file) => {
                const collectionName = collectionNameByID.get(
                    file.collectionID,
                );
                return collectionName ? { file, collectionName } : undefined;
            })
            .filter((item) => !!item);
        if (items.length < 2) continue;
        duplicateGroups.push({
            id: newID("dg_"),
            items,
            itemSize: size,
            prunableCount: duplicates.length - 1,
            prunableSize: size * (duplicates.length - 1),
            isSelected: true,
        });
    }

    return duplicateGroups;
};
