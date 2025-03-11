import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import log from "@/base/log";
import { Stack, TextField, type TextFieldProps } from "@mui/material";
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
    onCancel,
    onSubmit,
    ...rest
}) => {
    const formik = useFormik({
        initialValues: { value: initialValue ?? "" },
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
            <Stack direction="row" sx={{ gap: "12px" }}>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onCancel}
                >
                    {t("cancel")}
                </FocusVisibleButton>
                <LoadingButton
                    fullWidth
                    color="primary"
                    type="submit"
                    loading={formik.isSubmitting}
                >
                    {submitButtonTitle}
                </LoadingButton>
            </Stack>
        </form>
    );
};
