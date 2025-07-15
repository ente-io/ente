import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Stack,
    TextField,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";

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
    onSubmit: (name: string) => void | Promise<void>;
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
                <UploaderNameInputForm
                    {...{ onClose, uploaderName, uploadFileCount, onSubmit }}
                />
            </DialogContent>
        </Dialog>
    );
};

/**
 * The form that obtains the textual input of the uploader name.
 *
 * It is kept as a separate component so that it gets recreated on prop changes
 * (e.g. uploaderName changes).
 */
export const UploaderNameInputForm: React.FC<
    Omit<UploaderNameInput, "open">
> = ({ onClose, uploaderName, uploadFileCount, onSubmit }) => {
    const formik = useFormik({
        initialValues: { value: uploaderName },
        onSubmit: async (values, { setFieldError }) => {
            const value = values.value;
            const setValueFieldError = (message: string) =>
                setFieldError("value", message);

            if (!value) {
                setValueFieldError(t("required"));
                return;
            }
            try {
                await onSubmit(value);
                onClose();
            } catch (e) {
                log.error(`Failed to submit input ${value}`, e);
                setValueFieldError(t("generic_error"));
            }
        },
    });

    return (
        <form onSubmit={formik.handleSubmit}>
            <TextField
                name="value"
                value={formik.values.value}
                onChange={formik.handleChange}
                type={"text"}
                fullWidth
                autoFocus
                margin="normal"
                hiddenLabel
                aria-label={t("name")}
                placeholder={t("name_placeholder")}
                disabled={formik.isSubmitting}
                error={!!formik.errors.value}
                // As an exception, we don't use an space character default here
                // since that skews dialog's look too much in the happy case.
                //
                // The downside is that there will be a layout shift on errors.
                helperText={formik.errors.value}
            />
            <Stack sx={{ mt: 1.5, gap: 1 }}>
                <LoadingButton
                    fullWidth
                    type="submit"
                    loading={formik.isSubmitting}
                    color="accent"
                >
                    {t("add_photos_count", { count: uploadFileCount })}
                </LoadingButton>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onClose}
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </Stack>
        </form>
    );
};
