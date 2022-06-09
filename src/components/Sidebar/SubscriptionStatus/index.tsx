import { MemberSubscriptionStatus } from './member';
import { AdminSubscriptionStatus as AdminSubscriptionStatus } from './admin';
import { GalleryContext } from 'pages/gallery';
import React, { useContext } from 'react';
import { hasNonAdminFamilyMembers, isFamilyAdmin } from 'utils/billing';
import Box from '@mui/material/Box';

export default function SubscriptionStatus({ userDetails }) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    if (!userDetails) {
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
