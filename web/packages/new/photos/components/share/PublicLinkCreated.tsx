import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { VerticallyCentered } from "@ente/shared/components/Container";
import DialogBoxBase from "@ente/shared/components/DialogBox/base";
import Check from "@mui/icons-material/Check";
import {
    Box,
    Button,
    DialogActions,
    DialogContent,
    Typography,
} from "@mui/material";
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
}) => {
    return (
        <DialogBoxBase
            open={open}
            onClose={onClose}
            disablePortal
            BackdropProps={{ sx: { position: "absolute" } }}
            sx={{ position: "absolute" }}
            PaperProps={{
                sx: { p: 1 },
            }}
        >
            <DialogContent>
                <VerticallyCentered>
                    <Typography fontWeight={"bold"}>
                        {t("PUBLIC_LINK_CREATED")}
                    </Typography>
                    <Box pt={2}>
                        <Check sx={{ fontSize: "48px" }} />
                    </Box>
                </VerticallyCentered>
            </DialogContent>
            <DialogActions>
                <Button onClick={onClose} color="secondary" size={"large"}>
                    {t("DONE")}
                </Button>
                <Button
                    onClick={() => {
                        onCopyLink();
                        onClose();
                    }}
                    size={"large"}
                    color="primary"
                    autoFocus
                >
                    {t("COPY_LINK")}
                </Button>
            </DialogActions>
        </DialogBoxBase>
    );
};
