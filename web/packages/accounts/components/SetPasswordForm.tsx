import { isWeakPassword } from "@/accounts/utils/password";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import ShowHidePassword from "@ente/shared/components/Form/ShowHidePassword";
import { Box, Input, TextField, Typography } from "@mui/material";
import { Formik } from "formik";
import { t } from "i18next";
import React, { useState } from "react";
import { Trans } from "react-i18next";
import * as Yup from "yup";
import { PasswordStrengthHint } from "./PasswordStrength";

export interface SetPasswordFormProps {
    userEmail: string;
    callback: (
        passphrase: string,
        setFieldError: (
            field: keyof SetPasswordFormValues,
            message: string,
        ) => void,
    ) => Promise<void>;
    buttonText: string;
}

export interface SetPasswordFormValues {
    passphrase: string;
    confirm: string;
}

function SetPasswordForm(props: SetPasswordFormProps) {
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleClickShowPassword = () => {
        setShowPassword(!showPassword);
    };

    const handleMouseDownPassword = (
        event: React.MouseEvent<HTMLButtonElement>,
    ) => {
        event.preventDefault();
    };

    const onSubmit = async (
        values: SetPasswordFormValues,
        {
            setFieldError,
        }: {
            setFieldError: (
                field: keyof SetPasswordFormValues,
                message: string,
            ) => void;
        },
    ) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                await props.callback(passphrase, setFieldError);
            } else {
                setFieldError("confirm", t("password_mismatch_error"));
            }
        } catch (e) {
            const message = e instanceof Error ? e.message : "";
            setFieldError("confirm", `${t("generic_error_retry")} ${message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Formik<SetPasswordFormValues>
            initialValues={{ passphrase: "", confirm: "" }}
            validationSchema={Yup.object().shape({
                passphrase: Yup.string().required(t("required")),
                confirm: Yup.string().required(t("required")),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={onSubmit}
        >
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <Typography
                        variant="small"
                        sx={{ mb: 2, color: "text.muted" }}
                    >
                        {t("pick_password_hint")}
                    </Typography>

                    <Input
                        sx={{ display: "none" }}
                        name="email"
                        id="email"
                        autoComplete="username"
                        type="email"
                        value={props.userEmail}
                    />
                    <TextField
                        fullWidth
                        name="password"
                        id="password"
                        autoComplete="new-password"
                        type={showPassword ? "text" : "password"}
                        label={t("password")}
                        value={values.passphrase}
                        onChange={handleChange("passphrase")}
                        error={Boolean(errors.passphrase)}
                        helperText={errors.passphrase}
                        autoFocus
                        disabled={loading}
                        slotProps={{
                            input: {
                                endAdornment: (
                                    <ShowHidePassword
                                        showPassword={showPassword}
                                        handleClickShowPassword={
                                            handleClickShowPassword
                                        }
                                        handleMouseDownPassword={
                                            handleMouseDownPassword
                                        }
                                    />
                                ),
                            },
                        }}
                    />
                    <TextField
                        fullWidth
                        name="confirm-password"
                        id="confirm-password"
                        autoComplete="new-password"
                        type="password"
                        label={t("confirm_password")}
                        value={values.confirm}
                        onChange={handleChange("confirm")}
                        disabled={loading}
                        error={Boolean(errors.confirm)}
                        helperText={errors.confirm}
                    />
                    <PasswordStrengthHint password={values.passphrase} />

                    <Typography variant="small" sx={{ my: 2 }}>
                        <Trans i18nKey={"pick_password_caution"} />
                    </Typography>

                    <Box sx={{ mt: 4, mb: 2 }}>
                        <LoadingButton
                            fullWidth
                            color="accent"
                            type="submit"
                            loading={loading}
                            disabled={isWeakPassword(values.passphrase)}
                        >
                            {props.buttonText}
                        </LoadingButton>
                        {loading && (
                            <Typography
                                variant="small"
                                sx={{
                                    textAlign: "center",
                                    mt: 1,
                                    color: "text.muted",
                                }}
                            >
                                {t("key_generation_in_progress")}
                            </Typography>
                        )}
                    </Box>
                </form>
            )}
        </Formik>
    );
}
export default SetPasswordForm;
