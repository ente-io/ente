import { Box, Typography } from "@mui/material";
import {
    AccountsPageContents,
    AccountsPageFooter,
    AccountsPageTitle,
} from "ente-accounts/components/layouts/centered-paper";
import { VerifyingPasskey } from "ente-accounts/components/LoginComponents";
import { SecondFactorChoice } from "ente-accounts/components/SecondFactorChoice";
import { useSecondFactorChoiceIfNeeded } from "ente-accounts/components/utils/second-factor-choice";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "ente-accounts/services/passkey";
import {
    stashedRedirect,
    unstashRedirect,
} from "ente-accounts/services/redirect";
import {
    getSRPAttributes,
    setupSRP,
    unstashAndUseSRPSetupAttributes,
    type SRPAttributes,
} from "ente-accounts/services/srp";
import type { KeyAttributes, User } from "ente-accounts/services/user";
import {
    putUserKeyAttributes,
    sendOTT,
    verifyEmail,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { useBaseContext } from "ente-base/context";
import { isDevBuild } from "ente-base/env";
import { isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import { clearSessionStorage } from "ente-base/session";
import localForage from "ente-shared/storage/localForage";
import { getData, setData, setLSUser } from "ente-shared/storage/localStorage";
import {
    getLocalReferralSource,
    setIsFirstLogin,
} from "ente-shared/storage/localStorage/helpers";
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
            const user: User = getData("user");

            const redirect = await redirectionIfNeeded(user);
            if (redirect) {
                void router.push(redirect);
            } else {
                setEmail(user.email);
            }
        };
        void main();
    }, [router]);

    const onSubmit: SingleInputFormProps["onSubmit"] = async (
        ott,
        setFieldError,
    ) => {
        try {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-call
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
                const user = getData("user");
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
                    accountsUrl!,
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
                void router.push("/two-factor/verify");
            } else {
                await setLSUser({
                    email,
                    token,
                    encryptedToken,
                    id,
                    isTwoFactorEnabled: false,
                });
                if (keyAttributes) {
                    setData("keyAttributes", keyAttributes);
                    setData("originalKeyAttributes", keyAttributes);
                } else {
                    const originalKeyAttributes = getData(
                        "originalKeyAttributes",
                    );
                    if (originalKeyAttributes) {
                        await putUserKeyAttributes(originalKeyAttributes);
                    }
                    await unstashAndUseSRPSetupAttributes(setupSRP);
                }
                // TODO(RE): Temporary safety valve before removing the
                // unnecessary clear (tag: Migration)
                if (isDevBuild && (await localForage.length()) > 0) {
                    throw new Error("Local forage is not empty");
                }
                await localForage.clear();
                setIsFirstLogin(true);
                const redirectURL = unstashRedirect();
                if (keyAttributes?.encryptedKey) {
                    clearSessionStorage();
                    void router.push(redirectURL ?? "/credentials");
                } else {
                    void router.push(redirectURL ?? "/generate");
                }
            }
        } catch (e) {
            if (isHTTPErrorWithStatus(e, 401)) {
                setFieldError(t("invalid_code_error"));
            } else if (isHTTPErrorWithStatus(e, 410)) {
                setFieldError(t("expired_code_error"));
            } else {
                log.error("OTT verification failed", e);
                throw e;
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
                autoComplete="one-time-code"
                label={t("verification_code")}
                submitButtonTitle={t("verify")}
                onSubmit={onSubmit}
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

    const keyAttributes: KeyAttributes = getData("keyAttributes");

    if (keyAttributes?.encryptedKey && (user.token || user.encryptedToken)) {
        return "/credentials";
    }

    // If we're coming here during the recover flow, do not redirect.
    if (stashedRedirect() == "/recover") return undefined;

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

    const srpAttributes: SRPAttributes = getData("srpAttributes");
    if (srpAttributes && !srpAttributes.isEmailMFAEnabled) {
        // Fetch the latest SRP attributes instead of relying on the potentially
        // stale stored values. This is an infrequent scenario path, so extra
        // API calls are fine.
        const latestSRPAttributes = await getSRPAttributes(email);
        if (latestSRPAttributes && !latestSRPAttributes.isEmailMFAEnabled) {
            return "/credentials";
        }
    }

    return undefined;
};
