import { ensure } from "@/utils/ensure";
import type { UserVerificationResponse } from "@ente/accounts/types/user";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import {
    LoginFlowFormFooter,
    VerifyingPasskey,
} from "@ente/shared/components/LoginComponents";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { ApiError } from "@ente/shared/error";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import localForage from "@ente/shared/storage/localForage";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import {
    getLocalReferralSource,
    setIsFirstLogin,
} from "@ente/shared/storage/localStorage/helpers";
import { clearKeys } from "@ente/shared/storage/sessionStorage";
import type { KeyAttributes, User } from "@ente/shared/user/types";
import { Box, Stack, Typography } from "@mui/material";
import { HttpStatusCode } from "axios";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { putAttributes, sendOtt, verifyOtt } from "../api/user";
import { PAGES } from "../constants/pages";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "../services/passkey";
import { configureSRP } from "../services/srp";
import type { PageProps } from "../types/page";
import type { SRPSetupAttributes } from "../types/srp";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { appName, logout } = appContext;

    const [email, setEmail] = useState("");
    const [resend, setResend] = useState(0);
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.KEY_ATTRIBUTES,
            );
            if (!user?.email) {
                router.push(PAGES.ROOT);
            } else if (
                keyAttributes?.encryptedKey &&
                (user.token || user.encryptedToken)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setEmail(user.email);
            }
        };
        main();
        appContext.showNavBar(true);
    }, []);

    const onSubmit: SingleInputFormProps["callback"] = async (
        ott,
        setFieldError,
    ) => {
        try {
            const referralSource = getLocalReferralSource();
            const resp = await verifyOtt(email, ott, referralSource);
            const {
                keyAttributes,
                encryptedToken,
                token,
                id,
                twoFactorSessionID,
                passkeySessionID,
            } = resp.data as UserVerificationResponse;
            if (passkeySessionID) {
                const user = getData(LS_KEYS.USER);
                setData(LS_KEYS.USER, {
                    ...user,
                    passkeySessionID,
                    isTwoFactorEnabled: true,
                    isTwoFactorPasskeysEnabled: true,
                });
                // TODO: This is not the first login though if they already have
                // 2FA. Does this flag mean first login on this device?
                setIsFirstLogin(true);
                const url = passkeyVerificationRedirectURL(
                    appName,
                    passkeySessionID,
                );
                setPasskeyVerificationData({ passkeySessionID, url });
                openPasskeyVerificationURL({ passkeySessionID, url });
            } else if (twoFactorSessionID) {
                setData(LS_KEYS.USER, {
                    email,
                    twoFactorSessionID,
                    isTwoFactorEnabled: true,
                });
                setIsFirstLogin(true);
                router.push(PAGES.TWO_FACTOR_VERIFY);
            } else {
                setData(LS_KEYS.USER, {
                    email,
                    token,
                    encryptedToken,
                    id,
                    isTwoFactorEnabled: false,
                });
                if (keyAttributes) {
                    setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
                    setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
                } else {
                    if (getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)) {
                        await putAttributes(
                            ensure(token),
                            getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES),
                        );
                    }
                    if (getData(LS_KEYS.SRP_SETUP_ATTRIBUTES)) {
                        const srpSetupAttributes: SRPSetupAttributes = getData(
                            LS_KEYS.SRP_SETUP_ATTRIBUTES,
                        );
                        await configureSRP(srpSetupAttributes);
                    }
                }
                localForage.clear();
                setIsFirstLogin(true);
                const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
                InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
                if (keyAttributes?.encryptedKey) {
                    clearKeys();
                    router.push(redirectURL ?? PAGES.CREDENTIALS);
                } else {
                    router.push(redirectURL ?? PAGES.GENERATE);
                }
            }
        } catch (e) {
            if (e instanceof ApiError) {
                if (e?.httpStatusCode === HttpStatusCode.Unauthorized) {
                    setFieldError(t("INVALID_CODE"));
                } else if (e?.httpStatusCode === HttpStatusCode.Gone) {
                    setFieldError(t("EXPIRED_CODE"));
                }
            } else {
                setFieldError(`${t("UNKNOWN_ERROR")} ${JSON.stringify(e)}`);
            }
        }
    };

    const resendEmail = async () => {
        setResend(1);
        await sendOtt(appName, email);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    };

    if (!email) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    if (passkeyVerificationData) {
        // We only need to handle this scenario when running in the desktop app
        // because the web app will navigate to Passkey verification URL.
        // However, still we add an additional `globalThis.electron` check to
        // show a spinner. This prevents the VerifyingPasskey component from
        // being disorientingly shown for a fraction of a second as the redirect
        // happens on the web app.
        //
        // See: [Note: Passkey verification in the desktop app]

        if (!globalThis.electron) {
            return (
                <VerticallyCentered>
                    <EnteSpinner />
                </VerticallyCentered>
            );
        }

        return (
            <VerifyingPasskey
                email={email}
                passkeySessionID={passkeyVerificationData?.passkeySessionID}
                onRetry={() =>
                    openPasskeyVerificationURL(passkeyVerificationData)
                }
                appContext={appContext}
            />
        );
    }

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle sx={{ mb: 14, wordBreak: "break-word" }}>
                    <Trans
                        i18nKey="EMAIL_SENT"
                        components={{
                            a: <Box color="text.muted" component={"span"} />,
                        }}
                        values={{ email }}
                    />
                </FormPaperTitle>
                <Typography color={"text.muted"} mb={2} variant="small">
                    {t("CHECK_INBOX")}
                </Typography>
                <SingleInputForm
                    fieldType="text"
                    autoComplete="one-time-code"
                    placeholder={t("ENTER_OTT")}
                    buttonText={t("VERIFY")}
                    callback={onSubmit}
                />

                <LoginFlowFormFooter>
                    <Stack direction="row" justifyContent="space-between">
                        {resend === 0 && (
                            <LinkButton onClick={resendEmail}>
                                {t("RESEND_MAIL")}
                            </LinkButton>
                        )}
                        {resend === 1 && <span>{t("SENDING")}</span>}
                        {resend === 2 && <span>{t("SENT")}</span>}
                        <LinkButton onClick={logout}>
                            {t("CHANGE_EMAIL")}
                        </LinkButton>
                    </Stack>
                </LoginFlowFormFooter>
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
