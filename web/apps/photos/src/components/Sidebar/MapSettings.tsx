import { InlineErrorIndicator } from "@/base/components/ErrorIndicator";
import { MenuItemGroup } from "@/base/components/Menu";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import log from "@/base/log";
import type { ButtonishProps } from "@/new/photos/components/mui";
import { AppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { Box, Link, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import React, { useContext, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { getMapEnabledStatus } from "services/userService";

export const MapSettings: React.FC<NestedSidebarDrawerVisibilityProps> = ({
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

    return (
        <NestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
        >
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={handleRootClose}
                    title={t("map")}
                />

                <Stack sx={{ px: "16px", py: "20px" }}>
                    <MenuItemGroup>
                        <EnteMenuItem
                            onClick={openModifyMapEnabled}
                            variant="toggle"
                            checked={mapEnabled}
                            label={t("enabled")}
                        />
                    </MenuItemGroup>
                </Stack>
            </Stack>
            <ModifyMapSettings
                open={modifyMapEnabledView}
                mapEnabled={mapEnabled}
                onClose={closeModifyMapEnabled}
                onRootClose={handleRootClose}
            />
        </NestedSidebarDrawer>
    );
};

const ModifyMapSettings = ({ open, onClose, onRootClose, mapEnabled }) => {
    const [phase, setPhase] = useState<"loading" | "failed" | undefined>();
    const { updateMapEnabled } = useContext(AppContext);

    const disableMap = async () => {
        setPhase("loading");
        try {
            await updateMapEnabled(false);
            handleClose();
        } catch (e) {
            log.error("Error", e);
            setPhase("failed");
        }
    };

    const enableMap = async () => {
        setPhase("loading");
        try {
            await updateMapEnabled(true);
            handleClose();
        } catch (e) {
            log.error("Error", e);
            setPhase("failed");
        }
    };

    const handleClose = () => {
        setPhase(undefined);
        onClose();
    };

    const handleRootClose = () => {
        handleClose();
        onRootClose();
    };

    return (
        <NestedSidebarDrawer
            {...{ open }}
            onClose={handleClose}
            onRootClose={handleRootClose}
        >
            {mapEnabled ? (
                <ConfirmDisableMap
                    onClose={handleClose}
                    onRootClose={handleRootClose}
                    onClick={disableMap}
                    phase={phase}
                />
            ) : (
                <ConfirmEnableMap
                    onClose={handleClose}
                    onRootClose={handleRootClose}
                    onClick={enableMap}
                    phase={phase}
                />
            )}
        </NestedSidebarDrawer>
    );
};

type ConfirmStepProps = Pick<
    NestedSidebarDrawerVisibilityProps,
    "onClose" | "onRootClose"
> &
    ButtonishProps & {
        phase: "loading" | "failed" | undefined;
    };

const ConfirmEnableMap: React.FC<ConfirmStepProps> = ({
    onClose,
    onRootClose,
    onClick,
    phase,
}) => (
    <Stack sx={{ gap: "4px", py: "12px" }}>
        <SidebarDrawerTitlebar
            onClose={onClose}
            onRootClose={onRootClose}
            title={t("enable_maps_confirm")}
        />
        <Stack py={"20px"} px={"8px"} spacing={"32px"}>
            <Box px={"8px"}>
                {" "}
                <Typography color="text.muted">
                    <Trans
                        i18nKey={"enable_maps_confirm_message"}
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
                {phase == "failed" && <InlineErrorIndicator />}
                <LoadingButton
                    loading={phase == "loading"}
                    color={"accent"}
                    fullWidth
                    onClick={onClick}
                >
                    {t("enable")}
                </LoadingButton>
                <FocusVisibleButton
                    color={"secondary"}
                    fullWidth
                    onClick={onClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </Stack>
    </Stack>
);

const ConfirmDisableMap: React.FC<ConfirmStepProps> = ({
    onClose,
    onRootClose,
    onClick,
    phase,
}) => (
    <Stack sx={{ gap: "4px", py: "12px" }}>
        <SidebarDrawerTitlebar
            onClose={onClose}
            onRootClose={onRootClose}
            title={t("disable_maps_confirm")}
        />
        <Stack py={"20px"} px={"8px"} spacing={"32px"}>
            <Box px={"8px"}>
                <Typography color="text.muted">
                    <Trans i18nKey={"disable_maps_confirm_message"} />
                </Typography>
            </Box>
            <Stack px={"8px"} spacing={"8px"}>
                {phase == "failed" && <InlineErrorIndicator />}
                <LoadingButton
                    loading={phase == "loading"}
                    color={"critical"}
                    size="large"
                    onClick={onClick}
                >
                    {t("disable")}
                </LoadingButton>
                <FocusVisibleButton
                    color={"secondary"}
                    size="large"
                    onClick={onClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </Stack>
    </Stack>
);
