import { Input, Stack, TextField, Typography } from "@mui/material";
import { AccountsPageFooter } from "ente-accounts/components/layouts/centered-paper";
import { getSRPAttributes } from "ente-accounts/services/srp-remote";
import { sendOTT } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isMuseumHTTPError } from "ente-base/http";
import log from "ente-base/log";
import { setData, setLSUser } from "ente-shared/storage/localStorage";
import { useFormik } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback } from "react";

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
            log.debug(() => ["srpAttributes", JSON.stringify(srpAttributes)]);
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
                await setLSUser({ email });
                void router.push("/verify");
            } else {
                await setLSUser({ email });
                setData("srpAttributes", srpAttributes);
                void router.push("/credentials");
            }
        },
        [router],
    );

    const formik = useFormik({
        initialValues: { value: "" },
        onSubmit: async (values, { setFieldError }) => {
            const value = values.value;
            const setValueFieldError = (message: string) =>
                setFieldError("value", message);

            if (!value) {
                setValueFieldError(t("required"));
                return;
            }
            try {
                await loginUser(value, setValueFieldError);
            } catch (e) {
                log.error("Failed to login", e);
                setValueFieldError(t("generic_error"));
            }
        },
    });

    return (
        <>
            {/* AccountsPageTitle, inlined to tweak mb */}
            <Typography variant="h3" sx={{ flex: 1, mb: 4 }}>
                {t("login")}
            </Typography>
            <form onSubmit={formik.handleSubmit}>
                <TextField
                    name="value"
                    value={formik.values.value}
                    onChange={formik.handleChange}
                    type="email"
                    autoComplete="username"
                    label={t("enter_email")}
                    fullWidth
                    margin="normal"
                    disabled={formik.isSubmitting}
                    error={!!formik.errors.value}
                    // See: Note: [Use space as default TextField helperText]
                    helperText={formik.errors.value ?? " "}
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
