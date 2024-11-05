import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { Link } from "@mui/material";
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
