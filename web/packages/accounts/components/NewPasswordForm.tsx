import { Input, TextField, Typography } from "@mui/material";
import { isWeakPassword } from "ente-accounts/utils/password";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import { useCallback, useState } from "react";
import { Trans } from "react-i18next";
import { PasswordStrengthHint } from "./PasswordStrength";

export interface NewPasswordFormProps {
    /**
     * The email of the user whose password we are setting.
     *
     * This is used to show a hidden input field of type email (and the provided
     * value) to aid password managers to detect and save the new password,
     * associating it with the user's email.
     */
    userEmail: string;
    /**
     * The title of the form's submit button.
     */
    submitButtonTitle: string;
    /**
     * Submission handler. A callback invoked when the submit button is pressed.
     *
     * @param password The new password entered by the user. The form will first
     * check that both of the passwords entered by the user match, and that the
     * password is not too weak.
     *
     * @param setPasswordsFieldError A function that can be called to show an
     * error message below the password fields.
     */
    onSubmit: (
        password: string,
        setPasswordsFieldError: (message: string) => void,
    ) => Promise<void>;
}

/**
 * A form showing two password input fields, a password strength indicator, and
 * a submit button.
 *
 * This form can be used both for the initial setup of the password, and for
 * later changing it.
 */
export const NewPasswordForm: React.FC<NewPasswordFormProps> = ({
    userEmail,
    submitButtonTitle,
    onSubmit,
}) => {
    const [showPassword, setShowPassword] = useState(false);

    const handleToggleShowHidePassword = useCallback(
        () => setShowPassword((show) => !show),
        [],
    );

    const formik = useFormik({
        initialValues: { password: "", confirmPassword: "" },
        onSubmit: async ({ password, confirmPassword }, { setFieldError }) => {
            const setPasswordsFieldError = (message: string) =>
                setFieldError("confirmPassword", message);

            if (!confirmPassword) {
                setPasswordsFieldError(t("required"));
                return;
            }

            if (password != confirmPassword) {
                setPasswordsFieldError(t("password_mismatch_error"));
                return;
            }

            try {
                await onSubmit(password, setPasswordsFieldError);
            } catch (e) {
                log.error("Could not set password", e);
                setPasswordsFieldError(t("generic_error"));
            }
        },
    });

    return (
        <form onSubmit={formik.handleSubmit}>
            <Typography variant="small" sx={{ mb: 2, color: "text.muted" }}>
                {t("pick_password_hint")}
            </Typography>

            <Input
                sx={{ display: "none" }}
                name="email"
                type="email"
                autoComplete="username"
                value={userEmail}
            />
            <TextField
                name="password"
                autoComplete="new-password"
                type={showPassword ? "text" : "password"}
                label={t("password")}
                value={formik.values.password}
                onChange={formik.handleChange}
                disabled={formik.isSubmitting}
                fullWidth
                autoFocus
                slotProps={{
                    input: {
                        endAdornment: (
                            <ShowHidePasswordInputAdornment
                                showPassword={showPassword}
                                onToggle={handleToggleShowHidePassword}
                            />
                        ),
                    },
                }}
            />
            <TextField
                name="confirmPassword"
                autoComplete="new-password"
                type="password"
                label={t("confirm_password")}
                value={formik.values.confirmPassword}
                onChange={formik.handleChange}
                error={!!formik.errors.confirmPassword}
                // See: [Note: Use space as default TextField helperText]
                helperText={formik.errors.confirmPassword ?? " "}
                disabled={formik.isSubmitting}
                fullWidth
            />
            <PasswordStrengthHint password={formik.values.password} />

            <Typography
                variant="small"
                sx={{ color: "text.muted", my: 2, mb: 4 }}
            >
                <Trans i18nKey={"pick_password_caution"} />
            </Typography>

            <LoadingButton
                color="accent"
                type="submit"
                loading={formik.isSubmitting}
                disabled={isWeakPassword(formik.values.password)}
                fullWidth
            >
                {submitButtonTitle}
            </LoadingButton>
            <Typography
                variant="small"
                sx={(theme) => ({
                    textAlign: "center",
                    mt: 1,
                    color: "text.muted",
                    minHeight: theme.typography.small.lineHeight,
                })}
            >
                {formik.isSubmitting ? t("key_generation_in_progress") : ""}
            </Typography>
        </form>
    );
};
