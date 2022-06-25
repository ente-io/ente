import { BackgroundOverlay } from './backgroundOverlay';
import { ClickOverlay } from './clickOverlay';
import React, { useContext } from 'react';
import { Box, Skeleton } from '@mui/material';
import { UserDetails } from 'types/user';

import { GalleryContext } from 'pages/gallery';
import {
    hasNonAdminFamilyMembers,
    isFamilyAdmin,
    isPartOfFamily,
} from 'utils/billing';
import { SubscriptionCardContent } from './contentOverlay';

const SUBSCRIPTION_CARD_SIZE = 152;

interface Iprops {
    userDetails: UserDetails;
    openMemberSubscriptionDialog: () => void;
}

export default function SubscriptionCard({
    userDetails,
    openMemberSubscriptionDialog,
}: Iprops) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    if (!userDetails) {
        return (
            <Skeleton
                animation="wave"
                variant="rectangular"
                height={SUBSCRIPTION_CARD_SIZE}
                sx={{ borderRadius: '8px' }}
            />
        );
    }

    const isMemberSubscription =
        isPartOfFamily(userDetails.familyData) &&
        !isFamilyAdmin(userDetails.familyData);

    return (
        <Box position="relative" height={SUBSCRIPTION_CARD_SIZE}>
            <SubscriptionCardContent
                hasNonAdminFamilyMembers={hasNonAdminFamilyMembers}
                userDetails={userDetails}
            />
            <BackgroundOverlay />
            <ClickOverlay
                onClick={
                    isMemberSubscription
                        ? openMemberSubscriptionDialog
                        : showPlanSelectorModal
                }
            />
        </Box>
    );
}
