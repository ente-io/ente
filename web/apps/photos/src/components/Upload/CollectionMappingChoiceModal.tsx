import type { CollectionMapping } from "@/base/types/ipc";
import {
    CenteredFlex,
    SpaceBetweenFlex,
} from "@ente/shared/components/Container";
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { Button, Dialog, DialogContent, Typography } from "@mui/material";
import { t } from "i18next";

interface CollectionMappingChoiceModalProps {
    open: boolean;
    onClose: () => void;
    didSelect: (mapping: CollectionMapping) => void;
}

export const CollectionMappingChoiceModal: React.FC<
    CollectionMappingChoiceModalProps
> = ({ open, onClose, didSelect }) => {
    const handleClose = dialogCloseHandler({ onClose });

    return (
        <Dialog open={open} onClose={handleClose} maxWidth={"sm"} fullWidth>
            <DialogTitleWithCloseButton onClose={onClose}>
                {t("MULTI_FOLDER_UPLOAD")}
            </DialogTitleWithCloseButton>
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
