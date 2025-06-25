import { Input, Stack, TextField, Typography } from "@mui/material";
import { AccountsPageFooter } from "ente-accounts/components/layouts/centered-paper";
import {
    getSRPAttributes,
    saveSRPAttributes,
} from "ente-accounts/services/srp";
import { savePartialLocalUser, sendOTT } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isMuseumHTTPError } from "ente-base/http";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback } from "react";
import { z } from "zod/v4";
import { AccountsPageTitleWithCaption } from "./LoginComponents";

interface LoginContentsProps {
    /** Called when the user clicks the signup option instead.  */
    onSignUp: () => void;
    /** Reactive value of {@link customAPIHost}. */
    host: string | undefined;
}

/**
 * Contents of the "login form", maintained as a separate component so that the
 * same code can be used both in the standalone /login page, and also within the
 * embedded login form shown on the photos index page.
 */
export const LoginContents: React.FC<LoginContentsProps> = ({
    onSignUp,
    host,
}) => {
    const router = useRouter();

    const loginUser = useCallback(
        async (email: string, setFieldError: (message: string) => void) => {
            const srpAttributes = await getSRPAttributes(email);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                try {
                    await sendOTT(email, "login");
                } catch (e) {
                    if (
                        await isMuseumHTTPError(e, 404, "USER_NOT_REGISTERED")
                    ) {
                        setFieldError(t("email_not_registered"));
                        return;
                    }
                    throw e;
                }
                savePartialLocalUser({ email });
                void router.push("/verify");
            } else {
                savePartialLocalUser({ email });
                saveSRPAttributes(srpAttributes);
                void router.push("/credentials");
            }
        },
        [router],
    );

    const formik = useFormik({
        initialValues: { email: "" },
        onSubmit: async ({ email }, { setFieldError }) => {
            const setEmailFieldError = (message: string) =>
                setFieldError("email", message);

            if (!email) {
                setEmailFieldError(t("required"));
                return;
            }

            if (!z.email().safeParse(email).success) {
                setEmailFieldError(t("invalid_email_error"));
                return;
            }

            try {
                await loginUser(email, setEmailFieldError);
            } catch (e) {
                log.error("Failed to login", e);
                setEmailFieldError(t("generic_error"));
            }
        },
    });

    return (
        <>
            <AccountsPageTitleWithCaption>
                {t("login")}
            </AccountsPageTitleWithCaption>
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
                    // See: [Note: Use space as default TextField helperText]
                    helperText={formik.errors.email ?? " "}
                />
                <Input sx={{ display: "none" }} type="password" value="" />
                <LoadingButton
                    fullWidth
                    type="submit"
                    loading={formik.isSubmitting}
                    color="accent"
                >
                    {t("login")}
                </LoadingButton>
            </form>
            <AccountsPageFooter>
                <Stack sx={{ gap: 3, textAlign: "center" }}>
                    <LinkButton onClick={onSignUp}>
                        {t("no_account")}
                    </LinkButton>
                    <Typography
                        variant="mini"
                        sx={{ color: "text.faint", minHeight: "16px" }}
                    >
                        {host ?? "" /* prevent layout shift with a minHeight */}
                    </Typography>
                </Stack>
            </AccountsPageFooter>
        </>
    );
};
