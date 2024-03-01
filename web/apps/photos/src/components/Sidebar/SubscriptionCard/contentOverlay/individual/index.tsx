import { UserDetails } from "types/user";
import StorageSection from "../storageSection";
import { IndividualUsageSection } from "./usageSection";

interface Iprops {
    userDetails: UserDetails;
}

export function IndividualSubscriptionCardContent({ userDetails }: Iprops) {
    const totalStorage =
        userDetails.subscription.storage + (userDetails.storageBonus ?? 0);
    return (
        <>
            <StorageSection storage={totalStorage} usage={userDetails.usage} />
            <IndividualUsageSection
                usage={userDetails.usage}
                fileCount={userDetails.fileCount}
                storage={totalStorage}
            />
        </>
    );
}
