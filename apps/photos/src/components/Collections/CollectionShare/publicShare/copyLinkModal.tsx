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
interface Iprops {
    open: boolean;
    onClose: () => void;
    handleCancel: () => void;
    copyToClipboardHelper: () => void;
}
export default function CopyLinkModal({
    open,
    onClose,
    handleCancel,
    copyToClipboardHelper,
}: Iprops) {
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
                <Button onClick={handleCancel} color="secondary" size={"large"}>
                    {t("DONE")}
                </Button>
                <Button
                    onClick={copyToClipboardHelper}
                    size={"large"}
                    color="primary"
                    autoFocus
                >
                    {t("COPY_LINK")}
                </Button>
            </DialogActions>
        </DialogBoxBase>
    );
}
