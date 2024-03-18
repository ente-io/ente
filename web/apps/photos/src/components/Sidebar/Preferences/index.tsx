import ChevronRight from "@mui/icons-material/ChevronRight";
import { Box, DialogProps, Stack } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { useState } from "react";
import AdvancedSettings from "../AdvancedSettings";
import MapSettings from "../MapSetting";
import { LanguageSelector } from "./LanguageSelector";

export default function Preferences({ open, onClose, onRootClose }) {
    const [advancedSettingsView, setAdvancedSettingsView] = useState(false);
    const [mapSettingsView, setMapSettingsView] = useState(false);

    const openAdvancedSettings = () => setAdvancedSettingsView(true);
    const closeAdvancedSettings = () => setAdvancedSettingsView(false);

    const openMapSettings = () => setMapSettingsView(true);
    const closeMapSettings = () => setMapSettingsView(false);

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
                    title={t("PREFERENCES")}
                    onRootClose={handleRootClose}
                />
                <Box px={"8px"}>
                    <Stack py="20px" spacing="24px">
                        <LanguageSelector />
                        <EnteMenuItem
                            onClick={openMapSettings}
                            endIcon={<ChevronRight />}
                            label={t("MAP")}
                        />
                        <EnteMenuItem
                            onClick={openAdvancedSettings}
                            endIcon={<ChevronRight />}
                            label={t("ADVANCED")}
                        />
                    </Stack>
                </Box>
            </Stack>
            <AdvancedSettings
                open={advancedSettingsView}
                onClose={closeAdvancedSettings}
                onRootClose={onRootClose}
            />
            <MapSettings
                open={mapSettingsView}
                onClose={closeMapSettings}
                onRootClose={onRootClose}
            />
        </EnteDrawer>
    );
}
