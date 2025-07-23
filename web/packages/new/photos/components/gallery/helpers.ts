/**
 * @file code that really belongs to pages/gallery.tsx itself, but it written
 * here in a separate file so that we can write in this package that has
 * TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 *
 * Separate from index.tsx so that it can export non-(React-)components, which
 * is a needed for fast refresh to work.
 */

import { getUserRecoveryKey } from "ente-accounts/services/recovery-key";
import log from "ente-base/log";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { type CollectionOp } from "ente-new/photos/components/SelectedFileOptions";
import {
    addToCollection,
    moveFromCollection,
    moveToCollection,
    restoreToCollection,
} from "ente-new/photos/services/collection";
import { createUncategorizedCollection } from "../../services/collection";
import { PseudoCollectionID } from "../../services/collection-summary";

/**
 * Ensure that the keys in local storage are not malformed by verifying that the
 * recoveryKey can be decrypted with the masterKey.
 *
 * This is not meant to be bullet proof, but more like an extra sanity check.
 *
 * @returns `true` if the sanity check passed, otherwise `false`. Since failure
 * is not expected, the caller should {@link logout} on `false` to avoid
 * continuing with an unexpected local state.
 */
export const validateKey = async () => {
    try {
        await getUserRecoveryKey();
        return true;
    } catch (e) {
        log.warn("Failed to validate key" /*, caller will logout */, e);
        return false;
    }
};

/**
 * Return the {@link Collection} (from amongst {@link collections}) with the
 * given {@link collectionSummaryID}.
 *
 * As a special case, if the given {@link collectionSummaryID} is the ID of the
 * placeholder uncategorized collection, create a new uncategorized collection
 * and then return it.
 *
 * This is used in the context of the collection summary, so one of the two
 * cases must be true.
 */
export const findCollectionCreatingUncategorizedIfNeeded = async (
    collections: Collection[],
    collectionSummaryID: number,
): Promise<Collection> =>
    collectionSummaryID == PseudoCollectionID.uncategorizedPlaceholder
        ? createUncategorizedCollection()
        : // Null assert since the collection selector should only
          // show "selectable" normalCollectionSummaries.
          //
          // See: [Note: Picking from selectable collection summaries].
          collections.find(({ id }) => id == collectionSummaryID)!;

/**
 * Perform a "collection operation" on the selected file(s).
 *
 * @param op The {@link CollectionOp} to perform, e.g. "add", "restore".
 *
 * @param selectedCollection The existing or new collection selected by the
 * user. This serves as the target of the operation.
 *
 * @param selectedUserFiles The files selected by the user, on which the
 * operation should be performed. Currently these need to all belong to the
 * user.
 *
 * @param sourceCollectionID In the case of a "move", the operation is always
 * expected to happen in the context of an existing collection, which serves as
 * the source collection for the move. In such a case, the caller should provide
 * this argument, using the collection ID of the collection in which the
 * selection occurred.
 *
 * [Note: Add and move of non-user files]
 *
 * Currently, all {@link selectedUserFiles} need to belong to the user. This is
 * because adds and move cannot be performed on remote across ownership
 * boundaries directly.
 *
 * Enhancement: The mobile client has support for adding and moving such files.
 * It does so by creating a copy, but using hash checks to avoid a copy if not
 * needed. Implement these. This is a bit non-trivial since the mobile client
 * then also adds various heuristics to omit the display of the "doubled" files
 * in the all section etc.
 */
export const performCollectionOp = async (
    op: CollectionOp,
    selectedCollection: Collection,
    selectedUserFiles: EnteFile[],
    sourceCollectionID: number | undefined,
): Promise<void> => {
    switch (op) {
        case "add":
            await addToCollection(selectedCollection, selectedUserFiles);
            break;
        case "move":
            await moveFromCollection(
                sourceCollectionID!,
                selectedCollection,
                selectedUserFiles,
            );
            break;
        case "restore":
            await restoreToCollection(selectedCollection, selectedUserFiles);
            break;
        case "unhide":
            await moveToCollection(selectedCollection, selectedUserFiles);
            break;
    }
};
