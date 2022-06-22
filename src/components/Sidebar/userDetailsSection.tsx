import React, { useEffect, useState } from 'react';
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

export default function UserDetailsSection({ sidebarView }) {
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
                    openMemberSubscriptionDialog={openMemberSubscriptionManage}
                />
                <SubscriptionStatus userDetails={userDetails} />
            </Stack>

            <MemberSubscriptionManage
                userDetails={userDetails}
                open={memberSubscriptionManageView}
                onClose={closeMemberSubscriptionManage}
            />
        </>
    );
}
