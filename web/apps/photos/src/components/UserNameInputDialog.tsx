import DialogBox from "@ente/shared/components/DialogBox/base";
import DialogIcon from "@ente/shared/components/DialogBox/DialogIcon";
import SingleInputForm from "@ente/shared/components/SingleInputForm";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import { DialogContent, DialogTitle, Typography } from "@mui/material";
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
        <DialogBox maxWidth="xs" open={open} onClose={onClose}>
            <DialogIcon icon={<AutoAwesomeOutlinedIcon />} />

            <DialogTitle>{t("ENTER_NAME")}</DialogTitle>

            <DialogContent>
                <Typography color={"text.muted"} pb={1}>
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
        </DialogBox>
    );
}
