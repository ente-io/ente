import CheckIcon from "@mui/icons-material/Check";
import { Box, Dialog, DialogContent, DialogTitle, Stack } from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { t } from "i18next";

type PublicLinkCreatedProps = ModalVisibilityProps & {
    /**
     * Callback invoked when the user presses the button to copy the newly
     * created link. The dialog also closes when this happens.
     */
    onCopyLink: () => void;
};

/**
 * A Dialog acknowledging the creation of a link to a public album, and offering
 * the user a choice to copy the newly created link.
 */
export const PublicLinkCreated: React.FC<PublicLinkCreatedProps> = ({
    open,
    onClose,
    onCopyLink,
}) => (
    <Dialog
        {...{ open, onClose }}
        disablePortal
        fullWidth
        slotProps={{ backdrop: { sx: { position: "absolute" } } }}
        sx={{ position: "absolute" }}
    >
        <DialogTitle sx={{ textAlign: "center" }}>
            {t("public_link_created")}
        </DialogTitle>
        <DialogContent>
            <Box sx={{ textAlign: "center" }}>
                <CheckIcon sx={{ fontSize: "48px" }} />
            </Box>
            <Stack sx={{ pt: 3, gap: 1 }}>
                <FocusVisibleButton
                    onClick={() => {
                        onCopyLink();
                        onClose();
                    }}
                    fullWidth
                >
                    {t("copy_link")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    onClick={onClose}
                    color="secondary"
                    fullWidth
                >
                    {t("done")}
                </FocusVisibleButton>
            </Stack>
        </DialogContent>
    </Dialog>
);
