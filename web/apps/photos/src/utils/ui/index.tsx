import { ensureElectron } from "@/base/electron";
import { AppUpdate } from "@/base/types/ipc";
import { openURL } from "@/new/photos/utils/web";
import { DialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import InfoOutlined from "@mui/icons-material/InfoRounded";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { Subscription } from "types/billing";

export const getDownloadAppMessage = (): DialogBoxAttributes => {
    return {
        title: t("download_app"),
        content: t("download_app_message"),

        proceed: {
            text: t("download"),
            action: downloadApp,
            variant: "accent",
        },
        close: {
            text: t("close"),
        },
    };
};

const downloadApp = () => openURL("https://ente.io/download/desktop");

export const getTrashFilesMessage = (
    deleteFileHelper,
): DialogBoxAttributes => ({
    title: t("TRASH_FILES_TITLE"),
    content: t("TRASH_FILES_MESSAGE"),
    proceed: {
        action: deleteFileHelper,
        text: t("MOVE_TO_TRASH"),
        variant: "critical",
        autoFocus: true,
    },
    close: { text: t("cancel") },
});

export const getTrashFileMessage = (deleteFileHelper): DialogBoxAttributes => ({
    title: t("TRASH_FILE_TITLE"),
    content: t("TRASH_FILE_MESSAGE"),
    proceed: {
        action: deleteFileHelper,
        text: t("MOVE_TO_TRASH"),
        variant: "critical",
        autoFocus: true,
    },
    close: { text: t("cancel") },
});

export const getUpdateReadyToInstallMessage = ({
    version,
}: AppUpdate): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: t("UPDATE_AVAILABLE"),
    content: t("UPDATE_INSTALLABLE_MESSAGE"),
    proceed: {
        action: () => ensureElectron().updateAndRestart(),
        text: t("INSTALL_NOW"),
        variant: "accent",
    },
    close: {
        text: t("INSTALL_ON_NEXT_LAUNCH"),
        variant: "secondary",
        action: () => ensureElectron().updateOnNextRestart(version),
    },
    staticBackdrop: true,
});

export const getUpdateAvailableForDownloadMessage = ({
    version,
}: AppUpdate): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: t("UPDATE_AVAILABLE"),
    content: t("UPDATE_AVAILABLE_MESSAGE"),
    close: {
        text: t("IGNORE_THIS_VERSION"),
        variant: "secondary",
        action: () => ensureElectron().skipAppUpdate(version),
    },
    proceed: {
        action: downloadApp,
        text: t("DOWNLOAD_AND_INSTALL"),
        variant: "accent",
    },
});

export const getRootLevelFileWithFolderNotAllowMessage =
    (): DialogBoxAttributes => ({
        icon: <InfoOutlined />,
        title: t("ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED"),
        content: (
            <Trans
                i18nKey={"ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED_MESSAGE"}
            />
        ),
        close: {},
    });

export const getExportDirectoryDoesNotExistMessage =
    (): DialogBoxAttributes => ({
        title: t("EXPORT_DIRECTORY_DOES_NOT_EXIST"),
        content: <Trans i18nKey={"EXPORT_DIRECTORY_DOES_NOT_EXIST_MESSAGE"} />,
        close: {},
    });

export const getSubscriptionPurchaseSuccessMessage = (
    subscription: Subscription,
): DialogBoxAttributes => ({
    title: t("SUBSCRIPTION_PURCHASE_SUCCESS_TITLE"),
    close: { variant: "accent" },
    content: (
        <Trans
            i18nKey="SUBSCRIPTION_PURCHASE_SUCCESS"
            values={{ date: subscription?.expiryTime }}
        />
    ),
});

export const getSessionExpiredMessage = (
    action: () => void,
): DialogBoxAttributes => ({
    title: t("session_expired"),
    content: t("session_expired_message"),

    nonClosable: true,
    proceed: {
        text: t("login"),
        action,
        variant: "accent",
    },
});
