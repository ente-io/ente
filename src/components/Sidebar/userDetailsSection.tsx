import React, { useContext, useEffect, useMemo, useState } from 'react';
import SubscriptionCard from './SubscriptionCard';
import { getUserDetailsV2 } from 'services/userService';
import { UserDetails } from 'types/user';
import { LS_KEYS } from 'utils/storage/localStorage';
import { useLocalState } from 'hooks/useLocalState';
import Typography from '@mui/material/Typography';
import SubscriptionStatus from './SubscriptionStatus';
import Stack from '@mui/material/Stack';
import { Skeleton } from '@mui/material';
import { MemberSubscriptionManage } from '../MemberSubscriptionManage';
import { GalleryContext } from 'pages/gallery';
import { isPartOfFamily, isFamilyAdmin } from 'utils/billing';

export default function UserDetailsSection({ sidebarView }) {
    const galleryContext = useContext(GalleryContext);

    const [userDetails, setUserDetails] = useLocalState<UserDetails>(
        LS_KEYS.USER_DETAILS
    );
    const [memberSubscriptionManageView, setMemberSubscriptionManageView] =
        useState(false);

    const openMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(true);
    const closeMemberSubscriptionManage = () =>
        setMemberSubscriptionManageView(false);

    useEffect(() => {
        if (!sidebarView) {
            return;
        }
        const main = async () => {
            const userDetails = await getUserDetailsV2();
            setUserDetails(userDetails);
        };
        main();
    }, [sidebarView]);

    const isMemberSubscription = useMemo(
        () =>
            userDetails &&
            isPartOfFamily(userDetails.familyData) &&
            !isFamilyAdmin(userDetails.familyData),
        [userDetails]
    );

    const handleSubscriptionCardClick = isMemberSubscription
        ? openMemberSubscriptionManage
        : galleryContext.showPlanSelectorModal;

    return (
        <>
            <Stack spacing={1}>
                <Typography px={1} color="text.secondary">
                    {userDetails ? (
                        userDetails.email
                    ) : (
                        <Skeleton animation="wave" />
                    )}
                </Typography>

                <SubscriptionCard
                    userDetails={userDetails}
                    onClick={handleSubscriptionCardClick}
                />
                <SubscriptionStatus userDetails={userDetails} />
            </Stack>

            {isMemberSubscription && (
                <MemberSubscriptionManage
                    userDetails={userDetails}
                    open={memberSubscriptionManageView}
                    onClose={closeMemberSubscriptionManage}
                />
            )}
        </>
    );
}
