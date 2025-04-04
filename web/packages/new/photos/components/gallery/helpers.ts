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

import type { Collection } from "ente-media/collection";
import type { FamilyData } from "ente-new/photos/services/user-details";
import type { User } from "ente-shared/user/types";

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
        if (sharees) {
            sharees.forEach((item) => {
                if (item.id !== user.id)
                    userIDToEmailMap.set(item.id, item.email);
            });
        }
    });
    return userIDToEmailMap;
};

export const constructEmailList = (
    user: User,
    collections: Collection[],
    familyData: FamilyData,
): string[] => {
    const emails = collections
        .map((item) => {
            const { owner, sharees } = item;
            if (owner.email && item.owner.id !== user.id) {
                return [item.owner.email];
            } else {
                if (!sharees?.length) {
                    return [];
                }
                const shareeEmails = item.sharees
                    .filter((sharee) => sharee.email !== user.email)
                    .map((sharee) => sharee.email);
                return shareeEmails;
            }
        })
        .flat();

    // adding family members
    if (familyData) {
        const family = familyData.members.map((member) => member.email);
        emails.push(...family);
    }
    return Array.from(new Set(emails));
};
