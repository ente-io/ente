import type { CollectionMapping } from "@/base/types/ipc";
import { FocusVisibleButton } from "@/new/photos/components/FocusVisibleButton";
import FolderIcon from "@mui/icons-material/Folder";
import FolderCopyIcon from "@mui/icons-material/FolderCopy";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React from "react";
import { SpaceBetweenFlex } from "./mui";
import { DialogCloseIconButton, type DialogVisiblityProps } from "./mui/Dialog";

type CollectionMappingChoiceModalProps = DialogVisiblityProps & {
    didSelect: (mapping: CollectionMapping) => void;
};

/**
 * A {@link Dialog} that allow the user to choose a collection mapping.
 * @param param0
 * @returns
 */
export const CollectionMappingChoiceDialog: React.FC<
    CollectionMappingChoiceModalProps
> = ({ open, onClose, didSelect }) => (
    <Dialog
        open={open}
        onClose={onClose}
        fullWidth
        PaperProps={{ sx: { maxWidth: "360px", padding: "12px" } }}
    >
        <SpaceBetweenFlex sx={{ paddingInlineEnd: "4px" }}>
            <DialogTitle>{t("multi_folder_upload")}</DialogTitle>
            <DialogCloseIconButton {...{ onClose }} />
        </SpaceBetweenFlex>

        <DialogContent
            sx={{
                display: "flex",
                flexDirection: "column",
                "&&": { paddingBlockStart: "12px" },
                gap: "20px",
            }}
        >
            <Typography color="text.muted">{t("upload_to_choice")}</Typography>
            <Stack sx={{ gap: "12px" }}>
                <FocusVisibleButton
                    size="medium"
                    color="accent"
                    startIcon={<FolderIcon />}
                    onClick={() => {
                        onClose();
                        didSelect("root");
                    }}
                >
                    {t("upload_to_single_album")}
                </FocusVisibleButton>

                <FocusVisibleButton
                    size="medium"
                    color="accent"
                    startIcon={<FolderCopyIcon />}
                    onClick={() => {
                        onClose();
                        didSelect("parent");
                    }}
                >
                    {t("upload_to_album_per_folder")}
                </FocusVisibleButton>
            </Stack>
        </DialogContent>
    </Dialog>
);
