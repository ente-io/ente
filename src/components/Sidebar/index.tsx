import React, { useEffect, useState } from 'react';
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

export default function Sidebar() {
    const [userDetails, setUserDetails] = useState<UserDetails>(null);
    useEffect(() => {
        setUserDetails(getLocalUserDetails());
    }, []);
    const [isOpen, setIsOpen] = useState(false);

    useEffect(() => {
        const main = async () => {
            const userDetails = await getUserDetails();
            setUserDetails(userDetails);
            setData(LS_KEYS.USER_DETAILS, userDetails);
        };
        main();
    }, [isOpen]);

    const closeSidebar = () => setIsOpen(false);

    return (
        <DrawerSidebar
            anchor="left"
            open={true}
            onClose={() => setIsOpen(false)}>
            <div>
                <InfoSection userDetails={userDetails} />
                <DividerWithMargin />
                <NavigationSection closeSidebar={closeSidebar} />
                <UtilitySection closeSidebar={closeSidebar} />
                <DividerWithMargin />
                <HelpSection userDetails={userDetails} />
                <DividerWithMargin />
                <ExitSection />
                <DividerWithMargin />
                <DebugLogs />
            </div>
        </DrawerSidebar>
    );
}
