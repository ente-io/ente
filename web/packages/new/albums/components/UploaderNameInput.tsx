import type { ModalVisibilityProps } from "@/base/components/utils/modal";
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

type UploaderNameInput = ModalVisibilityProps & {
    /**
     * The existing uploader name to prefill.
     */
    uploaderName: string;
    /**
     * Count of the number of files that the uploader is trying to upload.
     */
    uploadFileCount: number;
    /**
     * Callback invoked when the user presses submit after entering a name.
     */
    onSubmit: (name: string) => Promise<void>;
};

/**
 * A dialog asking the uploader to a public album to provide their name so that
 * other folks can know who uploaded a given photo in the shared album.
 */
export const UploaderNameInput: React.FC<UploaderNameInput> = ({
    open,
    onClose,
    uploaderName,
    uploadFileCount,
    onSubmit,
}) => {
    const handleSubmit = async (inputValue: string) => {
        onClose();
        await onSubmit(inputValue);
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
                        count: uploadFileCount,
                    })}
                    fieldType="text"
                    blockButton
                    secondaryButtonAction={onClose}
                />
            </DialogContent>
        </Dialog>
    );
};
