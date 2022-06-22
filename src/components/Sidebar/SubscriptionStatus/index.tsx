import { GalleryContext } from 'pages/gallery';
import React, { useContext, useMemo } from 'react';
import {
    hasNonAdminFamilyMembers,
    hasPaidSubscription,
    isFamilyAdmin,
    isOnFreePlan,
    isSubscriptionActive,
    isSubscriptionCancelled,
} from 'utils/billing';
import Box from '@mui/material/Box';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';
import { Typography } from '@mui/material';

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
            {(!hasNonAdminFamilyMembers(userDetails.familyData) ||
                isFamilyAdmin(userDetails.familyData) ||
                hasPaidSubscription(userDetails.subscription)) && (
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
                            : isSubscriptionCancelled(
                                  userDetails.subscription
                              ) &&
                              constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                                  userDetails.subscription?.expiryTime
                              )
                        : constants.SUBSCRIPTION_EXPIRED_MESSAGE(
                              showPlanSelectorModal
                          )}
                </Typography>
            )}
        </Box>
    );
}
