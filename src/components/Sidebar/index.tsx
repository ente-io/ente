import React, { useEffect } from 'react';

import ShortcutSection from './ShortcutSection';
import UtilitySection from './UtilitySection';
import HelpSection from './HelpSection';
import ExitSection from './ExitSection';
import DebugSection from './DebugSection';
import { DrawerSidebar } from './styledComponents';
import HeaderSection from './Header';
import { CollectionSummaries } from 'types/collection';
import UserDetailsSection from './userDetailsSection';
import { Divider, Stack } from '@mui/material';

interface Iprops {
    collectionSummaries: CollectionSummaries;
    sidebarView: boolean;
    closeSidebar: () => void;
}
export default function Sidebar({
    collectionSummaries,
    sidebarView,
    closeSidebar,
}: Iprops) {
    const drawerSidebarPaperRef = React.useRef<HTMLDivElement>(null);
    useEffect(() => {
        if (!sidebarView && drawerSidebarPaperRef.current) {
            drawerSidebarPaperRef.current.scrollTop = 0;
        }
    }, [sidebarView]);

    return (
        <DrawerSidebar
            open={sidebarView}
            onClose={closeSidebar}
            keepMounted
            PaperProps={{ ref: drawerSidebarPaperRef }}>
            <HeaderSection closeSidebar={closeSidebar} />
            <Divider />
            <UserDetailsSection sidebarView={sidebarView} />
            <Stack spacing={0.5} mb={3}>
                <ShortcutSection
                    closeSidebar={closeSidebar}
                    collectionSummaries={collectionSummaries}
                />
                <UtilitySection closeSidebar={closeSidebar} />
                <Divider />
                <HelpSection />
                <Divider />
                <ExitSection />
                <Divider />
                <DebugSection />
            </Stack>
        </DrawerSidebar>
    );
}
