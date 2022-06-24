import { BackgroundOverlay } from './backgroundOverlay';
import { ClickOverlay } from './clickOverlay';
import React, { useContext } from 'react';
import { Skeleton } from '@mui/material';
import { UserDetails } from 'types/user';

import { GalleryContext } from 'pages/gallery';
import {
    hasNonAdminFamilyMembers,
    isFamilyAdmin,
    isPartOfFamily,
} from 'utils/billing';
import { SubscriptionCardContent } from './contentOverlay';
import { FlexWrapper } from 'components/Container';
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
                height={148}
                sx={{ borderRadius: '8px' }}
            />
        );
    }

    const isMemberSubscription =
        isPartOfFamily(userDetails.familyData) &&
        !isFamilyAdmin(userDetails.familyData);

    return (
        <FlexWrapper flexDirection={'column'} position="relative" height={148}>
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
        </FlexWrapper>
    );
}
