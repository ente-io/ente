import {
    Stack,
    TextField,
    type ButtonProps,
    type TextFieldProps,
} from "@mui/material";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";

export type SingleInputFormProps = Pick<
    TextFieldProps,
    "label" | "placeholder" | "autoComplete" | "autoFocus" | "slotProps"
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
     * Color of the submit button.
     *
     * Default: "primary".
     */
    submitButtonColor?: ButtonProps["color"];
    /**
     * Cancellation handler.
     *
     * This function is called when the user activates the cancel button in the
     * form.
     *
     * If this is not provided, then only a full width submit button will be
     * shown in the form (below the input).
     */
    onCancel?: () => void;
    /**
     * Submission handler. A callback invoked when the submit button is pressed.
     *
     * During submission, the text input and the submit button are disabled, and
     * an indeterminate progress indicator is shown.
     *
     * If this function rejects then a generic error helper text is shown below
     * the text input, and the input (/ buttons) reenabled.
     *
     * This function is also passed an function that can be used to explicitly
     * set the error message that as shown below the text input when a specific
     * problem occurs during submission.
     *
     * @param name The current value of the text input.
     *
     * @param showError A function that can be called to set the error message
     * shown below the text input if submission fails.
     *
     * Note that if {@link showError} is called, then the {@link onSubmit}
     * function should not throw, otherwise the error message shown by
     * {@link showError} will get overwritten by the generic error message.
     */
    onSubmit:
        | ((name: string, showError: (message: string) => void) => void)
        | ((
              name: string,
              showError: (message: string) => void,
          ) => Promise<void>);
};

/**
 * A TextField and cancel/submit buttons.
 *
 * A common requirement is taking a single textual input from the user. This is
 * a form suitable for that purpose. It contains a single MUI {@link TextField}
 * and two accompanying buttons; one to submit, and one to cancel.
 *
 * Submission is handled as an async function, during which the input is
 * disabled and a loading indicator is shown. Errors during submission are shown
 * as the helper text associated with the text field.
 */
export const SingleInputForm: React.FC<SingleInputFormProps> = ({
    initialValue,
    submitButtonTitle,
    submitButtonColor,
    onCancel,
    onSubmit,
    ...rest
}) => {
    const formik = useFormik({
        initialValues: { value: initialValue ?? "" },
        onSubmit: async (values, { setFieldError }) => {
            const value = values.value;
            const showError = (message: string) =>
                setFieldError("value", message);

            if (!value) {
                showError(t("required"));
                return;
            }
            try {
                await onSubmit(value, showError);
            } catch (e) {
                log.error(`Failed to submit input ${value}`, e);
                showError(t("generic_error"));
            }
        },
    });

    const submitButton = (
        <LoadingButton
            fullWidth
            type="submit"
            loading={formik.isSubmitting}
            color={submitButtonColor ?? "primary"}
        >
            {submitButtonTitle}
        </LoadingButton>
    );

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
            {onCancel ? (
                <Stack direction="row" sx={{ gap: "12px" }}>
                    <FocusVisibleButton
                        fullWidth
                        color="secondary"
                        onClick={onCancel}
                    >
                        {t("cancel")}
                    </FocusVisibleButton>
                    {submitButton}
                </Stack>
            ) : (
                submitButton
            )}
        </form>
    );
};
