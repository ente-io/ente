import React, { useContext, useEffect, useState } from 'react';
import { LS_KEYS, setData } from 'utils/storage/localStorage';

import { getUserDetails } from 'services/userService';
import { UserDetails } from 'types/user';
import { getLocalUserDetails } from 'utils/user';
import InfoSection from './InfoSection';
import NavigationSection from './NavigationSection';
import UtilitySection from './UtilitySection';
import HelpSection from './HelpSection';
import ExitSection from './ExitSection';
import DebugLogs from './DebugLogs';
import { DrawerSidebar, DividerWithMargin } from './styledComponents';
import { AppContext } from 'pages/_app';
import SubscriptionDetails from './SubscriptionDetails';
import HeaderSection from './Header';

export default function Sidebar() {
    const { sidebarView, closeSidebar } = useContext(AppContext);
    const [userDetails, setUserDetails] = useState<UserDetails>(null);
    useEffect(() => {
        setUserDetails(getLocalUserDetails());
    }, []);

    useEffect(() => {
        const main = async () => {
            const userDetails = await getUserDetails();
            setUserDetails(userDetails);
            setData(LS_KEYS.USER_DETAILS, userDetails);
        };
        main();
    }, [sidebarView]);

    return (
        <DrawerSidebar anchor="left" open={sidebarView} onClose={closeSidebar}>
            <HeaderSection closeSidebar={closeSidebar} />
            <DividerWithMargin />
            <InfoSection userDetails={userDetails} />
            <SubscriptionDetails userDetails={userDetails} />
            <DividerWithMargin />
            <NavigationSection closeSidebar={closeSidebar} />
            <UtilitySection closeSidebar={closeSidebar} />
            <DividerWithMargin />
            <HelpSection userDetails={userDetails} />
            <DividerWithMargin />
            <ExitSection />
            <DividerWithMargin />
            <DebugLogs />
        </DrawerSidebar>
    );
}
