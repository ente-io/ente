import ChevronRight from "@mui/icons-material/ChevronRight";
import { Box, DialogProps, Stack } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import isElectron from "is-electron";
import { useState } from "react";

import ElectronAPIs from "@ente/shared/electron";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { logError } from "@ente/shared/sentry";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import AdvancedSettings from "../AdvancedSettings";
import MapSettings from "../MapSetting";
import { LanguageSelector } from "./LanguageSelector";

export default function Preferences({ open, onClose, onRootClose }) {
    const [advancedSettingsView, setAdvancedSettingsView] = useState(false);
    const [mapSettingsView, setMapSettingsView] = useState(false);
    const [optOutOfCrashReports, setOptOutOfCrashReports] = useLocalState(
        LS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
        false,
    );

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

    const toggleOptOutOfCrashReports = async () => {
        try {
            if (isElectron()) {
                await ElectronAPIs.updateOptOutOfCrashReports(
                    !optOutOfCrashReports,
                );
            }
            setOptOutOfCrashReports(!optOutOfCrashReports);
            InMemoryStore.set(
                MS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
                !optOutOfCrashReports,
            );
        } catch (e) {
            logError(e, "toggleOptOutOfCrashReports failed");
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
                            variant="toggle"
                            checked={!optOutOfCrashReports}
                            onClick={toggleOptOutOfCrashReports}
                            label={t("CRASH_REPORTING")}
                        />

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
