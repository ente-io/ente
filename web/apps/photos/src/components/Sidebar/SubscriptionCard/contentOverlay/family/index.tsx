import { useMemo } from "react";
import { UserDetails } from "types/user";
import { isPartOfFamily } from "utils/user/family";
import StorageSection from "../storageSection";
import { FamilyUsageSection } from "./usageSection";

interface Iprops {
    userDetails: UserDetails;
}
export function FamilySubscriptionCardContent({ userDetails }: Iprops) {
    const totalUsage = useMemo(() => {
        if (isPartOfFamily(userDetails.familyData)) {
            return userDetails.familyData.members.reduce(
                (sum, currentMember) => sum + currentMember.usage,
                0,
            );
        } else {
            return userDetails.usage;
        }
    }, [userDetails]);
    const totalStorage =
        userDetails.familyData.storage + (userDetails.storageBonus ?? 0);

    return (
        <>
            <StorageSection storage={totalStorage} usage={totalUsage} />
            <FamilyUsageSection
                userUsage={userDetails.usage}
                fileCount={userDetails.fileCount}
                totalUsage={totalUsage}
                totalStorage={totalStorage}
            />
        </>
    );
}
