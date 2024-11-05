import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { AppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { Stack } from "@mui/material";
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
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={handleRootClose}
                    title={t("advanced")}
                />

                <Stack sx={{ px: "16px", py: "20px" }}>
                    <Stack sx={{ gap: "4px" }}>
                        <MenuItemGroup>
                            <EnteMenuItem
                                variant="toggle"
                                checked={!appContext.isCFProxyDisabled}
                                onClick={toggleCFProxy}
                                label={t("faster_upload")}
                            />
                        </MenuItemGroup>
                        <MenuSectionTitle
                            title={t("faster_upload_description")}
                        />
                    </Stack>
                </Stack>
            </Stack>
        </NestedSidebarDrawer>
    );
};
