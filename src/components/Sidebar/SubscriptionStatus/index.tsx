import { GalleryContext } from 'pages/gallery';
import React, { useContext, useMemo } from 'react';
import {
    hasPaidSubscription,
    isFamilyAdmin,
    isOnFreePlan,
    isPartOfFamily,
    hasExceededStorageQuota,
    isSubscriptionActive,
    isSubscriptionCancelled,
} from 'utils/billing';
import Box from '@mui/material/Box';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';
import { Typography } from '@mui/material';
import billingService from 'services/billingService';

export default function SubscriptionStatus({
    userDetails,
}: {
    userDetails: UserDetails;
}) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    const hasAMessage = useMemo(() => {
        if (!userDetails) {
            return false;
        }
        if (
            isPartOfFamily(userDetails.familyData) &&
            !isFamilyAdmin(userDetails.familyData)
        ) {
            return false;
        }
        if (
            hasPaidSubscription(userDetails.subscription) &&
            !isSubscriptionCancelled(userDetails.subscription)
        ) {
            return false;
        }
        return true;
    }, [userDetails]);

    const handleClick = useMemo(
        () =>
            userDetails && isSubscriptionActive(userDetails.subscription)
                ? hasExceededStorageQuota(userDetails) && showPlanSelectorModal
                : billingService.redirectToCustomerPortal,
        [userDetails]
    );

    if (!hasAMessage) {
        return <></>;
    }

    return (
        <Box px={1} pt={0.5}>
            <Typography
                variant="body2"
                color={'text.secondary'}
                onClick={handleClick && handleClick}
                sx={{ cursor: handleClick && 'pointer' }}>
                {isSubscriptionActive(userDetails.subscription)
                    ? isOnFreePlan(userDetails.subscription)
                        ? constants.FREE_SUBSCRIPTION_INFO(
                              userDetails.subscription?.expiryTime
                          )
                        : isSubscriptionCancelled(userDetails.subscription)
                        ? constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                              userDetails.subscription?.expiryTime
                          )
                        : hasExceededStorageQuota(userDetails) &&
                          constants.STORAGE_QUOTA_EXCEEDED_SUBSCRIPTION_INFO(
                              showPlanSelectorModal
                          )
                    : constants.SUBSCRIPTION_EXPIRED_MESSAGE(
                          billingService.redirectToCustomerPortal
                      )}
            </Typography>
        </Box>
    );
}
