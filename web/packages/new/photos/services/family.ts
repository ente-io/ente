import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import {
    LS_KEYS,
    getData,
    removeData,
} from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { z } from "zod";

const FamilyMember = z.object({
    /**
     * Email address of the family member.
     */
    email: z.string(),
    /**
     * Storage used by the family member.
     *
     * This field will not be present for invited members until they accept.
     */
    usage: z.number().nullish().transform(nullToUndefined),
    /**
     * `true` if this is the admin.
     *
     * This field will not be sent for invited members until they accept.
     */
    isAdmin: z.boolean().nullish().transform(nullToUndefined),
});

type FamilyMember = z.infer<typeof FamilyMember>;

/**
 * Zod schema for details about the family plan (if any) that the user is a part
 * of.
 */
export const FamilyData = z.object({
    members: z.array(FamilyMember),
    /**
     * Family admin subscription storage capacity.
     *
     * This excludes add-on and any other bonus storage.
     */
    storage: z.number(),
});

/**
 * Details about the family plan (if any) that the user is a part of.
 */
export type FamilyData = z.infer<typeof FamilyData>;

export function getLocalFamilyData(): FamilyData {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return getData(LS_KEYS.FAMILY_DATA);
}

// isPartOfFamily return true if the current user is part of some family plan
export function isPartOfFamily(familyData: FamilyData): boolean {
    return Boolean(
        // eslint-disable-next-line @typescript-eslint/prefer-optional-chain, @typescript-eslint/no-unnecessary-condition
        familyData && familyData.members && familyData.members.length > 0,
    );
}

// hasNonAdminFamilyMembers return true if the admin user has members in his family
export function hasNonAdminFamilyMembers(familyData: FamilyData): boolean {
    return Boolean(isPartOfFamily(familyData) && familyData.members.length > 1);
}

export function isFamilyAdmin(familyData: FamilyData): boolean {
    const familyAdmin: FamilyMember = getFamilyPlanAdmin(familyData);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const user: User = getData(LS_KEYS.USER);
    return familyAdmin.email === user.email;
}

export function getFamilyPlanAdmin(familyData: FamilyData): FamilyMember {
    if (isPartOfFamily(familyData)) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        return familyData.members.find((x) => x.isAdmin)!;
    } else {
        log.error(
            "invalid getFamilyPlanAdmin call - verify user is part of family plan before calling this method",
        );
        throw new Error(
            "invalid getFamilyPlanAdmin call - verify user is part of family plan before calling this method",
        );
    }
}

export function getTotalFamilyUsage(familyData: FamilyData): number {
    return familyData.members.reduce(
        (sum, currentMember) => sum + (currentMember.usage ?? 0),
        0,
    );
}

export const leaveFamily = async () => {
    ensureOk(
        await fetch(await apiURL("/family/leave"), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        }),
    );
    removeData(LS_KEYS.FAMILY_DATA);
};
