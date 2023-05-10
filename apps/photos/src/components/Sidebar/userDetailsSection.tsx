import React, { useContext, useEffect, useMemo, useState } from 'react';
import SubscriptionCard from './SubscriptionCard';
import { getUserDetailsV2 } from 'services/userService';
import { UserDetails } from 'types/user';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useLocalState } from 'hooks/useLocalState';
import Typography from '@mui/material/Typography';
import SubscriptionStatus from './SubscriptionStatus';
import { Box, Skeleton } from '@mui/material';
import { MemberSubscriptionManage } from '../MemberSubscriptionManage';
import { GalleryContext } from 'pages/gallery';
import { isFamilyAdmin, isPartOfFamily } from 'utils/user/family';

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
            setData(LS_KEYS.SUBSCRIPTION, userDetails.subscription);
            setData(LS_KEYS.FAMILY_DATA, userDetails.familyData);
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                email: userDetails.email,
            });
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
            <Box px={0.5} mt={2} pb={1.5} mb={1}>
                <Typography px={1} pb={1} color="text.muted">
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
            </Box>
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
