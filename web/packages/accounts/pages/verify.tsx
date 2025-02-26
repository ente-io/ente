import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "@/accounts/components/layouts/centered-paper";
import { VerifyingPasskey } from "@/accounts/components/LoginComponents";
import { SecondFactorChoice } from "@/accounts/components/SecondFactorChoice";
import { useSecondFactorChoiceIfNeeded } from "@/accounts/components/utils/second-factor-choice";
import { PAGES } from "@/accounts/constants/pages";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "@/accounts/services/passkey";
import { stashedRedirect, unstashRedirect } from "@/accounts/services/redirect";
import { configureSRP } from "@/accounts/services/srp";
import type {
    SRPAttributes,
    SRPSetupAttributes,
} from "@/accounts/services/srp-remote";
import { getSRPAttributes } from "@/accounts/services/srp-remote";
import { putAttributes, sendOTT, verifyEmail } from "@/accounts/services/user";
import { LinkButton } from "@/base/components/LinkButton";
import { LoadingIndicator } from "@/base/components/loaders";
import { useBaseContext } from "@/base/context";
import log from "@/base/log";
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
import { Box, Typography } from "@mui/material";
import { HttpStatusCode } from "axios";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";

const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [email, setEmail] = useState("");
    const [resend, setResend] = useState(0);
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();
    const {
        secondFactorChoiceProps,
        userVerificationResultAfterResolvingSecondFactorChoice,
    } = useSecondFactorChoiceIfNeeded();

    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);

            const redirect = await redirectionIfNeeded(user);
            if (redirect) {
                void router.push(redirect);
            } else {
                setEmail(user.email);
            }
        };
        void main();
    }, [router]);

    const onSubmit: SingleInputFormProps["callback"] = async (
        ott,
        setFieldError,
    ) => {
        try {
            const referralSource = getLocalReferralSource()?.trim();
            const cleanedReferral = referralSource
                ? `web:${referralSource}`
                : undefined;
            const {
                keyAttributes,
                encryptedToken,
                token,
                id,
                twoFactorSessionID,
                passkeySessionID,
                accountsUrl,
            } = await userVerificationResultAfterResolvingSecondFactorChoice(
                await verifyEmail(email, ott, cleanedReferral),
            );
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
                const url = passkeyVerificationRedirectURL(
                    accountsUrl,
                    passkeySessionID,
                );
                setPasskeyVerificationData({ passkeySessionID, url });
                openPasskeyVerificationURL({ passkeySessionID, url });
            } else if (twoFactorSessionID) {
                await setLSUser({
                    email,
                    twoFactorSessionID,
                    isTwoFactorEnabled: true,
                });
                setIsFirstLogin(true);
                void router.push(PAGES.TWO_FACTOR_VERIFY);
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
                            token!,
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
                await localForage.clear();
                setIsFirstLogin(true);
                const redirectURL = unstashRedirect();
                if (keyAttributes?.encryptedKey) {
                    clearKeys();
                    void router.push(redirectURL ?? PAGES.CREDENTIALS);
                } else {
                    void router.push(redirectURL ?? PAGES.GENERATE);
                }
            }
        } catch (e) {
            if (e instanceof ApiError) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
                if (e?.httpStatusCode === HttpStatusCode.Unauthorized) {
                    setFieldError(t("invalid_code_error"));
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
                } else if (e?.httpStatusCode === HttpStatusCode.Gone) {
                    setFieldError(t("expired_code_error"));
                }
            } else {
                log.error("OTT verification failed", e);
                setFieldError(t("generic_error_retry"));
            }
        }
    };

    const resendEmail = async () => {
        setResend(1);
        await sendOTT(email, undefined);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    };

    if (!email) {
        return <LoadingIndicator />;
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
            return <LoadingIndicator />;
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
        <AccountsPageContents>
            <AccountsPageTitle>
                <Trans
                    i18nKey="email_sent"
                    components={{
                        a: (
                            <Box
                                component={"span"}
                                sx={{
                                    color: "text.muted",
                                    wordBreak: "break-word",
                                }}
                            />
                        ),
                    }}
                    values={{ email }}
                />
            </AccountsPageTitle>

            <Typography variant="small" sx={{ color: "text.muted", mb: 2 }}>
                {t("check_inbox_hint")}
            </Typography>
            <SingleInputForm
                fieldType="text"
                autoComplete="one-time-code"
                placeholder={t("verification_code")}
                buttonText={t("verify")}
                callback={onSubmit}
            />

            <AccountsPageFooter>
                {resend === 0 && (
                    <LinkButton onClick={resendEmail}>
                        {t("resend_code")}
                    </LinkButton>
                )}
                {resend === 1 && <span>{t("status_sending")}</span>}
                {resend === 2 && <span>{t("status_sent")}</span>}
                <LinkButton onClick={logout}>{t("change_email")}</LinkButton>
            </AccountsPageFooter>

            <SecondFactorChoice {...secondFactorChoiceProps} />
        </AccountsPageContents>
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
