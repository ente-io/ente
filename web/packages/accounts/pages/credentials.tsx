import { AccountsPageContents } from "ente-accounts/components/layouts/centered-paper";
import {
    AccountsPageFooterWithHost,
    PasswordHeader,
    VerifyingPasskey,
} from "ente-accounts/components/LoginComponents";
import { SecondFactorChoice } from "ente-accounts/components/SecondFactorChoice";
import { sessionExpiredDialogAttributes } from "ente-accounts/components/utils/dialog";
import {
    twoFactorEnabledErrorMessage,
    useSecondFactorChoiceIfNeeded,
} from "ente-accounts/components/utils/second-factor-choice";
import {
    VerifyMasterPasswordForm,
    type VerifyMasterPasswordFormProps,
} from "ente-accounts/components/VerifyMasterPasswordForm";
import {
    getData,
    getToken,
    savedIsFirstLogin,
    saveIsFirstLogin,
    setData,
    setLSUser,
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
    getSRPAttributes,
    setupSRP,
    verifySRP,
} from "ente-accounts/services/srp";
import {
    generateAndSaveInteractiveKeyAttributes,
    type KeyAttributes,
    type User,
} from "ente-accounts/services/user";
import { decryptAndStoreToken } from "ente-accounts/utils/helpers";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import { decryptBox } from "ente-base/crypto";
import { clearLocalStorage } from "ente-base/local-storage";
import log from "ente-base/log";
import {
    haveAuthenticatedSession,
    saveMasterKeyInSessionAndSafeStore,
    stashKeyEncryptionKeyInSessionStore,
    unstashKeyEncryptionKeyFromSession,
    updateSessionFromElectronSafeStorageIfNeeded,
} from "ente-base/session";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";

/**
 * A page that allows the user to authenticate using their password.
 */
const Page: React.FC = () => {
    const { logout, showMiniDialog } = useBaseContext();

    const [srpAttributes, setSrpAttributes] = useState<SRPAttributes>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [user, setUser] = useState<User>();
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();
    const [sessionValidityCheck, setSessionValidityCheck] = useState<
        Promise<void> | undefined
    >();
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
                    setData("keyAttributes", session.updatedKeyAttributes);
                    setData("srpAttributes", session.updatedSRPAttributes);
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

    useEffect(() => {
        const main = async () => {
            const user: User = getData("user");
            if (!user?.email) {
                void router.push("/");
                return;
            }
            setUser(user);
            await updateSessionFromElectronSafeStorageIfNeeded();
            if (await haveAuthenticatedSession()) {
                void router.push(appHomeRoute);
                return;
            }
            const kek = await unstashKeyEncryptionKeyFromSession();
            const keyAttributes: KeyAttributes = getData("keyAttributes");
            const srpAttributes: SRPAttributes = getData("srpAttributes");

            if (getToken()) {
                setSessionValidityCheck(validateSession());
            }

            if (kek && keyAttributes) {
                const masterKey = await decryptBox(
                    {
                        encryptedData: keyAttributes.encryptedKey,
                        nonce: keyAttributes.keyDecryptionNonce,
                    },
                    kek,
                );
                void postVerification(masterKey, kek, keyAttributes);
                return;
            }

            if (keyAttributes) {
                if (
                    (!user?.token && !user?.encryptedToken) ||
                    (keyAttributes && !keyAttributes.memLimit)
                ) {
                    clearLocalStorage();
                    void router.push("/");
                    return;
                }
                setKeyAttributes(keyAttributes);
                return;
            }

            if (srpAttributes) {
                setSrpAttributes(srpAttributes);
            } else {
                void router.push("/");
            }
        };
        void main();
        // TODO: validateSession is a dependency, but add that only after we've
        // wrapped items from the callback (like logout) in useCallback too.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const getKeyAttributes: VerifyMasterPasswordFormProps["getKeyAttributes"] =
        async (kek: string) => {
            try {
                // Currently the page will get reloaded if any of the attributes
                // have changed, so we don't need to worry about the KEK having
                // been generated using stale credentials. This await on the
                // promise is here to only ensure we're done with the check
                // before we let the user in.
                if (sessionValidityCheck) await sessionValidityCheck;

                const {
                    keyAttributes,
                    encryptedToken,
                    token,
                    id,
                    twoFactorSessionID,
                    passkeySessionID,
                    accountsUrl,
                } =
                    await userVerificationResultAfterResolvingSecondFactorChoice(
                        await verifySRP(srpAttributes!, kek),
                    );
                saveIsFirstLogin();

                if (passkeySessionID) {
                    await stashKeyEncryptionKeyInSessionStore(kek);
                    const user = getData("user");
                    await setLSUser({
                        ...user,
                        passkeySessionID,
                        isTwoFactorEnabled: true,
                        isTwoFactorPasskeysEnabled: true,
                    });
                    stashRedirect("/");
                    const url = passkeyVerificationRedirectURL(
                        accountsUrl!,
                        passkeySessionID,
                    );
                    setPasskeyVerificationData({ passkeySessionID, url });
                    openPasskeyVerificationURL({ passkeySessionID, url });
                    throw new Error(twoFactorEnabledErrorMessage);
                } else if (twoFactorSessionID) {
                    await stashKeyEncryptionKeyInSessionStore(kek);
                    const user = getData("user");
                    await setLSUser({
                        ...user,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    void router.push("/two-factor/verify");
                    throw new Error(twoFactorEnabledErrorMessage);
                } else {
                    const user = getData("user");
                    await setLSUser({
                        ...user,
                        token,
                        encryptedToken,
                        id,
                        isTwoFactorEnabled: false,
                    });
                    if (keyAttributes) setData("keyAttributes", keyAttributes);
                    return keyAttributes;
                }
            } catch (e) {
                if (
                    e instanceof Error &&
                    e.message != twoFactorEnabledErrorMessage
                ) {
                    log.error("getKeyAttributes failed", e);
                }
                throw e;
            }
        };

    const handleVerifyMasterPassword: VerifyMasterPasswordFormProps["onVerify"] =
        (key, kek, keyAttributes, password) => {
            void (async () => {
                const updatedKeyAttributes = savedIsFirstLogin()
                    ? await generateAndSaveInteractiveKeyAttributes(
                          password,
                          keyAttributes,
                          key,
                      )
                    : keyAttributes;
                await postVerification(key, kek, updatedKeyAttributes);
            })();
        };

    const postVerification = async (
        masterKey: string,
        kek: string,
        keyAttributes: KeyAttributes,
    ) => {
        await saveMasterKeyInSessionAndSafeStore(masterKey);
        await decryptAndStoreToken(keyAttributes, masterKey);
        try {
            let srpAttributes: SRPAttributes | null | undefined =
                getData("srpAttributes");
            if (!srpAttributes && user) {
                srpAttributes = await getSRPAttributes(user.email);
                if (srpAttributes) {
                    setData("srpAttributes", srpAttributes);
                }
            }
            log.debug(() => `userSRPSetupPending ${!srpAttributes}`);
            if (!srpAttributes) {
                await setupSRP(await generateSRPSetupAttributes(kek));
            }
        } catch (e) {
            log.error("migrate to srp failed", e);
        }
        void router.push(unstashRedirect() ?? appHomeRoute);
    };

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
                email={user?.email}
                passkeySessionID={passkeyVerificationData?.passkeySessionID}
                onRetry={() =>
                    openPasskeyVerificationURL(passkeyVerificationData)
                }
                {...{ logout, showMiniDialog }}
            />
        );
    }

    // TODO: Handle the case when user is not present, or exclude that
    // possibility using types.
    return (
        <AccountsPageContents>
            <PasswordHeader caption={user?.email} />
            <VerifyMasterPasswordForm
                user={user}
                keyAttributes={keyAttributes}
                getKeyAttributes={getKeyAttributes}
                srpAttributes={srpAttributes}
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
