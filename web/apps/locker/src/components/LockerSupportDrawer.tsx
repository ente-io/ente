import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import NorthEastIcon from "@mui/icons-material/NorthEast";
import { Stack, Tooltip, Typography } from "@mui/material";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
} from "ente-base/components/RowButton";
import {
    TitledNestedSidebarDrawer,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { savedLogs } from "ente-base/log-web";
import { saveStringAsFile } from "ente-base/utils/web";
import { initiateEmail, openURL } from "ente-new/photos/utils/web";
import { t } from "i18next";
import React from "react";
import { Trans } from "react-i18next";

export const LockerSupportDrawer: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const { showMiniDialog } = useBaseContext();

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleHelp = () => openURL("https://ente.io/help/photos/");
    const handleBlog = () => openURL("https://ente.io/blog/");
    const handleRequestFeature = () =>
        openURL("https://github.com/ente-io/ente/discussions");
    const handleSupport = () => initiateEmail("support@ente.io");

    const viewLogs = async () => {
        log.info("Viewing logs");
        const electron = globalThis.electron;
        if (electron) {
            await electron.openLogDirectory();
        } else {
            saveStringAsFile(savedLogs(), `ente-web-logs-${Date.now()}.txt`);
        }
    };

    const confirmViewLogs = () =>
        showMiniDialog({
            title: t("view_logs"),
            message: <Trans i18nKey="view_logs_message" />,
            continue: { text: t("view_logs"), action: viewLogs },
        });

    return (
        <TitledNestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
            title={t("help")}
        >
            <Stack sx={{ px: 2, py: 1, gap: 3 }}>
                <RowButtonGroup>
                    <RowButton
                        endIcon={<InfoOutlinedIcon />}
                        label={t("ente_help")}
                        onClick={handleHelp}
                    />
                </RowButtonGroup>
                <RowButtonGroup>
                    <RowButton
                        endIcon={<NorthEastIcon />}
                        label={t("blog")}
                        onClick={handleBlog}
                    />
                    <RowButtonDivider />
                    <RowButton
                        endIcon={<NorthEastIcon />}
                        label={t("request_feature")}
                        onClick={handleRequestFeature}
                    />
                </RowButtonGroup>
                <RowButtonGroup>
                    <RowButton
                        endIcon={<ChevronRightIcon />}
                        label={
                            <Tooltip title="support@ente.io">
                                <Typography sx={{ fontWeight: "medium" }}>
                                    {t("support")}
                                </Typography>
                            </Tooltip>
                        }
                        onClick={handleSupport}
                    />
                </RowButtonGroup>
                <RowButtonGroup>
                    <RowButton
                        endIcon={<ChevronRightIcon />}
                        label={t("view_logs")}
                        onClick={confirmViewLogs}
                    />
                </RowButtonGroup>
            </Stack>
        </TitledNestedSidebarDrawer>
    );
};
