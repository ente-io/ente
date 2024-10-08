import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import log from "@/base/log";
import { wait } from "@/utils/promise";
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
import type { DialogVisibilityProps } from "./mui/Dialog";

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
     * Submission handler.
     *
     * During submission, the text input and the submit button are disabled, and
     * an indeterminate progress indicator is shown.
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
export const SingleInputFormV2: React.FC<SingleInputFormProps> = ({
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

export const SingleInputDialogTest: React.FC<DialogVisibilityProps> = ({
    open,
    onClose,
}) => {
    // const handleSubmit: SingleInputFormProps["callback"] = async (
    //     inputValue,
    //     setFieldError,
    // ) => {
    //     try {
    //         await onSubmit(inputValue);
    //         onClose();
    //     } catch (e) {
    //         log.error(`Error when submitting value ${inputValue}`, e);
    //         setFieldError(t("generic_error_retry"));
    //     }
    // };

    const handleSubmit = async (value: string) => {
        await wait(3000);
        if (value == "t") throw new Error("test");
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullWidth
            PaperProps={{ sx: { padding: "8px 4px 4px 4px" } }}
        >
            <DialogTitle>{"New person"}</DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: 0 } }}>
                <SingleInputFormV2
                    autoComplete="name"
                    autoFocus
                    label="Add name"
                    placeholder="Enter name"
                    initialValue="tt"
                    submitButtonTitle="Add person"
                    onCancel={onClose}
                    onSubmit={handleSubmit}
                />
            </DialogContent>
        </Dialog>
    );
};
