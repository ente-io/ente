import {
    FormPaper,
    FormPaperFooter,
    FormPaperTitle,
} from "@/base/components/FormPaper";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Alert, Box, TextField } from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import * as Yup from "yup";
import { appHomeRoute } from "../services/redirect";
import { changeEmail, sendOTTForEmailChange } from "../services/user";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = () => {
    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            void router.push("/");
        }
    }, []);

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t("CHANGE_EMAIL")}</FormPaperTitle>
                <ChangeEmailForm />
            </FormPaper>
        </VerticallyCentered>
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
            await sendOTTForEmailChange(email);
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
            setFieldError("email", t("email_already_taken"));
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
            setFieldError("ott", t("INCORRECT_CODE"));
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
                              .email(t("EMAIL_ERROR"))
                              .required(t("required")),
                          ott: Yup.string().required(t("required")),
                      })
                    : Yup.object().shape({
                          email: Yup.string()
                              .email(t("EMAIL_ERROR"))
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
                                i18nKey="EMAIL_SENT"
                                components={{
                                    a: (
                                        <Box
                                            color="text.muted"
                                            component={"span"}
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
                                InputProps={{
                                    readOnly: ottInputVisible,
                                }}
                                type="email"
                                label={t("ENTER_EMAIL")}
                                value={values.email}
                                onChange={handleChange("email")}
                                error={Boolean(errors.email)}
                                helperText={errors.email}
                                autoFocus
                                disabled={loading}
                            />
                            {ottInputVisible && (
                                <TextField
                                    fullWidth
                                    type="text"
                                    label={t("ENTER_OTT")}
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
                                {!ottInputVisible ? t("SEND_OTT") : t("VERIFY")}
                            </LoadingButton>
                        </VerticallyCentered>
                    </form>

                    <FormPaperFooter
                        style={{
                            justifyContent: ottInputVisible
                                ? "space-between"
                                : "normal",
                        }}
                    >
                        {ottInputVisible && (
                            <LinkButton
                                onClick={() => setShowOttInputVisibility(false)}
                            >
                                {t("CHANGE_EMAIL")}?
                            </LinkButton>
                        )}
                        <LinkButton onClick={goToApp}>
                            {t("go_back")}
                        </LinkButton>
                    </FormPaperFooter>
                </>
            )}
        </Formik>
    );
};
