/// <reference types="next/image-types/global" />

import { Box } from "@mui/material";
import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { t } from "i18next";
import warningRed from "./assets/warning-red.png";

export const trashFilesDialogAttributes = (
    count: number,
): Pick<MiniDialogAttributes, "title" | "message" | "illustration"> => ({
    title: t("trash_items_title", { count }),
    message: t("trash_items_message", { count }),
    illustration: (
        <Box
            component="img"
            src={warningRed.src}
            alt=""
            sx={{ width: 68, height: 64, objectFit: "contain" }}
        />
    ),
});
