import { Input, Stack, TextField, Typography } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { replaceSavedLocalUser } from "ente-accounts/services/accounts-db";
import { sendOTT } from "ente-accounts/services/user";
import { LinkButtonUndecorated } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isMuseumHTTPError } from "ente-base/http";
import log from "ente-base/log";
import { customAPIHost } from "ente-base/origins";
import { useFormik } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import {
    SRPLoginError,
    getSRPAttributes,
    loginWithSRP,
} from "services/auth/srp";
import { z } from "zod";

const Page: React.FC = () => {
    const router = useRouter();

    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>(undefined);
    const [showLogin, setShowLogin] = useState(false);
    const [loginReturnToChat, setLoginReturnToChat] = useState(false);

    const refreshHost = useCallback(
        () => void customAPIHost().then(setHost),
        [],
    );

    useEffect(() => {
        refreshHost();

        const shouldOpenLogin =
            typeof window !== "undefined" &&
            window.sessionStorage.getItem("ensu.openLogin") === "1";
        if (shouldOpenLogin) {
            setLoginReturnToChat(true);
            setShowLogin(true);
            window.sessionStorage.removeItem("ensu.openLogin");
            setLoading(false);
            return;
        }

        void router.replace("/chat");
    }, [router, refreshHost]);

    const closeLogin = useCallback(() => {
        setShowLogin(false);
        if (loginReturnToChat) {
            setLoginReturnToChat(false);
            void router.push("/chat");
        }
    }, [loginReturnToChat, router]);

    const formik = useFormik({
        initialValues: { email: "", password: "" },
        onSubmit: async ({ email, password }, { setFieldError }) => {
            const setEmailFieldError = (message: string) =>
                setFieldError("email", message);
            const setPasswordFieldError = (message: string) =>
                setFieldError("password", message);

            if (!email) {
                setEmailFieldError(t("required"));
                return;
            }

            if (!z.email().safeParse(email).success) {
                setEmailFieldError(t("invalid_email_error"));
                return;
            }

            const startEmailLogin = async () => {
                try {
                    await sendOTT(email, "login");
                } catch (error) {
                    if (
                        await isMuseumHTTPError(
                            error,
                            404,
                            "USER_NOT_REGISTERED",
                        )
                    ) {
                        setEmailFieldError(t("email_not_registered"));
                        return false;
                    }
                    log.error("Failed to start email login", error);
                    setEmailFieldError(t("generic_error"));
                    return false;
                }

                replaceSavedLocalUser({ email });
                await router.push("/verify");
                return true;
            };

            try {
                const srpAttributes = await getSRPAttributes(email);
                if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                    await startEmailLogin();
                    return;
                }

                if (!password) {
                    setPasswordFieldError(t("required"));
                    return;
                }

                await loginWithSRP(email, password, srpAttributes);
                await router.push("/chat");
            } catch (e) {
                if (e instanceof SRPLoginError) {
                    switch (e.code) {
                        case "INCORRECT_PASSWORD":
                            setPasswordFieldError(t("incorrect_password"));
                            return;
                        case "SRP_NOT_AVAILABLE":
                        case "EMAIL_MFA_ENABLED":
                            await startEmailLogin();
                            return;
                        case "TWO_FACTOR_REQUIRED":
                            setPasswordFieldError(
                                "Second factor verification is required. This is not supported in Ensu web yet.",
                            );
                            return;
                        case "DECRYPT_FAILED":
                            setPasswordFieldError(e.message);
                            return;
                        case "INVALID_RESPONSE":
                            setPasswordFieldError(e.message);
                            return;
                        default:
                            setPasswordFieldError(t("generic_error"));
                            return;
                    }
                }

                if (e instanceof Error && e.message) {
                    setPasswordFieldError(e.message);
                } else {
                    setPasswordFieldError(t("generic_error"));
                }
                log.error("Login failed", e);
            }
        },
    });

    const loginForm = (
        <form onSubmit={formik.handleSubmit}>
            <TextField
                name="email"
                value={formik.values.email}
                onChange={formik.handleChange}
                type="email"
                autoComplete="username"
                label={t("enter_email")}
                fullWidth
                autoFocus
                margin="normal"
                disabled={formik.isSubmitting}
                error={!!formik.errors.email}
                helperText={formik.errors.email ?? " "}
            />

            <TextField
                name="password"
                value={formik.values.password}
                onChange={formik.handleChange}
                type="password"
                autoComplete="current-password"
                label={t("password")}
                fullWidth
                margin="normal"
                disabled={formik.isSubmitting}
                error={!!formik.errors.password}
                helperText={formik.errors.password ?? " "}
            />

            {/*
                A hidden password input prevents password managers from
                incorrectly trying to fill unrelated inputs.
            */}
            <Input sx={{ display: "none" }} type="password" value="" />

            <Stack sx={{ gap: 1, mt: 1 }}>
                <LoadingButton
                    fullWidth
                    type="submit"
                    loading={formik.isSubmitting}
                    color="accent"
                >
                    {t("login")}
                </LoadingButton>
                <Stack direction="row" justifyContent="center">
                    <LinkButtonUndecorated onClick={closeLogin}>
                        {t("cancel")}
                    </LinkButtonUndecorated>
                </Stack>
            </Stack>
        </form>
    );

    if (loading || !showLogin) return <LoadingIndicator />;

    return (
        <AccountsPageContents>
            <AccountsPageTitle>Ensu</AccountsPageTitle>

            <Stack sx={{ gap: 2 }}>
                <Typography variant="small" sx={{ color: "text.muted" }}>
                    Local-first encrypted chat. Sign in to sync across devices.
                </Typography>

                {loginForm}
            </Stack>

            <AccountsPageFooter>
                <Stack sx={{ gap: 1, textAlign: "center", width: "100%" }}>
                    <Typography
                        variant="mini"
                        sx={{ color: "text.faint", minHeight: "16px" }}
                    >
                        {host ?? ""}
                    </Typography>
                </Stack>
            </AccountsPageFooter>
        </AccountsPageContents>
    );
};

export default Page;
