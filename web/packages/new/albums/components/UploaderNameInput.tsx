import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import SingleInputForm from "@ente/shared/components/SingleInputForm";
import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Typography,
    useMediaQuery,
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
    // Make the dialog fullscreen if it starts to get too squished.
    const fullScreen = useMediaQuery("(width < 400px)");

    const handleSubmit = async (inputValue: string) => {
        onClose();
        await onSubmit(inputValue);
    };

    return (
        <Dialog
            {...{ open, onClose, fullScreen }}
            slotProps={{
                paper: { sx: fullScreen ? {} : { maxWidth: "346px" } },
            }}
            fullWidth
        >
            <Box
                sx={(theme) => ({
                    padding: "24px 16px 0px 16px",
                    svg: { width: "44px", height: "44px" },
                    color: theme.vars.palette.stroke.muted,
                })}
            >
                {<AutoAwesomeOutlinedIcon />}
            </Box>
            <DialogTitle>{t("enter_name")}</DialogTitle>
            <DialogContent>
                <Typography sx={{ color: "text.muted", pb: 1 }}>
                    {t("uploader_name_hint")}
                </Typography>
                <SingleInputForm
                    hiddenLabel
                    initialValue={uploaderName}
                    callback={handleSubmit}
                    placeholder={t("name_placeholder")}
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
