import { Divider, Stack } from "@mui/material";
import { CollectionSummaries } from "types/collection";
import DebugSection from "./DebugSection";
import ExitSection from "./ExitSection";
import HeaderSection from "./Header";
import HelpSection from "./HelpSection";
import ShortcutSection from "./ShortcutSection";
import UtilitySection from "./UtilitySection";
import { DrawerSidebar } from "./styledComponents";
import UserDetailsSection from "./userDetailsSection";

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
    return (
        <DrawerSidebar open={sidebarView} onClose={closeSidebar}>
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
