import { ensureElectron } from "@/base/electron";
import { AppUpdate } from "@/base/types/ipc";
import { openURL } from "@/new/photos/utils/web";
import { DialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import InfoOutlined from "@mui/icons-material/InfoRounded";
import { Link } from "@mui/material";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { Subscription } from "types/billing";

export const getDownloadAppMessage = (): DialogBoxAttributes => {
    return {
        title: t("DOWNLOAD_APP"),
        content: t("DOWNLOAD_APP_MESSAGE"),

        proceed: {
            text: t("DOWNLOAD"),
            action: downloadApp,
            variant: "accent",
        },
        close: {
            text: t("CLOSE"),
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
    title: t("SESSION_EXPIRED"),
    content: t("SESSION_EXPIRED_MESSAGE"),

    nonClosable: true,
    proceed: {
        text: t("LOGIN"),
        action,
        variant: "accent",
    },
});

export const getMapEnableConfirmationDialog = (
    enableMapHelper,
): DialogBoxAttributes => ({
    title: t("ENABLE_MAPS"),
    content: (
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
    ),
    proceed: {
        action: enableMapHelper,
        text: t("enable"),
        variant: "accent",
    },
    close: { text: t("cancel") },
});

export const getMapDisableConfirmationDialog = (
    disableMapHelper,
): DialogBoxAttributes => ({
    title: t("DISABLE_MAPS"),
    content: <Trans i18nKey={"DISABLE_MAP_DESCRIPTION"} />,
    proceed: {
        action: disableMapHelper,
        text: t("disable"),
        variant: "accent",
    },
    close: { text: t("cancel") },
});

export const getEditorCloseConfirmationMessage = (
    doClose: () => void,
): DialogBoxAttributes => ({
    title: t("CONFIRM_EDITOR_CLOSE_MESSAGE"),
    content: t("CONFIRM_EDITOR_CLOSE_DESCRIPTION"),
    proceed: {
        action: doClose,
        text: t("CLOSE"),
        variant: "critical",
    },
    close: { text: t("cancel") },
});
