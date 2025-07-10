import { AccountsPageContents } from "ente-accounts/components/layouts/centered-paper";
import {
    AccountsPageFooterWithHost,
    PasswordHeader,
    VerifyingPasskey,
} from "ente-accounts/components/LoginComponents";
import { SecondFactorChoice } from "ente-accounts/components/SecondFactorChoice";
import { sessionExpiredDialogAttributes } from "ente-accounts/components/utils/dialog";
import { useSecondFactorChoiceIfNeeded } from "ente-accounts/components/utils/second-factor-choice";
import {
    VerifyMasterPasswordForm,
    type VerifyMasterPasswordFormProps,
} from "ente-accounts/components/VerifyMasterPasswordForm";
import {
    savedIsFirstLogin,
    savedKeyAttributes,
    savedPartialLocalUser,
    savedSRPAttributes,
    saveIsFirstLogin,
    saveKeyAttributes,
    saveSRPAttributes,
    updateSavedLocalUser,
} from "ente-accounts/services/accounts-db";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "ente-accounts/services/passkey";
import {
    appHomeRoute,
    stashRedirect,
    unstashRedirect,
} from "ente-accounts/services/redirect";
import { checkSessionValidity } from "ente-accounts/services/session";
import type { SRPAttributes } from "ente-accounts/services/srp";
import {
    generateSRPSetupAttributes,
    getAndSaveSRPAttributes,
    getSRPAttributes,
    setupSRP,
    verifySRP,
} from "ente-accounts/services/srp";
import {
    decryptAndStoreTokenIfNeeded,
    generateAndSaveInteractiveKeyAttributes,
    type KeyAttributes,
} from "ente-accounts/services/user";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import { decryptBox } from "ente-base/crypto";
import { isDevBuild } from "ente-base/env";
import { clearLocalStorage } from "ente-base/local-storage";
import log from "ente-base/log";
import {
    masterKeyFromSession,
    saveMasterKeyInSessionAndSafeStore,
    stashKeyEncryptionKeyInSessionStore,
    unstashKeyEncryptionKeyFromSession,
    updateSessionFromElectronSafeStorageIfNeeded,
} from "ente-base/session";
import { saveAuthToken, savedAuthToken } from "ente-base/token";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";

/**
 * A page that allows the user to authenticate using their password.
 *
 * It is shown in two cases:
 *
 * - Initial authentication, when the user is logging in on to a new client.
 *
 * - Subsequent reauthentication, when the user opens the web app in a new tab.
 *   Such a tab won't have the user's master key in session storage, so we ask
 *   the user to reauthenticate using their password.
 *
 * See: [Note: Login pages]
 */
const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [userEmail, setUserEmail] = useState<string>("");
    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >(undefined);
    const [srpAttributes, setSRPAttributes] = useState<
        SRPAttributes | undefined
    >(undefined);
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >(undefined);
    const [sessionValidityCheck, setSessionValidityCheck] = useState<
        Promise<void> | undefined
    >(undefined);

    const {
        secondFactorChoiceProps,
        userVerificationResultAfterResolvingSecondFactorChoice,
    } = useSecondFactorChoiceIfNeeded();

    const router = useRouter();

    const validateSession = useCallback(async () => {
        const showSessionExpiredDialog = () =>
            showMiniDialog(sessionExpiredDialogAttributes(logout));

        try {
            const session = await checkSessionValidity();
            switch (session.status) {
                case "invalid":
                    showSessionExpiredDialog();
                    break;
                case "valid":
                    break;
                case "validButPasswordChanged":
                    saveKeyAttributes(session.updatedKeyAttributes);
                    saveSRPAttributes(session.updatedSRPAttributes);
                    // Set a flag that causes new interactive key attributes to
                    // be generated.
                    saveIsFirstLogin();
                    // This should be a rare occurrence, instead of building the
                    // scaffolding to update all the in-memory state, just
                    // reload everything.
                    window.location.reload();
            }
        } catch (e) {
            // Ignore errors since we shouldn't be logging the user out for
            // potentially transient issues.
            log.warn("Ignoring error when determining session validity", e);
        }
    }, [logout, showMiniDialog]);

    const postVerification = useCallback(
        async (
            userEmail: string,
            masterKey: string,
            kek: string,
            keyAttributes: KeyAttributes,
        ) => {
            await saveMasterKeyInSessionAndSafeStore(masterKey);
            await decryptAndStoreTokenIfNeeded(keyAttributes, masterKey);
            try {
                let srpAttributes = savedSRPAttributes();
                if (!srpAttributes) {
                    srpAttributes = await getSRPAttributes(userEmail);
                    if (srpAttributes) {
                        saveSRPAttributes(srpAttributes);
                    } else {
                        await setupSRP(await generateSRPSetupAttributes(kek));
                        await getAndSaveSRPAttributes(userEmail);
                    }
                }
            } catch (e) {
                log.error("SRP migration failed", e);
            }
            void router.push(unstashRedirect() ?? appHomeRoute);
        },
        [router],
    );

    useEffect(() => {
        void (async () => {
            const user = savedPartialLocalUser();
            const userEmail = user?.email;
            if (!userEmail) {
                await router.replace("/");
                return;
            }

            await updateSessionFromElectronSafeStorageIfNeeded();
            if ((await masterKeyFromSession()) && (await savedAuthToken())) {
                await router.replace(appHomeRoute);
                return;
            }

            setUserEmail(userEmail);
            if (user.token) setSessionValidityCheck(validateSession());

            const kek = await unstashKeyEncryptionKeyFromSession();
            const keyAttributes = savedKeyAttributes();

            // Refreshing an existing tab, or desktop app, or only the token
            // needs to decrypted and set.
            if (kek && keyAttributes) {
                const masterKey = await decryptBox(
                    {
                        encryptedData: keyAttributes.encryptedKey,
                        nonce: keyAttributes.keyDecryptionNonce,
                    },
                    kek,
                );
                await postVerification(
                    userEmail,
                    masterKey,
                    kek,
                    keyAttributes,
                );
                return;
            }

            // Reauthentication in a new tab on the web app. Use previously
            // generated interactive key attributes to verify password.
            if (keyAttributes) {
                if (!user.token && !user.encryptedToken) {
                    // TODO: Why? For now, add a dev mode circuit breaker.
                    if (isDevBuild) throw new Error("Unexpected case reached");
                    clearLocalStorage();
                    void router.replace("/");
                    return;
                }
                setKeyAttributes(keyAttributes);
                return;
            }

            // First login on a new client. `getKeyAttributes` from below will
            // be used during password verification to generate interactive key
            // attributes for subsequent reauthentications.
            const srpAttributes = savedSRPAttributes();
            if (srpAttributes) {
                setSRPAttributes(srpAttributes);
                return;
            }

            void router.replace("/");
        })();
    }, [router, validateSession, postVerification]);

    const getKeyAttributes: VerifyMasterPasswordFormProps["getKeyAttributes"] =
        useCallback(
            async (srpAttributes: SRPAttributes, kek: string) => {
                const {
                    id,
                    keyAttributes,
                    token,
                    encryptedToken,
                    twoFactorSessionID,
                    passkeySessionID,
                    accountsUrl,
                } =
                    await userVerificationResultAfterResolvingSecondFactorChoice(
                        await verifySRP(srpAttributes, kek),
                    );

                // If we had to ask remote for the key attributes, it is the
                // initial login on this client.
                saveIsFirstLogin();

                if (passkeySessionID) {
                    await stashKeyEncryptionKeyInSessionStore(kek);
                    updateSavedLocalUser({ passkeySessionID });
                    stashRedirect("/");
                    const url = passkeyVerificationRedirectURL(
                        accountsUrl!,
                        passkeySessionID,
                    );
                    setPasskeyVerificationData({ passkeySessionID, url });
                    openPasskeyVerificationURL({ passkeySessionID, url });
                    return "redirecting-second-factor";
                } else if (twoFactorSessionID) {
                    await stashKeyEncryptionKeyInSessionStore(kek);
                    updateSavedLocalUser({
                        isTwoFactorEnabled: true,
                        twoFactorSessionID,
                    });
                    void router.push("/two-factor/verify");
                    return "redirecting-second-factor";
                } else {
                    // In rare cases, if the user hasn't already setup their key
                    // attributes, we might get the plaintext token from remote.
                    if (token) await saveAuthToken(token);
                    updateSavedLocalUser({
                        id,
                        token,
                        encryptedToken,
                        isTwoFactorEnabled: undefined,
                        twoFactorSessionID: undefined,
                        passkeySessionID: undefined,
                    });
                    if (keyAttributes) saveKeyAttributes(keyAttributes);
                    return keyAttributes;
                }
            },
            [userVerificationResultAfterResolvingSecondFactorChoice, router],
        );

    const handleVerifyMasterPassword: VerifyMasterPasswordFormProps["onVerify"] =
        useCallback(
            (key, kek, keyAttributes, password) => {
                void (async () => {
                    // Currently the page will get reloaded if any of the
                    // attributes have changed, so we don't need to worry about
                    // the KEK having been generated using stale credentials.
                    //
                    // This await on the promise is here to only ensure we're
                    // done with the check before we let the user in.
                    if (sessionValidityCheck) await sessionValidityCheck;

                    const updatedKeyAttributes = savedIsFirstLogin()
                        ? await generateAndSaveInteractiveKeyAttributes(
                              password,
                              keyAttributes,
                              key,
                          )
                        : keyAttributes;

                    await postVerification(
                        userEmail,
                        key,
                        kek,
                        updatedKeyAttributes,
                    );
                })();
            },
            [postVerification, userEmail, sessionValidityCheck],
        );

    if (!userEmail) {
        return <LoadingIndicator />;
    }

    if (!keyAttributes && !srpAttributes) {
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
                email={userEmail}
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
            <PasswordHeader caption={userEmail} />
            <VerifyMasterPasswordForm
                {...{
                    userEmail,
                    keyAttributes,
                    getKeyAttributes,
                    srpAttributes,
                }}
                submitButtonTitle={t("sign_in")}
                onVerify={handleVerifyMasterPassword}
            />
            <AccountsPageFooterWithHost>
                <LinkButton onClick={() => router.push("/recover")}>
                    {t("forgot_password")}
                </LinkButton>
                <LinkButton onClick={logout}>{t("change_email")}</LinkButton>
            </AccountsPageFooterWithHost>
            <SecondFactorChoice {...secondFactorChoiceProps} />
        </AccountsPageContents>
    );
};

export default Page;
