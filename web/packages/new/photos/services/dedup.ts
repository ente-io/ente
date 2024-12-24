import { assertionFailed } from "@/base/assert";
import { newID } from "@/base/id";
import { ensureLocalUser } from "@/base/local-user";
import type { EnteFile } from "@/media/file";
import { metadataHash } from "@/media/file-metadata";
import { wait } from "@/utils/promise";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import { createCollectionNameByID } from "./collection";
import { getLocalCollections } from "./collections";
import { getLocalFiles, uniqueFilesByID } from "./files";

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
 * 1. Identify and divide files into multiple groups based on hash.
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
    // Find the user's ID.
    const userID = ensureLocalUser().id;

    // Find all non-hidden collections owned by the user, and also use that to
    // keep a map of their names (we'll attach this info to the result later).
    const nonHiddenCollections = await getLocalCollections("normal");
    const nonHiddenOwnedCollections = nonHiddenCollections.filter(
        ({ owner }) => owner.id == userID,
    );
    const allowedCollectionIDs = new Set(
        nonHiddenOwnedCollections.map(({ id }) => id),
    );
    const collectionNameByID = createCollectionNameByID(
        nonHiddenOwnedCollections,
    );

    // Final all non-hidden collection files owned by the user that are in a
    // non-hidden owned collection.
    const nonHiddenCollectionFiles = await getLocalFiles("normal");
    const filteredCollectionFiles = nonHiddenCollectionFiles.filter((f) =>
        allowedCollectionIDs.has(f.collectionID),
    );

    // Group the filtered collection files by their hashes.
    const files = uniqueFilesByID(filteredCollectionFiles);
    const filesByHash = new Map<string, EnteFile[]>();
    for (const file of files) {
        const hash = metadataHash(file.metadata);
        if (!hash) {
            // Some very old files uploaded by ancient versions of Ente might
            // not have hashes. Ignore these.
            continue;
        }

        filesByHash.set(hash, [...(filesByHash.get(hash) ?? []), file]);
    }

    // Construct the results from groups that have more than one file with the
    // same hash.
    const duplicateGroups: DuplicateGroup[] = [];

    for (const duplicates of filesByHash.values()) {
        if (duplicates.length < 2) continue;

        // Take the size of any of the items, they should all be the same since
        // the hashes are the same.
        //
        // Note that this is not guaranteed in the case of live photos, since
        // the hash originates from the image and video contents, but the size
        // comes from the size of their combined zip, and different clients
        // might use different zip implementation to arrive at non-exact but
        // similar sizes. The delta should be minor so we can use any of the
        // sizes, this is only meant as a rough UI hint anyway.
        let size = 0;
        for (const file of duplicates) {
            if (file.info?.fileSize) {
                size = file.info.fileSize;
                break;
            }
        }

        // If none of the files marked as duplicates have a size, ignored this
        // group. This shouldn't really happen in practice, but it can happen in
        // rare cases (group of duplicates uploaded by ancient version of Ente
        // which did not attach the file size during uploads).
        if (!size) continue;

        const items = duplicates
            .map((file) => {
                const collectionName = collectionNameByID.get(
                    file.collectionID,
                );
                // Ignore duplicates for which we do not have a collection. This
                // shouldn't really happen though, so retain an assert.
                if (!collectionName) assertionFailed();
                return collectionName ? { file, collectionName } : undefined;
            })
            .filter((item) => !!item);
        if (items.length < 2) continue;

        // Within each duplicate group, keep the files sorted by collection name
        // so that it is easier to scan them at glance.
        items.sort((a, b) => a.collectionName.localeCompare(b.collectionName));

        duplicateGroups.push({
            id: newID("dg_"),
            items,
            itemSize: size,
            prunableCount: items.length - 1,
            prunableSize: size * (items.length - 1),
            isSelected: true,
        });
    }

    return duplicateGroups;
};

/**
 * Remove duplicate groups that the user has retained from those that we
 * returned in {@link deduceDuplicates}.
 *
 * @param duplicateGroups A list of duplicate groups. This is the same list as
 * would've been returned from a previous call to {@link deduceDuplicates},
 * except (a) their sort order might've changed, and (b) the user may have
 * unselected some of them (i.e. isSelected for such items would be `false`).
 *
 * This function will only process entries for which isSelected is `true`.
 */
export const removeSelectedDuplicateGroups = async (
    duplicateGroups: DuplicateGroup[],
) => {
    const selectedDuplicateGroups = duplicateGroups.filter((g) => g.isSelected);
    for (const duplicateGroup of selectedDuplicateGroups) {
        const fileToRetain = duplicateGroupFileToRetain(duplicateGroup);
        console.log({ fileToRetain });
    }
    await wait(3000);
};

/**
 * Find the most eligible file from amongst the duplicates to retain.
 *
 * Give preference to files which have a caption or edited name or edited time,
 * otherwise pick arbitrarily.
 */
const duplicateGroupFileToRetain = (duplicateGroup: DuplicateGroup) => {
    const filesWithCaption: EnteFile[] = [];
    const filesWithOtherEdits: EnteFile[] = [];
    for (const { file } of duplicateGroup.items) {
        const pubMM = getPublicMagicMetadataSync(file);
        if (!pubMM) continue;
        if (pubMM.caption) filesWithCaption.push(file);
        if (pubMM.editedName ?? pubMM.editedTime)
            filesWithOtherEdits.push(file);
    }

    // Duplicate group items should not be empty, so we'll get something always.
    return (
        filesWithCaption[0] ??
        filesWithOtherEdits[0] ??
        duplicateGroup.items[0]!.file
    );
};
