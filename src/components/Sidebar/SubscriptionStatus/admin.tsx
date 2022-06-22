import { Typography } from '@mui/material';
import React from 'react';
import {
    isSubscriptionActive,
    isOnFreePlan,
    isSubscriptionCancelled,
} from 'utils/billing';
import constants from 'utils/strings/constants';

export function AdminSubscriptionStatus({
    userDetails,
    showPlanSelectorModal,
}) {
    return (
        <Typography
            variant="body2"
            color={'text.secondary'}
            onClick={showPlanSelectorModal}
            sx={{ cursor: 'pointer' }}>
            {isSubscriptionActive(userDetails.subscription)
                ? isOnFreePlan(userDetails.subscription)
                    ? constants.FREE_SUBSCRIPTION_INFO(
                          userDetails.subscription?.expiryTime
                      )
                    : isSubscriptionCancelled(userDetails.subscription) &&
                      constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                          userDetails.subscription?.expiryTime
                      )
                : constants.SUBSCRIPTION_EXPIRED_MESSAGE(showPlanSelectorModal)}
        </Typography>
    );
}
