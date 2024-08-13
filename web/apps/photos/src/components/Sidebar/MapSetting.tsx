import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemGroup } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import log from "@/base/log";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import {
    Box,
    Button,
    DialogProps,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { getMapEnabledStatus } from "services/userService";
import type { SettingsDrawerProps } from "./types";

export const MapSettings: React.FC<SettingsDrawerProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
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
};

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

function EnableMap({ onClose, enableMap, onRootClose }) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("ENABLE_MAPS")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    {" "}
                    <Typography color="text.muted">
                        <Trans
                            i18nKey={"ENABLE_MAP_DESCRIPTION"}
                            components={{
                                a: (
                                    <Link
                                        target="_blank"
                                        rel="noopener"
                                        href="https://www.openstreetmap.org/"
                                    />
                                ),
                            }}
                        />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button color={"accent"} size="large" onClick={enableMap}>
                        {t("enable")}
                    </Button>
                    <Button color={"secondary"} size="large" onClick={onClose}>
                        {t("cancel")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}

function DisableMap({ onClose, disableMap, onRootClose }) {
    return (
        <Stack spacing={"4px"} py={"12px"}>
            <Titlebar
                onClose={onClose}
                title={t("DISABLE_MAPS")}
                onRootClose={onRootClose}
            />
            <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                <Box px={"8px"}>
                    <Typography color="text.muted">
                        <Trans i18nKey={"DISABLE_MAP_DESCRIPTION"} />
                    </Typography>
                </Box>
                <Stack px={"8px"} spacing={"8px"}>
                    <Button
                        color={"critical"}
                        size="large"
                        onClick={disableMap}
                    >
                        {t("disable")}
                    </Button>
                    <Button color={"secondary"} size="large" onClick={onClose}>
                        {t("cancel")}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
