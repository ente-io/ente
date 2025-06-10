import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import {
    Box,
    Checkbox,
    Divider,
    FormControlLabel,
    FormGroup,
    IconButton,
    InputAdornment,
    InputLabel,
    Link,
    Stack,
    TextField,
    Tooltip,
    Typography,
} from "@mui/material";
import {
    deriveSRPPassword,
    generateSRPSetupAttributes,
} from "ente-accounts/services/srp";
import {
    generateAndSaveInteractiveKeyAttributes,
    generateKeysAndAttributes,
    sendOTT,
} from "ente-accounts/services/user";
import { isWeakPassword } from "ente-accounts/utils/password";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { isMuseumHTTPError } from "ente-base/http";
import log from "ente-base/log";
import { saveMasterKeyInSessionAndSafeStore } from "ente-base/session";
import { setLSUser } from "ente-shared//storage/localStorage";
import { setData } from "ente-shared/storage/localStorage";
import {
    setJustSignedUp,
    setLocalReferralSource,
} from "ente-shared/storage/localStorage/helpers";
import { useFormik } from "formik";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import React, { useCallback, useState } from "react";
import { Trans } from "react-i18next";
import * as Yup from "yup";
import { PasswordStrengthHint } from "./PasswordStrength";
import {
    AccountsPageFooter,
    AccountsPageTitle,
} from "./layouts/centered-paper";

interface SignUpContentsProps {
    router: NextRouter;
    /** Called when the user clicks the login option instead.  */
    onLogin: () => void;
    /** Reactive value of {@link customAPIHost}. */
    host: string | undefined;
}

export const SignUpContents: React.FC<SignUpContentsProps> = ({
    router,
    onLogin,
    host,
}) => {
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleToggleShowHidePassword = useCallback(
        () => setShowPassword((show) => !show),
        [],
    );

    const formik = useFormik({
        initialValues: {
            email: "",
            password: "",
            confirmPassword: "",
            referral: "",
            acceptedTerms: false,
        },
        validationSchema: Yup.object().shape({
            email: Yup.string()
                .email(t("invalid_email_error"))
                .required(t("required")),
            password: Yup.string().required(t("required")),
            confirmPassword: Yup.string().required(t("required")),
        }),
        validateOnChange: false,
        validateOnBlur: false,
        onSubmit: async (
            { email, password, confirmPassword, referral },
            { setFieldError },
        ) => {
            try {
                if (password != confirmPassword) {
                    setFieldError("confirm", t("password_mismatch_error"));
                    return;
                }
                setLoading(true);
                try {
                    setLocalReferralSource(referral);
                    await sendOTT(email, "signup");
                    await setLSUser({ email });
                } catch (e) {
                    log.error("Signup failed", e);
                    if (
                        await isMuseumHTTPError(
                            e,
                            409,
                            "USER_ALREADY_REGISTERED",
                        )
                    ) {
                        setFieldError("email", t("email_already_registered"));
                    } else {
                        setFieldError("email", t("generic_error"));
                    }
                    throw e;
                }
                try {
                    const { masterKey, kek, keyAttributes } =
                        await generateKeysAndAttributes(password);

                    const srpSetupAttributes = await generateSRPSetupAttributes(
                        await deriveSRPPassword(kek),
                    );

                    setData("originalKeyAttributes", keyAttributes);
                    setData("srpSetupAttributes", srpSetupAttributes);
                    await generateAndSaveInteractiveKeyAttributes(
                        password,
                        keyAttributes,
                        masterKey,
                    );

                    await saveMasterKeyInSessionAndSafeStore(masterKey);
                    setJustSignedUp(true);
                    void router.push("/verify");
                } catch (e) {
                    setFieldError("confirm", t("password_generation_failed"));
                    throw e;
                }
            } catch (e) {
                log.error("signup failed", e);
            }
            setLoading(false);
        },
    });

    const form = (
        <form noValidate onSubmit={formik.handleSubmit}>
            <Stack sx={{ mb: 2 }}>
                <TextField
                    name="email"
                    type="email"
                    autoComplete="username"
                    label={t("enter_email")}
                    value={formik.values.email}
                    onChange={formik.handleChange}
                    error={!!formik.errors.email}
                    helperText={formik.errors.email}
                    disabled={loading}
                    fullWidth
                    autoFocus
                />
                <TextField
                    name="password"
                    autoComplete="new-password"
                    type={showPassword ? "text" : "password"}
                    label={t("password")}
                    value={formik.values.password}
                    onChange={formik.handleChange}
                    error={!!formik.errors.password}
                    helperText={formik.errors.password}
                    disabled={loading}
                    fullWidth
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
                    helperText={formik.errors.confirmPassword}
                    disabled={loading}
                    fullWidth
                />
                <PasswordStrengthHint password={formik.values.password} />
                <InputLabel
                    htmlFor="referral"
                    sx={{ color: "text.muted", mt: "24px", mx: "2px" }}
                >
                    {t("referral_source_hint")}
                </InputLabel>
                <TextField
                    hiddenLabel
                    id="referral"
                    type="text"
                    value={formik.values.referral}
                    onChange={formik.handleChange}
                    error={!!formik.errors.referral}
                    disabled={loading}
                    fullWidth
                    slotProps={{
                        input: {
                            endAdornment: (
                                <InputAdornment position="end">
                                    <Tooltip title={t("referral_source_info")}>
                                        <IconButton
                                            tabIndex={-1}
                                            color="secondary"
                                            edge={"end"}
                                        >
                                            <InfoOutlinedIcon />
                                        </IconButton>
                                    </Tooltip>
                                </InputAdornment>
                            ),
                        },
                    }}
                />

                <FormGroup sx={{ width: "100%" }}>
                    <FormControlLabel
                        sx={{ color: "text.muted", ml: 0, mt: 2, mb: 0 }}
                        control={
                            <Checkbox
                                name="acceptedTerms"
                                size="small"
                                disabled={loading}
                                checked={formik.values.acceptedTerms}
                                onChange={formik.handleChange}
                                color="accent"
                            />
                        }
                        label={
                            <Typography variant="small">
                                <Trans
                                    i18nKey={"terms_and_conditions"}
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
            </Stack>
            <Box sx={{ mb: 1 }}>
                <LoadingButton
                    fullWidth
                    color="accent"
                    type="submit"
                    loading={loading}
                    disabled={
                        !formik.values.acceptedTerms ||
                        isWeakPassword(formik.values.password)
                    }
                >
                    {t("create_account")}
                </LoadingButton>
                {loading && (
                    <Typography
                        variant="small"
                        sx={{ mt: 1, textAlign: "center", color: "text.muted" }}
                    >
                        {t("key_generation_in_progress")}
                    </Typography>
                )}
            </Box>
        </form>
    );

    return (
        <>
            <AccountsPageTitle>{t("sign_up")}</AccountsPageTitle>
            {form}
            <Divider />
            <AccountsPageFooter>
                <Stack sx={{ gap: 3, textAlign: "center" }}>
                    <LinkButton onClick={onLogin}>
                        {t("existing_account")}
                    </LinkButton>
                    {host && (
                        <Typography variant="mini" sx={{ color: "text.faint" }}>
                            {host}
                        </Typography>
                    )}
                </Stack>
            </AccountsPageFooter>
        </>
    );
};
