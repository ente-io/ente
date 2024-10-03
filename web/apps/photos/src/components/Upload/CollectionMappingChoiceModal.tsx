import type { CollectionMapping } from "@/base/types/ipc";
import FolderIcon from "@mui/icons-material/Folder";
import FolderCopyIcon from "@mui/icons-material/FolderCopy";
import {
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
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
                    padding: "8px 12px",
                    maxWidth: "390px",
                },
            }}
        >
            <DialogTitle sx={{ "&&&": { paddingBlockEnd: 0 } }}>
                <Typography variant="large" fontWeight={"bold"}>
                    {t("MULTI_FOLDER_UPLOAD")}
                </Typography>
            </DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: "16px" } }}>
                <Stack sx={{ gap: "16px" }}>
                    <Typography color="text.muted" mt={0}>
                        {t("UPLOAD_STRATEGY_CHOICE")}
                    </Typography>
                    <Stack sx={{ gap: 1 }}>
                        <Button
                            size="medium"
                            color="accent"
                            startIcon={<FolderIcon />}
                            onClick={() => {
                                onClose();
                                didSelect("root");
                            }}
                        >
                            {t("UPLOAD_STRATEGY_SINGLE_COLLECTION")}
                        </Button>

                        <Button
                            size="medium"
                            color="accent"
                            startIcon={<FolderCopyIcon />}
                            onClick={() => {
                                onClose();
                                didSelect("parent");
                            }}
                        >
                            {t("UPLOAD_STRATEGY_COLLECTION_PER_FOLDER")}
                        </Button>
                    </Stack>
                </Stack>
            </DialogContent>
        </Dialog>
    );
};
