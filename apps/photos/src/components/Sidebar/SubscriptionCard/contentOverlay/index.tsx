import { Overlay, SpaceBetweenFlex } from "@ente/shared/components/Container";
import { UserDetails } from "types/user";
import { hasNonAdminFamilyMembers } from "utils/user/family";
import { FamilySubscriptionCardContent } from "./family";
import { IndividualSubscriptionCardContent } from "./individual";

interface Iprops {
    userDetails: UserDetails;
}

export function SubscriptionCardContentOverlay({ userDetails }: Iprops) {
    return (
        <Overlay>
            <SpaceBetweenFlex
                height={"100%"}
                flexDirection={"column"}
                padding={"20px 16px"}
            >
                {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                    <FamilySubscriptionCardContent userDetails={userDetails} />
                ) : (
                    <IndividualSubscriptionCardContent
                        userDetails={userDetails}
                    />
                )}
            </SpaceBetweenFlex>
        </Overlay>
    );
}
