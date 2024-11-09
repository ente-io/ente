import SingleInputForm from "@ente/shared/components/SingleInputForm";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Typography,
} from "@mui/material";
import { t } from "i18next";

export default function UserNameInputDialog({
    open,
    onClose,
    onNameSubmit,
    toUploadFilesCount,
    uploaderName,
}) {
    const handleSubmit = async (inputValue: string) => {
        onClose();
        await onNameSubmit(inputValue);
    };

    return (
        <Dialog
            fullWidth
            PaperProps={{ sx: { maxWidth: "346px" } }}
            open={open}
            onClose={onClose}
        >
            <Box
                sx={{
                    padding: "24px 16px 0px 16px",
                    svg: {
                        width: "44px",
                        height: "44px",
                    },
                    color: (theme) => theme.colors.stroke.muted,
                }}
            >
                {<AutoAwesomeOutlinedIcon />}
            </Box>
            <DialogTitle>{t("enter_name")}</DialogTitle>

            <DialogContent>
                <Typography color={"text.muted"} sx={{ pb: 1 }}>
                    {t("PUBLIC_UPLOADER_NAME_MESSAGE")}
                </Typography>
                <SingleInputForm
                    hiddenLabel
                    initialValue={uploaderName}
                    callback={handleSubmit}
                    placeholder={t("NAME_PLACEHOLDER")}
                    buttonText={t("add_photos_count", {
                        count: toUploadFilesCount ?? 0,
                    })}
                    fieldType="text"
                    blockButton
                    secondaryButtonAction={onClose}
                />
            </DialogContent>
        </Dialog>
    );
}
