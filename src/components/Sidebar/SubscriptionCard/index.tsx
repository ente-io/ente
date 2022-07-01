import { BackgroundOverlay } from './backgroundOverlay';
import { ClickOverlay } from './clickOverlay';
import React from 'react';
import { Box, Skeleton } from '@mui/material';
import { UserDetails } from 'types/user';

import { SubscriptionCardContent } from './contentOverlay';

const SUBSCRIPTION_CARD_SIZE = 152;

interface Iprops {
    userDetails: UserDetails;
    onClick: () => void;
}

export default function SubscriptionCard({ userDetails, onClick }: Iprops) {
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

    return (
        <Box position="relative" height={SUBSCRIPTION_CARD_SIZE}>
            <SubscriptionCardContent userDetails={userDetails} />
            <BackgroundOverlay />
            <ClickOverlay onClick={onClick} />
        </Box>
    );
}
