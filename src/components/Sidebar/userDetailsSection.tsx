import React, { useEffect } from 'react';
import { SpaceBetweenFlex } from 'components/Container';
import { PaddedDivider } from './styledComponents';
import SubscriptionDetails from './SubscriptionDetails';
import { getUserDetailsV2 } from 'services/userService';
import { UserDetails } from 'types/user';
import { LS_KEYS } from 'utils/storage/localStorage';
import { useLocalState } from 'hooks/useLocalState';
import { THEMES } from 'types/theme';
import ThemeSwitcher from './ThemeSwitcher';
import Typography from '@mui/material/Typography';

export default function UserDetailsSection({ sidebarView, closeSidebar }) {
    const [userDetails, setUserDetails] = useLocalState<UserDetails>(
        LS_KEYS.USER_DETAILS
    );
    const [theme, setTheme] = useLocalState<THEMES>(LS_KEYS.THEME, THEMES.DARK);

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
            <SpaceBetweenFlex px={1}>
                <Typography>{userDetails?.email}</Typography>
                <ThemeSwitcher theme={theme} setTheme={setTheme} />
            </SpaceBetweenFlex>
            <PaddedDivider invisible />
            <SubscriptionDetails
                userDetails={userDetails}
                closeSidebar={closeSidebar}
            />
        </>
    );
}
