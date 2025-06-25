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
import type { Collection } from "ente-media/collection";
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
 * given {@link collectionSummaryID}. As a special case, if the given
 * {@link collectionSummaryID} is the ID of the placeholder uncategorized
 * collection, create a new uncategorized collection and then return it.
 */
export const findCollectionCreatingUncategorizedIfNeeded = async (
    collections: Collection[],
    collectionSummaryID: number,
): Promise<Collection | undefined> =>
    collectionSummaryID == PseudoCollectionID.uncategorizedPlaceholder
        ? createUncategorizedCollection()
        : collections.find(({ id }) => id == collectionSummaryID);
