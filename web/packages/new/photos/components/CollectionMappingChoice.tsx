import { SpaceBetweenFlex } from "@/base/components/mui/Container";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import type { CollectionMapping } from "@/base/types/ipc";
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
import { DialogCloseIconButton } from "./mui/Dialog";

type CollectionMappingChoiceProps = ModalVisibilityProps & {
    /**
     * Callback invoked with the mapping choice selected by the user.
     *
     * The dialog is automatically closed before this callback is invoked.
     */
    onSelect: (mapping: CollectionMapping) => void;
};

/**
 * A {@link Dialog} that allow the user to choose a collection mapping.
 */
export const CollectionMappingChoice: React.FC<
    CollectionMappingChoiceProps
> = ({ open, onClose, onSelect }) => (
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
            <Typography sx={{ color: "text.muted" }}>
                {t("upload_to_choice")}
            </Typography>
            <Stack sx={{ gap: "12px" }}>
                <FocusVisibleButton
                    color="accent"
                    startIcon={<FolderIcon />}
                    onClick={() => {
                        onClose();
                        onSelect("root");
                    }}
                >
                    {t("upload_to_single_album")}
                </FocusVisibleButton>

                <FocusVisibleButton
                    color="accent"
                    startIcon={<FolderCopyIcon />}
                    onClick={() => {
                        onClose();
                        onSelect("parent");
                    }}
                >
                    {t("upload_to_album_per_folder")}
                </FocusVisibleButton>
            </Stack>
        </DialogContent>
    </Dialog>
);
