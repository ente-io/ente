import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { ensureElectron } from "@/base/electron";
import type { AppUpdate } from "@/base/types/ipc";
import { openURL } from "@/new/photos/utils/web";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import { t } from "i18next";

export const downloadAppDialogAttributes = (): MiniDialogAttributes => ({
    title: t("download_app"),
    message: t("download_app_message"),
    continue: { text: t("download"), action: downloadApp },
});

const downloadApp = () => openURL("https://ente.io/download/desktop");

export const updateReadyToInstallDialogAttributes = ({
    version,
}: AppUpdate): MiniDialogAttributes => ({
    title: t("update_available"),
    message: t("update_installable_message"),
    icon: <AutoAwesomeOutlinedIcon />,
    nonClosable: true,
    continue: {
        text: t("install_now"),
        action: () => ensureElectron().updateAndRestart(),
    },
    cancel: {
        text: t("install_on_next_launch"),
        action: () => ensureElectron().updateOnNextRestart(version),
    },
});

export const updateAvailableForDownloadDialogAttributes = ({
    version,
}: AppUpdate): MiniDialogAttributes => ({
    title: t("update_available"),
    message: t("update_available_message"),
    icon: <AutoAwesomeOutlinedIcon />,
    continue: { text: t("download_and_install"), action: downloadApp },
    cancel: {
        text: t("ignore_this_version"),
        action: () => ensureElectron().skipAppUpdate(version),
    },
});
