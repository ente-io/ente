import { logError } from "@ente/shared/sentry";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { User } from "@ente/shared/user/types";
import { FamilyData, FamilyMember } from "types/user";

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
        logError(
            Error(
                "verify user is part of family plan before calling this method",
            ),
            "invalid getFamilyPlanAdmin call",
        );
    }
}

export function getTotalFamilyUsage(familyData: FamilyData): number {
    return familyData.members.reduce(
        (sum, currentMember) => sum + currentMember.usage,
        0,
    );
}
