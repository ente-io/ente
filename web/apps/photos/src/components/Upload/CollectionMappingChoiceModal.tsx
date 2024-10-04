import type { CollectionMapping } from "@/base/types/ipc";
import { FocusVisibleButton } from "@/new/photos/components/FocusVisibleButton";
import CloseIcon from "@mui/icons-material/Close";
import FolderIcon from "@mui/icons-material/Folder";
import FolderCopyIcon from "@mui/icons-material/FolderCopy";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";

interface CollectionMappingChoiceModalProps {
    open: boolean;
    onClose: () => void;
    didSelect: (mapping: CollectionMapping) => void;
}

export const CollectionMappingChoiceModal: React.FC<
    CollectionMappingChoiceModalProps
> = ({ open, onClose, didSelect }) => {
    return (
        <Dialog
            open={open}
            onClose={onClose}
            fullWidth
            PaperProps={{
                sx: {
                    paddingBlockEnd: "12px",
                    paddingInline: "12px",
                    maxWidth: "390px",
                },
            }}
        >
            <DialogTitle
                sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    "&&&": { paddingBlockEnd: 0 },
                }}
            >
                <Typography variant="large" fontWeight={"bold"}>
                    {t("multi_folder_upload")}
                </Typography>
                <IconButton
                    aria-label={t("close")}
                    color="secondary"
                    onClick={onClose}
                    sx={{ marginInlineEnd: "-12px" }}
                >
                    <CloseIcon />
                </IconButton>
            </DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: "16px" } }}>
                <Stack sx={{ gap: "16px" }}>
                    <Typography color="text.muted">
                        {t("upload_to_choice")}
                    </Typography>
                    <Stack sx={{ mt: "4px", gap: "12px" }}>
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
                </Stack>
            </DialogContent>
        </Dialog>
    );
};
