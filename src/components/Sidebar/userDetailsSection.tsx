import React, { useEffect } from 'react';
import SubscriptionCard from './SubscriptionCard';
import { getUserDetailsV2 } from 'services/userService';
import { UserDetails } from 'types/user';
import { LS_KEYS } from 'utils/storage/localStorage';
import { useLocalState } from 'hooks/useLocalState';
import Typography from '@mui/material/Typography';
import SubscriptionStatus from './SubscriptionStatus';
import Stack from '@mui/material/Stack';

export default function UserDetailsSection({ sidebarView, closeSidebar }) {
    const [userDetails, setUserDetails] = useLocalState<UserDetails>(
        LS_KEYS.USER_DETAILS
    );

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
        <Stack spacing={1}>
            <Typography>{userDetails?.email}</Typography>
            <SubscriptionCard
                userDetails={userDetails}
                closeSidebar={closeSidebar}
            />
            <SubscriptionStatus userDetails={userDetails} />
        </Stack>
    );
}
