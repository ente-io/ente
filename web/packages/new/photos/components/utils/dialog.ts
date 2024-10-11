import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { openURL } from "@/new/photos/utils/web";
import { t } from "i18next";

export const downloadAppDialogAttributes = (): MiniDialogAttributes => {
    return {
        title: t("download_app"),
        message: t("download_app_message"),

        continue: {
            text: t("download"),
            action: downloadApp,
        },
        cancel: t("close"),
    };
};

const downloadApp = () => openURL("https://ente.io/download/desktop");
