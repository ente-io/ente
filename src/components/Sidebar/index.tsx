import React, { useContext } from 'react';

import NavigationSection from './NavigationSection';
import UtilitySection from './UtilitySection';
import HelpSection from './HelpSection';
import ExitSection from './ExitSection';
import DebugLogs from './DebugLogs';
import { DrawerSidebar, PaddedDivider } from './styledComponents';
import { AppContext } from 'pages/_app';
import HeaderSection from './Header';
import { CollectionSummaries } from 'types/collection';
import UserDetailsSection from './userDetailsSection';

interface Iprops {
    collectionSummaries: CollectionSummaries;
}
export default function Sidebar({ collectionSummaries }: Iprops) {
    const { sidebarView, closeSidebar } = useContext(AppContext);

    return (
        <DrawerSidebar open={sidebarView} onClose={closeSidebar}>
            <HeaderSection closeSidebar={closeSidebar} />
            <PaddedDivider />
            <UserDetailsSection sidebarView={sidebarView} />
            <PaddedDivider invisible dense />
            <NavigationSection
                closeSidebar={closeSidebar}
                collectionSummaries={collectionSummaries}
            />
            <UtilitySection closeSidebar={closeSidebar} />
            <PaddedDivider />
            <HelpSection />
            <PaddedDivider />
            <ExitSection />
            <PaddedDivider />
            <DebugLogs />
        </DrawerSidebar>
    );
}
