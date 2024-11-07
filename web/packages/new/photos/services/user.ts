import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { z } from "zod";

export interface FamilyMember {
    email: string;
    usage: number;
    id: string;
    isAdmin: boolean;
}

export interface FamilyData {
    storage: number;
    expiry: number;
    members: FamilyMember[];
}

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
        (sum, currentMember) => sum + currentMember.usage,
        0,
    );
}

/**
 * Fetch the two-factor status (whether or not it is enabled) from remote.
 */
export const get2FAStatus = async () => {
    const res = await fetch(await apiURL("/users/two-factor/status"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ status: z.boolean() }).parse(await res.json()).status;
};

/**
 * Disable two-factor authentication for the current user on remote.
 */
export const disable2FA = async () =>
    ensureOk(
        await fetch(await apiURL("/users/two-factor/disable"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );
