import type { CollectionMapping } from "@/base/types/ipc";
import { SpaceBetweenFlex } from "@/new/photos/components/mui";
import { CenteredFlex } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import {
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
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
        <Dialog open={open} onClose={onClose} maxWidth={"sm"} fullWidth>
            <DialogTitle>
                <SpaceBetweenFlex>
                    {t("MULTI_FOLDER_UPLOAD")}
                    <IconButton
                        aria-label={t("close")}
                        color="secondary"
                        onClick={onClose}
                    >
                        <CloseIcon />
                    </IconButton>
                </SpaceBetweenFlex>
            </DialogTitle>
            <DialogContent>
                <CenteredFlex mb={1}>
                    <Typography color="text.muted">
                        {t("UPLOAD_STRATEGY_CHOICE")}
                    </Typography>
                </CenteredFlex>
                <SpaceBetweenFlex px={2}>
                    <Button
                        size="medium"
                        color="accent"
                        onClick={() => {
                            onClose();
                            didSelect("root");
                        }}
                    >
                        {t("UPLOAD_STRATEGY_SINGLE_COLLECTION")}
                    </Button>

                    <strong>{t("OR")}</strong>

                    <Button
                        size="medium"
                        color="accent"
                        onClick={() => {
                            onClose();
                            didSelect("parent");
                        }}
                    >
                        {t("UPLOAD_STRATEGY_COLLECTION_PER_FOLDER")}
                    </Button>
                </SpaceBetweenFlex>
            </DialogContent>
        </Dialog>
    );
};
