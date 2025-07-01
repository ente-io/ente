import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { Link } from "@mui/material";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { pt } from "ente-base/i18n";
import { t } from "i18next";
import { Trans } from "react-i18next";

export const confirmEnableMapsDialogAttributes = (
    onConfirm: () => void,
): MiniDialogAttributes => ({
    title: t("enable_maps_confirm"),
    message: (
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
    ),
    continue: { text: t("enable"), action: onConfirm },
});

export const confirmDisableMapsDialogAttributes = (
    onConfirm: () => void,
): MiniDialogAttributes => ({
    title: t("disable_maps_confirm"),
    message: <Trans i18nKey={"disable_maps_confirm_message"} />,
    continue: { text: t("disable"), color: "critical", action: onConfirm },
});

/**
 * Create attributes for a {@link MiniDialog} notifying the user that some of
 * the files were not processed because they belonged to other users.
 */
export const notifyOthersFilesDialogAttributes = () => ({
    // TODO(RE):
    title: pt("Note"),
    icon: <InfoOutlinedIcon />,
    // TODO(RE):
    message: pt("Files added by other users were not processed"),
    cancel: t("ok"),
});
