import { Stack, styled, Typography } from "@mui/material";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isHTTP401Error } from "ente-base/http";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import OtpInput from "react-otp-input";

interface Verify2FACodeFormProps {
    /**
     * Called when the user submits the OTP.
     *
     * The submission can happen in two ways:
     * 1. The fill-in all the required 6 digits, or
     * 2. They press the "Enable" button.
     *
     * The form will stay in a submitting state until this callback returns.
     *
     * @param otp The OTP that the user entered.
     */
    onSubmit: (otp: string) => Promise<void>;
    /**
     * The label for the submit button.
     */
    submitButtonText: string;
}

/**
 * A form that can be used to ask the user to fill in a 6 digit OTP that their
 * authenticator app is providing them with.
 */
export const Verify2FACodeForm: React.FC<Verify2FACodeFormProps> = ({
    onSubmit,
    submitButtonText,
}) => {
    const [shouldAutoFocus, setShouldAutoFocus] = useState(true);

    const {
        values,
        errors,
        handleChange,
        handleSubmit,
        submitForm,
        isSubmitting,
    } = useFormik<{ otp: string }>({
        initialValues: { otp: "" },
        validateOnBlur: false,
        validateOnChange: false,
        onSubmit: async ({ otp }, { setFieldError, resetForm }) => {
            try {
                await onSubmit(otp);
                resetForm(); // Prevent resubmission via the useEffect.
            } catch (e) {
                log.error("Failed to submit 2FA code", e);
                resetForm();
                setFieldError(
                    "otp",
                    isHTTP401Error(e)
                        ? t("incorrect_code")
                        : t("generic_error"),
                );
                // Workaround (toggling shouldAutoFocus) to reset the focus back
                // to the first input field in case of errors.
                // https://github.com/devfolioco/react-otp-input/issues/420
                setShouldAutoFocus(false);
                setTimeout(() => setShouldAutoFocus(true), 100);
            }
        },
    });

    useEffect(() => {
        if (values.otp.length == 6 && !isSubmitting) void submitForm();
    }, [values, isSubmitting, submitForm]);

    return (
        <form onSubmit={handleSubmit}>
            <Stack sx={{ gap: 3, textAlign: "center" }}>
                <Typography variant="small" sx={{ color: "text.muted" }}>
                    {t("enter_two_factor_otp")}
                </Typography>
                <OtpInput
                    containerStyle={{ justifyContent: "center" }}
                    shouldAutoFocus={shouldAutoFocus}
                    value={values.otp}
                    onChange={handleChange("otp")}
                    numInputs={6}
                    renderSeparator={<span>-</span>}
                    renderInput={(props) => <IndividualInput {...props} />}
                />
                {errors.otp && (
                    <Typography variant="mini" sx={{ color: "critical.main" }}>
                        {errors.otp}
                    </Typography>
                )}
                <LoadingButton
                    type="submit"
                    color="accent"
                    fullWidth
                    loading={isSubmitting}
                    disabled={values.otp.length < 6}
                >
                    {submitButtonText}
                </LoadingButton>
            </Stack>
        </form>
    );
};

const IndividualInput = styled("input")(
    ({ theme }) => `
    font-size: 1.5rem;
    padding: 4px;
    width: 40px !important;
    aspect-ratio: 1;
    margin-inline: 6px;
    border: 1px solid ${theme.vars.palette.accent.main};
    border-radius: 1px;
    outline-color: ${theme.vars.palette.accent.light};
    transition: 0.5s;
    ${theme.breakpoints.down("sm")} {
        font-size: 1rem;
        padding: 4px;
        width: 32px !important;
    }
`,
);
