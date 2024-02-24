import { sendOtt } from "@ente/accounts/api/user";
import { isWeakPassword } from "@ente/accounts/utils";
import { generateKeyAndSRPAttributes } from "@ente/accounts/utils/srp";
import SubmitButton from "@ente/shared/components/SubmitButton";
import {
    generateAndSaveIntermediateKeyAttributes,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { LS_KEYS, setData } from "@ente/shared/storage/localStorage";
import { Formik, FormikHelpers } from "formik";
import React, { useState } from "react";
import * as Yup from "yup";

import { PasswordStrengthHint } from "@ente/accounts/components/PasswordStrength";
import { PAGES } from "@ente/accounts/constants/pages";
import { APPS } from "@ente/shared/apps/constants";
import { VerticallyCentered } from "@ente/shared/components//Container";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import ShowHidePassword from "@ente/shared/components/Form/ShowHidePassword";
import LinkButton from "@ente/shared/components/LinkButton";
import { logError } from "@ente/shared/sentry";
import {
    setJustSignedUp,
    setLocalReferralSource,
} from "@ente/shared/storage/localStorage/helpers";
import { SESSION_KEYS } from "@ente/shared/storage/sessionStorage";
import InfoOutlined from "@mui/icons-material/InfoOutlined";
import {
    Box,
    Checkbox,
    FormControlLabel,
    FormGroup,
    IconButton,
    InputAdornment,
    Link,
    TextField,
    Tooltip,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import { NextRouter } from "next/router";
import { Trans } from "react-i18next";

interface FormValues {
    email: string;
    passphrase: string;
    confirm: string;
    referral: string;
}

interface SignUpProps {
    router: NextRouter;
    login: () => void;
    appName: APPS;
}

export default function SignUp({ router, appName, login }: SignUpProps) {
    const [acceptTerms, setAcceptTerms] = useState(false);
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

    const registerUser = async (
        { email, passphrase, confirm, referral }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>,
    ) => {
        try {
            if (passphrase !== confirm) {
                setFieldError("confirm", t("PASSPHRASE_MATCH_ERROR"));
                return;
            }
            setLoading(true);
            try {
                setData(LS_KEYS.USER, { email });
                setLocalReferralSource(referral);
                await sendOtt(appName, email);
            } catch (e) {
                setFieldError("confirm", `${t("UNKNOWN_ERROR")} ${e.message}`);
                throw e;
            }
            try {
                const { keyAttributes, masterKey, srpSetupAttributes } =
                    await generateKeyAndSRPAttributes(passphrase);

                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
                setData(LS_KEYS.SRP_SETUP_ATTRIBUTES, srpSetupAttributes);
                await generateAndSaveIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    masterKey,
                );

                await saveKeyInSessionStore(
                    SESSION_KEYS.ENCRYPTION_KEY,
                    masterKey,
                );
                setJustSignedUp(true);
                router.push(PAGES.VERIFY);
            } catch (e) {
                setFieldError("confirm", t("PASSWORD_GENERATION_FAILED"));
                throw e;
            }
        } catch (err) {
            logError(err, "signup failed");
        }
        setLoading(false);
    };

    return (
        <>
            <FormPaperTitle> {t("SIGN_UP")}</FormPaperTitle>
            <Formik<FormValues>
                initialValues={{
                    email: "",
                    passphrase: "",
                    confirm: "",
                    referral: "",
                }}
                validationSchema={Yup.object().shape({
                    email: Yup.string()
                        .email(t("EMAIL_ERROR"))
                        .required(t("REQUIRED")),
                    passphrase: Yup.string().required(t("REQUIRED")),
                    confirm: Yup.string().required(t("REQUIRED")),
                })}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={registerUser}
            >
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                }): JSX.Element => (
                    <form noValidate onSubmit={handleSubmit}>
                        <VerticallyCentered sx={{ mb: 1 }}>
                            <TextField
                                fullWidth
                                id="email"
                                name="email"
                                autoComplete="username"
                                type="email"
                                label={t("ENTER_EMAIL")}
                                value={values.email}
                                onChange={handleChange("email")}
                                error={Boolean(errors.email)}
                                helperText={errors.email}
                                autoFocus
                                disabled={loading}
                            />

                            <TextField
                                fullWidth
                                id="password"
                                name="password"
                                autoComplete="new-password"
                                type={showPassword ? "text" : "password"}
                                label={t("PASSPHRASE_HINT")}
                                value={values.passphrase}
                                onChange={handleChange("passphrase")}
                                error={Boolean(errors.passphrase)}
                                helperText={errors.passphrase}
                                disabled={loading}
                                InputProps={{
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
                                }}
                            />

                            <TextField
                                fullWidth
                                id="confirm-password"
                                name="confirm-password"
                                autoComplete="new-password"
                                type="password"
                                label={t("CONFIRM_PASSPHRASE")}
                                value={values.confirm}
                                onChange={handleChange("confirm")}
                                error={Boolean(errors.confirm)}
                                helperText={errors.confirm}
                                disabled={loading}
                            />
                            <PasswordStrengthHint
                                password={values.passphrase}
                            />

                            <Box sx={{ width: "100%" }}>
                                <Typography
                                    textAlign={"left"}
                                    color="text.secondary"
                                    mt={"24px"}
                                >
                                    {t("REFERRAL_CODE_HINT")}
                                </Typography>
                                <TextField
                                    hiddenLabel
                                    InputProps={{
                                        endAdornment: (
                                            <InputAdornment position="end">
                                                <Tooltip
                                                    title={t("REFERRAL_INFO")}
                                                >
                                                    <IconButton
                                                        tabIndex={-1}
                                                        color="secondary"
                                                        edge={"end"}
                                                    >
                                                        <InfoOutlined />
                                                    </IconButton>
                                                </Tooltip>
                                            </InputAdornment>
                                        ),
                                    }}
                                    fullWidth
                                    name="referral"
                                    type="text"
                                    value={values.referral}
                                    onChange={handleChange("referral")}
                                    error={Boolean(errors.referral)}
                                    disabled={loading}
                                />
                            </Box>
                            <FormGroup sx={{ width: "100%" }}>
                                <FormControlLabel
                                    sx={{
                                        color: "text.muted",
                                        ml: 0,
                                        mt: 2,
                                        mb: 0,
                                    }}
                                    control={
                                        <Checkbox
                                            size="small"
                                            disabled={loading}
                                            checked={acceptTerms}
                                            onChange={(e) =>
                                                setAcceptTerms(e.target.checked)
                                            }
                                            color="accent"
                                        />
                                    }
                                    label={
                                        <Typography variant="small">
                                            <Trans
                                                i18nKey={"TERMS_AND_CONDITIONS"}
                                                components={{
                                                    a: (
                                                        <Link
                                                            href="https://ente.io/terms"
                                                            target="_blank"
                                                        />
                                                    ),
                                                    b: (
                                                        <Link
                                                            href="https://ente.io/privacy"
                                                            target="_blank"
                                                        />
                                                    ),
                                                }}
                                            />
                                        </Typography>
                                    }
                                />
                            </FormGroup>
                        </VerticallyCentered>
                        <Box mb={4}>
                            <SubmitButton
                                sx={{ my: 0 }}
                                buttonText={t("CREATE_ACCOUNT")}
                                loading={loading}
                                disabled={
                                    !acceptTerms ||
                                    isWeakPassword(values.passphrase)
                                }
                            />
                            {loading && (
                                <Typography
                                    mt={1}
                                    textAlign={"center"}
                                    color="text.muted"
                                    variant="small"
                                >
                                    {t("KEY_GENERATION_IN_PROGRESS_MESSAGE")}
                                </Typography>
                            )}
                        </Box>
                    </form>
                )}
            </Formik>

            <FormPaperFooter>
                <LinkButton onClick={login}>{t("ACCOUNT_EXISTS")}</LinkButton>
            </FormPaperFooter>
        </>
    );
}
