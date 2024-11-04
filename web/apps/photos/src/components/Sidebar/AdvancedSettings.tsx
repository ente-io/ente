import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import {
    NestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { AppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { Box, Stack } from "@mui/material";
import { t } from "i18next";
import React, { useContext } from "react";

export const AdvancedSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const appContext = useContext(AppContext);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const toggleCFProxy = () => {
        appContext.setIsCFProxyDisabled(!appContext.isCFProxyDisabled);
    };

    return (
        <NestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
        >
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("advanced")}
                    onRootClose={handleRootClose}
                />

                <Box px={"8px"}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuItemGroup>
                                <EnteMenuItem
                                    variant="toggle"
                                    checked={!appContext.isCFProxyDisabled}
                                    onClick={toggleCFProxy}
                                    label={t("FASTER_UPLOAD")}
                                />
                            </MenuItemGroup>
                            <MenuSectionTitle
                                title={t("FASTER_UPLOAD_DESCRIPTION")}
                            />
                        </Box>
                    </Stack>
                </Box>
            </Stack>
        </NestedSidebarDrawer>
    );
};
