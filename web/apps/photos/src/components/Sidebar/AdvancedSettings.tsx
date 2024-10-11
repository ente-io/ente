import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import type { NestedDrawerVisibilityProps } from "@/base/components/utils/modal";
import { AppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { Box, DialogProps, Stack } from "@mui/material";
import { t } from "i18next";
import React, { useContext } from "react";

export const AdvancedSettings: React.FC<NestedDrawerVisibilityProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const appContext = useContext(AppContext);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };

    const toggleCFProxy = () => {
        appContext.setIsCFProxyDisabled(!appContext.isCFProxyDisabled);
    };

    return (
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={handleDrawerClose}
            BackdropProps={{
                sx: { "&&&": { backgroundColor: "transparent" } },
            }}
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
        </EnteDrawer>
    );
};
