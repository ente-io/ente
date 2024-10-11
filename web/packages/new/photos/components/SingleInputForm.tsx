import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import log from "@/base/log";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    TextField,
    type TextFieldProps,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";

type SingleInputFormProps = Pick<
    TextFieldProps,
    "label" | "placeholder" | "autoComplete" | "autoFocus"
> & {
    /**
     * The initial value, if any, to prefill in the input.
     */
    initialValue?: string;
    /**
     * Title for the submit button.
     */
    submitButtonTitle: string;
    /**
     * Cancellation handler.
     *
     * This function is called when the user activates the cancel button in the
     * form.
     */
    onCancel: () => void;
    /**
     * Submission handler. A callback invoked when the submit button is pressed.
     *
     * During submission, the text input and the submit button are disabled, and
     * an indeterminate progress indicator is shown.
     *
     * If this function rejects then a generic error helper text is shown below
     * the text input, and the input (/ buttons) reenabled.
     *
     * @param name The current value of the text input.
     */
    onSubmit: ((name: string) => void) | ((name: string) => Promise<void>);
};

/**
 * A TextField and two buttons.
 *
 * A common requirement is taking a single textual input from the user. This is
 * a form suitable for that purpose - it is form containing a single MUI
 * {@link TextField}, with two accompanying buttons; one to submit, and one to
 * cancel.
 *
 * Submission is handled as an async function, during which the input is
 * disabled and a loading indicator is shown. Errors during submission are shown
 * as the helper text associated with the text field.
 */
export const SingleInputForm: React.FC<SingleInputFormProps> = ({
    initialValue,
    submitButtonTitle,
    onCancel,
    onSubmit,
    ...rest
}) => {
    const formik = useFormik({
        initialValues: {
            value: initialValue ?? "",
        },
        onSubmit: async (values, { setFieldError }) => {
            const value = values.value;
            if (!value) {
                setFieldError("value", t("required"));
                return;
            }
            try {
                await onSubmit(value);
            } catch (e) {
                log.error(`Failed to submit input ${value}`, e);
                setFieldError("value", t("generic_error"));
            }
        },
    });

    // Note: [Use space as default TextField helperText]
    //
    // For MUI text fields that use a conditional helperText, e.g. in case of
    // errors, use an space as the default helperText in the other cases to
    // avoid a layout shift when the helperText is conditionally shown.

    return (
        <form onSubmit={formik.handleSubmit}>
            <TextField
                name="value"
                value={formik.values.value}
                onChange={formik.handleChange}
                type="text"
                fullWidth
                margin="normal"
                disabled={formik.isSubmitting}
                error={!!formik.errors.value}
                helperText={formik.errors.value ?? " "}
                {...rest}
            />
            <Box sx={{ display: "flex", gap: "12px" }}>
                <FocusVisibleButton
                    size="large"
                    color="secondary"
                    onClick={onCancel}
                >
                    {t("cancel")}
                </FocusVisibleButton>
                <LoadingButton
                    size="large"
                    color="accent"
                    type="submit"
                    loading={formik.isSubmitting}
                >
                    {submitButtonTitle}
                </LoadingButton>
            </Box>
        </form>
    );
};

type SingleInputDialogProps = ModalVisibilityProps &
    Omit<SingleInputFormProps, "onCancel"> & {
        /** Title of the dialog. */
        title: string;
    };

/**
 * A dialog that can be used to ask for a single text input using a
 * {@link SingleInputForm}.
 *
 * If the submission handler provided to this component resolves successfully,
 * then the dialog is closed.
 *
 * See also: {@link CollectionNamer}, its older sibling.
 */
export const SingleInputDialog: React.FC<SingleInputDialogProps> = ({
    open,
    onClose,
    onSubmit,
    title,
    ...rest
}) => {
    const handleSubmit = async (value: string) => {
        await onSubmit(value);
        onClose();
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullWidth
            PaperProps={{ sx: { padding: "8px 4px 4px 4px" } }}
        >
            <DialogTitle>{title}</DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: 0 } }}>
                <SingleInputForm
                    onCancel={onClose}
                    onSubmit={handleSubmit}
                    {...rest}
                />
            </DialogContent>
        </Dialog>
    );
};
