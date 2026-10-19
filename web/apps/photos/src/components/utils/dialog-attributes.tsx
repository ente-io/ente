import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { t } from "i18next";
import { DialogWarningIllustration } from "./DialogWarningIllustration";

export const trashFilesDialogAttributes = (
    count: number,
    onConfirm: () => void | Promise<void>,
): MiniDialogAttributes => ({
    title: t("trash_items_title", {
        count,
        fallbackLng: false,
        defaultValue: t(count === 1 ? "trash_file_title" : "trash_files_title"),
    }),
    message: t("trash_items_message", {
        count,
        fallbackLng: false,
        defaultValue: t(
            count === 1 ? "trash_file_message" : "trash_files_message",
        ),
    }),
    illustration: <DialogWarningIllustration color="red" />,
    continue: {
        text: t("move_to_trash"),
        color: "critical",
        action: onConfirm,
    },
});

export const notifyOthersFilesDialogAttributes = () => ({
    title: t("note"),
    icon: <InfoOutlinedIcon />,
    message: t("unowned_files_not_processed"),
    cancel: t("ok"),
});

export const notifyUnsupportedSharedFavoritesDialogAttributes = () => ({
    title: t("note"),
    icon: <InfoOutlinedIcon />,
    message: t("unsupported_shared_favorites_not_processed"),
    cancel: t("ok"),
});
