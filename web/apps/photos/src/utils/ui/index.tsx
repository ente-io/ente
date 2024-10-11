import { DialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import InfoOutlined from "@mui/icons-material/InfoRounded";
import { t } from "i18next";
import { Trans } from "react-i18next";
import { Subscription } from "types/billing";

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
