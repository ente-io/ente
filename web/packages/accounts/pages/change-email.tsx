import CheckIcon from "@mui/icons-material/Check";
import { Alert, Box, Stack, TextField } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { appHomeRoute } from "ente-accounts/services/redirect";
import { changeEmail, sendOTT } from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import { getData, setLSUser } from "ente-shared/storage/localStorage";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import * as Yup from "yup";

const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        const user = getData("user");
        if (!user?.token) {
            void router.push("/");
        }
    }, [router]);

    return (
        <AccountsPageContents>
            <AccountsPageTitle>{t("change_email")}</AccountsPageTitle>
            <ChangeEmailForm />
        </AccountsPageContents>
    );
};

export default Page;

interface formValues {
    email: string;
    ott?: string;
}

const ChangeEmailForm: React.FC = () => {
    const [loading, setLoading] = useState(false);
    const [ottInputVisible, setShowOttInputVisibility] = useState(false);
    const [email, setEmail] = useState<string | null>(null);
    const [showMessage, setShowMessage] = useState(false);

    const router = useRouter();

    const requestOTT = async (
        { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>,
    ) => {
        try {
            setLoading(true);
            await sendOTT(email, "change");
            setEmail(email);
            setShowOttInputVisibility(true);
            setShowMessage(true);
            // TODO: What was this meant to focus on? The ref referred to an
            // Form element that was removed. Is this still needed.
            // setTimeout(() => {
            //     ottInputRef.current?.focus();
            // }, 250);
        } catch (e) {
            log.error(e);
            setFieldError(
                "email",
                isHTTPErrorWithStatus(e, 403)
                    ? t("email_already_taken")
                    : t("generic_error"),
            );
        }
        setLoading(false);
    };

    const requestEmailChange = async (
        { email, ott }: formValues,
        { setFieldError }: FormikHelpers<formValues>,
    ) => {
        try {
            setLoading(true);
            await changeEmail(email, ott!);
            await setLSUser({ ...getData("user"), email });
            setLoading(false);
            void goToApp();
        } catch (e) {
            log.error(e);
            setLoading(false);
            setFieldError("ott", t("incorrect_code"));
        }
    };

    const goToApp = () => router.push(appHomeRoute);

    return (
        <Formik<formValues>
            initialValues={{ email: "" }}
            validationSchema={
                ottInputVisible
                    ? Yup.object().shape({
                          email: Yup.string()
                              .email(t("invalid_email_error"))
                              .required(t("required")),
                          ott: Yup.string().required(t("required")),
                      })
                    : Yup.object().shape({
                          email: Yup.string()
                              .email(t("invalid_email_error"))
                              .required(t("required")),
                      })
            }
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={!ottInputVisible ? requestOTT : requestEmailChange}
        >
            {({ values, errors, handleChange, handleSubmit }) => (
                <>
                    {showMessage && (
                        <Alert
                            icon={<CheckIcon fontSize="inherit" />}
                            severity="success"
                            onClose={() => setShowMessage(false)}
                        >
                            <Trans
                                i18nKey="email_sent"
                                components={{
                                    a: (
                                        <Box
                                            component={"span"}
                                            sx={{ color: "text.muted" }}
                                        />
                                    ),
                                }}
                                values={{ email }}
                            />
                        </Alert>
                    )}
                    <form noValidate onSubmit={handleSubmit}>
                        <Stack>
                            <TextField
                                fullWidth
                                type="email"
                                label={t("enter_email")}
                                value={values.email}
                                onChange={handleChange("email")}
                                error={Boolean(errors.email)}
                                helperText={errors.email}
                                autoFocus
                                disabled={loading}
                                slotProps={{
                                    input: { readOnly: ottInputVisible },
                                }}
                            />
                            {ottInputVisible && (
                                <TextField
                                    fullWidth
                                    type="text"
                                    label={t("verification_code")}
                                    value={values.ott}
                                    onChange={handleChange("ott")}
                                    error={Boolean(errors.ott)}
                                    helperText={errors.ott}
                                    disabled={loading}
                                />
                            )}
                            <LoadingButton
                                fullWidth
                                color="accent"
                                type="submit"
                                sx={{ mt: 2, mb: 4 }}
                                loading={loading}
                            >
                                {!ottInputVisible ? t("send_otp") : t("verify")}
                            </LoadingButton>
                        </Stack>
                    </form>

                    <AccountsPageFooter>
                        {ottInputVisible && (
                            <LinkButton
                                onClick={() => setShowOttInputVisibility(false)}
                            >
                                {t("change_email")}?
                            </LinkButton>
                        )}
                        <LinkButton onClick={goToApp}>
                            {t("go_back")}
                        </LinkButton>
                    </AccountsPageFooter>
                </>
            )}
        </Formik>
    );
};
