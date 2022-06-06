import React, { useContext } from 'react';

import NavigationSection from './NavigationSection';
import UtilitySection from './UtilitySection';
import HelpSection from './HelpSection';
import ExitSection from './ExitSection';
// import DebugLogs from './DebugLogs';
import { DrawerSidebar, PaddedDivider } from './styledComponents';
import HeaderSection from './Header';
import { CollectionSummaries } from 'types/collection';
import UserDetailsSection from './userDetailsSection';
import { GalleryContext } from 'pages/gallery';

interface Iprops {
    collectionSummaries: CollectionSummaries;
}
export default function Sidebar({ collectionSummaries }: Iprops) {
    const { sidebarView, closeSidebar } = useContext(GalleryContext);

    return (
        <DrawerSidebar open={sidebarView} onClose={closeSidebar}>
            <HeaderSection closeSidebar={closeSidebar} />
            <PaddedDivider spaced />
            <UserDetailsSection
                sidebarView={sidebarView}
                closeSidebar={closeSidebar}
            />
            <PaddedDivider invisible />
            <NavigationSection
                closeSidebar={closeSidebar}
                collectionSummaries={collectionSummaries}
            />
            <UtilitySection closeSidebar={closeSidebar} />
            <PaddedDivider />
            <HelpSection />
            <PaddedDivider />
            <ExitSection />
            {/* <PaddedDivider />
            <DebugLogs /> */}
        </DrawerSidebar>
    );
}
