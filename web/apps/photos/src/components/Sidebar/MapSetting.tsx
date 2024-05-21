import log from "@/next/log";
import { Box, DialogProps, Stack } from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import { getMapEnabledStatus } from "services/userService";
import DisableMap from "./DisableMap";
import EnableMap from "./EnableMap";

export default function MapSettings({ open, onClose, onRootClose }) {
    const { mapEnabled, updateMapEnabled } = useContext(AppContext);
    const [modifyMapEnabledView, setModifyMapEnabledView] = useState(false);

    const openModifyMapEnabled = () => setModifyMapEnabledView(true);
    const closeModifyMapEnabled = () => setModifyMapEnabledView(false);

    useEffect(() => {
        if (!open) {
            return;
        }
        const main = async () => {
            const remoteMapValue = await getMapEnabledStatus();
            updateMapEnabled(remoteMapValue);
        };
        main();
    }, [open]);

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
                    title={t("MAP")}
                    onRootClose={handleRootClose}
                />

                <Box px={"8px"}>
                    <Stack py="20px" spacing="24px">
                        <Box>
                            <MenuItemGroup>
                                <EnteMenuItem
                                    onClick={openModifyMapEnabled}
                                    variant="toggle"
                                    checked={mapEnabled}
                                    label={t("MAP_SETTINGS")}
                                />
                            </MenuItemGroup>
                        </Box>
                    </Stack>
                </Box>
            </Stack>
            <ModifyMapEnabled
                open={modifyMapEnabledView}
                mapEnabled={mapEnabled}
                onClose={closeModifyMapEnabled}
                onRootClose={handleRootClose}
            />
        </EnteDrawer>
    );
}

const ModifyMapEnabled = ({ open, onClose, onRootClose, mapEnabled }) => {
    const { somethingWentWrong, updateMapEnabled } = useContext(AppContext);

    const disableMap = async () => {
        try {
            await updateMapEnabled(false);
            onClose();
        } catch (e) {
            log.error("Disable Map failed", e);
            somethingWentWrong();
        }
    };

    const enableMap = async () => {
        try {
            await updateMapEnabled(true);
            onClose();
        } catch (e) {
            log.error("Enable Map failed", e);
            somethingWentWrong();
        }
    };

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
        <Box>
            <EnteDrawer
                anchor="left"
                transitionDuration={0}
                open={open}
                onClose={handleDrawerClose}
                slotProps={{
                    backdrop: {
                        sx: { "&&&": { backgroundColor: "transparent" } },
                    },
                }}
            >
                {mapEnabled ? (
                    <DisableMap
                        onClose={onClose}
                        disableMap={disableMap}
                        onRootClose={handleRootClose}
                    />
                ) : (
                    <EnableMap
                        onClose={onClose}
                        enableMap={enableMap}
                        onRootClose={handleRootClose}
                    />
                )}
            </EnteDrawer>
        </Box>
    );
};
