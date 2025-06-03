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

import { getUserRecoveryKeyB64 } from "ente-accounts/services/recovery-key";
import log from "ente-base/log";
import type { Collection } from "ente-media/collection";
import type { FamilyData } from "ente-new/photos/services/user-details";
import type { User } from "ente-shared/user/types";

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
        await getUserRecoveryKeyB64();
        return true;
    } catch (e) {
        log.warn("Failed to validate key" /*, caller will logout */, e);
        return false;
    }
};

export const constructUserIDToEmailMap = (
    user: User,
    collections: Collection[],
): Map<number, string> => {
    const userIDToEmailMap = new Map<number, string>();
    collections.forEach((item) => {
        const { owner, sharees } = item;
        if (user.id !== owner.id && owner.email) {
            userIDToEmailMap.set(owner.id, owner.email);
        }
        // Not sure about its nullability currently, revisit after auditing the
        // type for Collection.
        //
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (sharees) {
            sharees.forEach((item) => {
                if (item.id !== user.id && item.email)
                    userIDToEmailMap.set(item.id, item.email);
            });
        }
    });
    return userIDToEmailMap;
};

/**
 * Create a list of emails that are shown as suggestions to the user when they
 * are trying to share albums with specific users.
 */
export const createShareeSuggestionEmails = (
    user: User,
    collections: Collection[],
    familyData: FamilyData | undefined,
): string[] => {
    const emails = collections
        .map(({ owner, sharees }) => {
            if (owner.email && owner.id != user.id) {
                return [owner.email];
            } else {
                // Not sure about its nullability currently, revisit after auditing the
                // type for Collection.
                //
                // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
                return (sharees ?? []).map(({ email }) => email);
            }
        })
        .flat()
        .filter((e) => e !== undefined);

    // Add family members.
    if (familyData) {
        const family = familyData.members.map((member) => member.email);
        emails.push(...family);
    }

    return [...new Set(emails.filter((email) => email != user.email))];
};
