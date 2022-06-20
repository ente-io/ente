import { ClickOverlay } from './clickOverlay';
import React, { useContext } from 'react';
import { Box, Skeleton } from '@mui/material';
import { UserDetails } from 'types/user';

import { GalleryContext } from 'pages/gallery';
import { hasNonAdminFamilyMembers } from 'utils/billing';
import { SubscriptionCardContentOverlay } from './contentOverlay';
interface Iprops {
    userDetails: UserDetails;
    closeSidebar: () => void;
}

export default function SubscriptionCard({ userDetails }: Iprops) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    if (!userDetails) {
        return (
            <Skeleton
                animation="wave"
                variant="rectangular"
                width={'100%'}
                height={148}
                sx={{ borderRadius: '8px' }}
            />
        );
    }

    return (
        <Box position="relative">
            <img
                style={{
                    width: '100%',
                    aspectRatio: '2/1',
                }}
                src="/images/subscription-card-background.png"
            />
            <ClickOverlay onClick={showPlanSelectorModal} />
            <SubscriptionCardContentOverlay
                hasNonAdminFamilyMembers={hasNonAdminFamilyMembers}
                userDetails={userDetails}
            />
        </Box>
    );
}
