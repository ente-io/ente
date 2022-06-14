import { MemberSubscriptionStatus } from './member';
import { AdminSubscriptionStatus as AdminSubscriptionStatus } from './admin';
import { GalleryContext } from 'pages/gallery';
import React, { useContext, useMemo } from 'react';
import {
    hasNonAdminFamilyMembers,
    isFamilyAdmin,
    isOnFreePlan,
    isSubscriptionActive,
    isSubscriptionCancelled,
} from 'utils/billing';
import Box from '@mui/material/Box';
import { UserDetails } from 'types/user';

export default function SubscriptionStatus({
    userDetails,
}: {
    userDetails: UserDetails;
}) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    const hasAMessage = useMemo(
        () =>
            userDetails &&
            (!isSubscriptionActive(userDetails.subscription) ||
                isOnFreePlan(userDetails.subscription) ||
                isSubscriptionCancelled(userDetails.subscription)),
        [userDetails]
    );

    if (!hasAMessage) {
        return <></>;
    }

    return (
        <Box px={1}>
            {!hasNonAdminFamilyMembers(userDetails.familyData) ||
            isFamilyAdmin(userDetails.familyData) ? (
                <AdminSubscriptionStatus
                    userDetails={userDetails}
                    showPlanSelectorModal={showPlanSelectorModal}
                />
            ) : (
                <MemberSubscriptionStatus userDetails={userDetails} />
            )}
        </Box>
    );
}
