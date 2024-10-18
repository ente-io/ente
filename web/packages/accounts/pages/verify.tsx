import type { UserVerificationResponse } from "@/accounts/types/user";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { ApiError } from "@ente/shared/error";
import localForage from "@ente/shared/storage/localForage";
import {
    getData,
    LS_KEYS,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
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
import { getSRPAttributes } from "../api/srp";
import { putAttributes, sendOtt, verifyOtt } from "../api/user";
import {
    LoginFlowFormFooter,
    VerifyingPasskey,
} from "../components/LoginComponents";
import { PAGES } from "../constants/pages";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "../services/passkey";
import { stashedRedirect, unstashRedirect } from "../services/redirect";
import { configureSRP } from "../services/srp";
import type { PageProps } from "../types/page";
import type { SRPAttributes, SRPSetupAttributes } from "../types/srp";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { logout, showNavBar, showMiniDialog } = appContext;

    const [email, setEmail] = useState("");
    const [resend, setResend] = useState(0);
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);

            const redirect = await redirectionIfNeeded(user);
            if (redirect) {
                router.push(redirect);
            } else {
                setEmail(user.email);
            }
        };
        main();
        showNavBar(true);
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
                await setLSUser({
                    ...user,
                    passkeySessionID,
                    isTwoFactorEnabled: true,
                    isTwoFactorPasskeysEnabled: true,
                });
                // TODO: This is not the first login though if they already have
                // 2FA. Does this flag mean first login on this device?
                //
                // Update: This flag causes the interactive encryption key to be
                // generated, so it has a functional impact we need.
                setIsFirstLogin(true);
                const url = passkeyVerificationRedirectURL(passkeySessionID);
                setPasskeyVerificationData({ passkeySessionID, url });
                openPasskeyVerificationURL({ passkeySessionID, url });
            } else if (twoFactorSessionID) {
                await setLSUser({
                    email,
                    twoFactorSessionID,
                    isTwoFactorEnabled: true,
                });
                setIsFirstLogin(true);
                router.push(PAGES.TWO_FACTOR_VERIFY);
            } else {
                await setLSUser({
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
                const redirectURL = unstashRedirect();
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
                log.error("OTT verification failed", e);
                setFieldError(
                    `${t("generic_error_retry")} ${JSON.stringify(e)}`,
                );
            }
        }
    };

    const resendEmail = async () => {
        setResend(1);
        await sendOtt(email);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    };

    if (!email) {
        return (
            <VerticallyCentered>
                <ActivityIndicator />
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
                    <ActivityIndicator />
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
                {...{ logout, showMiniDialog }}
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

/**
 * A function called during page load to see if a redirection is required
 *
 * @returns The slug to redirect to, if needed.
 */
const redirectionIfNeeded = async (user: User | undefined) => {
    const email = user?.email;
    if (!email) {
        return "/";
    }

    const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);

    if (keyAttributes?.encryptedKey && (user.token || user.encryptedToken)) {
        return PAGES.CREDENTIALS;
    }

    // If we're coming here during the recover flow, do not redirect.
    if (stashedRedirect() == PAGES.RECOVER) return undefined;

    // The user might have email verification disabled, but after previously
    // entering their email on the login screen, they might've closed the tab
    // before proceeding (or opened a us in a new tab at this point).
    //
    // In such cases, we'll end up here with an email present.
    //
    // To distinguish this scenario from the normal email verification flow, we
    // can check to see the SRP attributes (the login page would've fetched and
    // saved them). If they are present and indicate that email verification is
    // not required, redirect to the password verification page.

    const srpAttributes: SRPAttributes = getData(LS_KEYS.SRP_ATTRIBUTES);
    if (srpAttributes && !srpAttributes.isEmailMFAEnabled) {
        // Fetch the latest SRP attributes instead of relying on the potentially
        // stale stored values. This is an infrequent scenario path, so extra
        // API calls are fine.
        const latestSRPAttributes = await getSRPAttributes(email);
        if (latestSRPAttributes && !latestSRPAttributes.isEmailMFAEnabled) {
            return PAGES.CREDENTIALS;
        }
    }

    return undefined;
};
