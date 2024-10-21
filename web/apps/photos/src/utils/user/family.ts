import log from "@/base/log";
import type { FamilyData, FamilyMember } from "@/new/photos/services/user";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";

export function getLocalFamilyData(): FamilyData {
    return getData(LS_KEYS.FAMILY_DATA);
}

// isPartOfFamily return true if the current user is part of some family plan
export function isPartOfFamily(familyData: FamilyData): boolean {
    return Boolean(
        familyData && familyData.members && familyData.members.length > 0,
    );
}

// hasNonAdminFamilyMembers return true if the admin user has members in his family
export function hasNonAdminFamilyMembers(familyData: FamilyData): boolean {
    return Boolean(isPartOfFamily(familyData) && familyData.members.length > 1);
}

export function isFamilyAdmin(familyData: FamilyData): boolean {
    const familyAdmin: FamilyMember = getFamilyPlanAdmin(familyData);
    const user: User = getData(LS_KEYS.USER);
    return familyAdmin.email === user.email;
}

export function getFamilyPlanAdmin(familyData: FamilyData): FamilyMember {
    if (isPartOfFamily(familyData)) {
        return familyData.members.find((x) => x.isAdmin);
    } else {
        log.error(
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
