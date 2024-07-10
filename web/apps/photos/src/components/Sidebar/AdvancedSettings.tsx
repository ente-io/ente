import { EnteDrawer } from "@/new/shared/components/EnteDrawer";
import { MenuItemGroup, MenuSectionTitle } from "@/new/shared/components/Menu";
import { Titlebar } from "@/new/shared/components/Titlebar";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { Box, DialogProps, Stack } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function AdvancedSettings({ open, onClose, onRootClose }) {
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
                    title={t("ADVANCED")}
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
}
