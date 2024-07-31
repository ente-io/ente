import { isDesktop } from "@/base/app";
import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import { pt } from "@/base/i18n";
import { MLSettingsBeta } from "@/new/photos/components/MLSettingsBeta";
import { canEnableML } from "@/new/photos/services/ml";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import ChevronRight from "@mui/icons-material/ChevronRight";
import ScienceIcon from "@mui/icons-material/Science";
import { Box, DialogProps, Stack } from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";

export default function AdvancedSettings({ open, onClose, onRootClose }) {
    const appContext = useContext(AppContext);

    const [showMLSettings, setShowMLSettings] = useState(false);
    const [openMLSettings, setOpenMLSettings] = useState(false);

    useEffect(() => {
        if (isDesktop) void canEnableML().then(setShowMLSettings);
    }, []);
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

                    {showMLSettings && (
                        <Box>
                            <MenuSectionTitle
                                title={t("LABS")}
                                icon={<ScienceIcon />}
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    endIcon={<ChevronRight />}
                                    onClick={() => setOpenMLSettings(true)}
                                    label={pt("Face and magic search")}
                                />
                            </MenuItemGroup>
                        </Box>
                    )}
                </Box>
            </Stack>

            <MLSettingsBeta
                open={openMLSettings}
                onClose={() => setOpenMLSettings(false)}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
}
