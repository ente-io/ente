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
    replaceSavedLocalUser,
    savedKeyAttributes,
    savedOriginalKeyAttributes,
    savedPartialLocalUser,
    savedSRPAttributes,
    saveIsFirstLogin,
    saveKeyAttributes,
    saveOriginalKeyAttributes,
    unstashAfterUseSRPSetupAttributes,
    unstashReferralSource,
    updateSavedLocalUser,
} from "ente-accounts/services/accounts-db";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "ente-accounts/services/passkey";
import {
    stashedRedirect,
    unstashRedirect,
} from "ente-accounts/services/redirect";
import {
    getAndSaveSRPAttributes,
    getSRPAttributes,
    setupSRP,
} from "ente-accounts/services/srp";
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
import { isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import { clearSessionStorage } from "ente-base/session";
import { saveAuthToken } from "ente-base/token";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";
import { Trans } from "react-i18next";

/**
 * A page that allows the user to verify their email.
 *
 * See: [Note: Login pages]
 */
const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [email, setEmail] = useState("");
    const [resend, setResend] = useState<"enable" | "sending" | "sent">(
        "enable",
    );
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();

    const {
        secondFactorChoiceProps,
        userVerificationResultAfterResolvingSecondFactorChoice,
    } = useSecondFactorChoiceIfNeeded();

    const router = useRouter();

    useEffect(() => {
        void redirectionIfNeededOrEmail().then((redirectOrEmail) => {
            if (typeof redirectOrEmail == "string") {
                void router.replace(redirectOrEmail);
            } else {
                setEmail(redirectOrEmail.email);
            }
        });
    }, [router]);

    const onSubmit: SingleInputFormProps["onSubmit"] = async (
        ott,
        setFieldError,
    ) => {
        try {
            const referralSource = unstashReferralSource();
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

            // The following flow is similar to (but not the same) as what
            // happens after `verifySRP` in the `/credentials` page.

            if (passkeySessionID) {
                updateSavedLocalUser({ passkeySessionID });
                saveIsFirstLogin();
                const url = passkeyVerificationRedirectURL(
                    accountsUrl!,
                    passkeySessionID,
                );
                setPasskeyVerificationData({ passkeySessionID, url });
                openPasskeyVerificationURL({ passkeySessionID, url });
            } else if (twoFactorSessionID) {
                updateSavedLocalUser({
                    isTwoFactorEnabled: true,
                    twoFactorSessionID,
                });
                saveIsFirstLogin();
                void router.push("/two-factor/verify");
            } else {
                if (token) await saveAuthToken(token);
                replaceSavedLocalUser({ id, email, token, encryptedToken });
                if (keyAttributes) {
                    saveKeyAttributes(keyAttributes);
                    saveOriginalKeyAttributes(keyAttributes);
                } else {
                    const originalKeyAttributes = savedOriginalKeyAttributes();
                    if (originalKeyAttributes) {
                        await putUserKeyAttributes(originalKeyAttributes);
                    }
                    await unstashAfterUseSRPSetupAttributes(setupSRP);
                    await getAndSaveSRPAttributes(email);
                }
                saveIsFirstLogin();
                if (keyAttributes) {
                    clearSessionStorage();
                    void router.push(unstashRedirect() ?? "/credentials");
                } else {
                    void router.push(unstashRedirect() ?? "/generate");
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

    const resendEmail = useCallback(async () => {
        setResend("sending");
        await sendOTT(email, undefined);
        setResend("sent");
        setTimeout(() => setResend("enable"), 3000);
    }, [email]);

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
                passkeySessionID={passkeyVerificationData.passkeySessionID}
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
                {resend == "enable" && (
                    <LinkButton onClick={resendEmail}>
                        {t("resend_code")}
                    </LinkButton>
                )}
                {resend == "sending" && <span>{t("status_sending")}</span>}
                {resend == "sent" && <span>{t("status_sent")}</span>}
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
 * @returns The slug to redirect to, if needed. Otherwise an object containing
 * the saved partial user's email.
 */
const redirectionIfNeededOrEmail = async () => {
    const user = savedPartialLocalUser();

    const email = user?.email;
    if (!email) {
        return "/";
    }

    if (savedKeyAttributes() && (user.token || user.encryptedToken)) {
        return "/credentials";
    }

    // If we're coming here during the recover flow, do not redirect.
    if (stashedRedirect() == "/recover") return { email };

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

    const srpAttributes = savedSRPAttributes();
    if (srpAttributes && !srpAttributes.isEmailMFAEnabled) {
        // Fetch the latest SRP attributes instead of relying on the potentially
        // stale stored values. This is an infrequent scenario path, so extra
        // API calls are fine.
        const latestSRPAttributes = await getSRPAttributes(email);
        if (latestSRPAttributes && !latestSRPAttributes.isEmailMFAEnabled) {
            return "/credentials";
        }
    }

    return { email };
};
