import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "@/accounts/components/layouts/centered-paper";
import { appHomeRoute } from "@/accounts/services/redirect";
import { changeEmail, sendOTT } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import { isHTTPErrorWithStatus } from "@/base/http";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Alert, Box, TextField } from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import * as Yup from "yup";

const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            void router.push("/");
        }
    }, []);

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
            await setLSUser({ ...getData(LS_KEYS.USER), email });
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
                            color="success"
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
                        <VerticallyCentered>
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
                                    input: {
                                        readOnly: ottInputVisible,
                                    },
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
                        </VerticallyCentered>
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
