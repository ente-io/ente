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
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "ente-accounts/services/passkey";
import {
    appHomeRoute,
    stashRedirect,
    unstashRedirect,
} from "ente-accounts/services/redirect";
import { checkSessionValidity } from "ente-accounts/services/session";
import {
    configureSRP,
    generateSRPSetupAttributes,
    loginViaSRP,
} from "ente-accounts/services/srp";
import type { SRPAttributes } from "ente-accounts/services/srp-remote";
import { getSRPAttributes } from "ente-accounts/services/srp-remote";
import { LinkButton } from "ente-base/components/LinkButton";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useBaseContext } from "ente-base/context";
import { sharedCryptoWorker } from "ente-base/crypto";
import type { B64EncryptionResult } from "ente-base/crypto/libsodium";
import { clearLocalStorage } from "ente-base/local-storage";
import log from "ente-base/log";
import VerifyMasterPasswordForm, {
    type VerifyMasterPasswordFormProps,
} from "ente-shared/components/VerifyMasterPasswordForm";
import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "ente-shared/crypto/helpers";
import { CustomError } from "ente-shared/error";
import { getData, setData, setLSUser } from "ente-shared/storage/localStorage";
import {
    getToken,
    isFirstLogin,
    setIsFirstLogin,
} from "ente-shared/storage/localStorage/helpers";
import { getKey, removeKey, setKey } from "ente-shared/storage/sessionStorage";
import type { KeyAttributes, User } from "ente-shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";

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
                    setIsFirstLogin(true);
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
            let key = getKey("encryptionKey");
            const electron = globalThis.electron;
            if (!key && electron) {
                try {
                    key = await electron.masterKeyB64();
                } catch (e) {
                    log.error("Failed to read master key from safe storage", e);
                }
                if (key) {
                    await saveKeyInSessionStore("encryptionKey", key, true);
                }
            }
            const token = getToken();
            if (key && token) {
                void router.push(appHomeRoute);
                return;
            }
            const kekEncryptedAttributes: B64EncryptionResult =
                getKey("keyEncryptionKey");
            const keyAttributes: KeyAttributes = getData("keyAttributes");
            const srpAttributes: SRPAttributes = getData("srpAttributes");

            if (token) {
                setSessionValidityCheck(validateSession());
            }

            if (kekEncryptedAttributes && keyAttributes) {
                removeKey("keyEncryptionKey");
                const cryptoWorker = await sharedCryptoWorker();
                const kek = await cryptoWorker.decryptB64(
                    kekEncryptedAttributes.encryptedData,
                    kekEncryptedAttributes.nonce,
                    kekEncryptedAttributes.key,
                );
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek,
                );
                // eslint-disable-next-line react-hooks/rules-of-hooks
                useMasterPassword(key, kek, keyAttributes);
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
                // have changed, so we don't need to worry about the kek having
                // been generated using stale credentials. This await on the
                // promise is here to only ensure we're done with the check
                // before we let the user in.
                if (sessionValidityCheck) await sessionValidityCheck;

                const cryptoWorker = await sharedCryptoWorker();
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
                        await loginViaSRP(srpAttributes!, kek),
                    );
                setIsFirstLogin(true);

                if (passkeySessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey("keyEncryptionKey", sessionKeyAttributes);
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
                    throw Error(CustomError.TWO_FACTOR_ENABLED);
                } else if (twoFactorSessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey("keyEncryptionKey", sessionKeyAttributes);
                    const user = getData("user");
                    await setLSUser({
                        ...user,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    void router.push("/two-factor/verify");
                    throw Error(CustomError.TWO_FACTOR_ENABLED);
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
                    e.message != CustomError.TWO_FACTOR_ENABLED
                ) {
                    log.error("getKeyAttributes failed", e);
                }
                throw e;
            }
        };

    // eslint-disable-next-line @typescript-eslint/no-misused-promises
    const useMasterPassword: VerifyMasterPasswordFormProps["callback"] = async (
        key,
        kek,
        keyAttributes,
        passphrase,
    ) => {
        try {
            if (isFirstLogin() && passphrase) {
                await generateAndSaveIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    key,
                );
            }
            await saveKeyInSessionStore("encryptionKey", key);
            await decryptAndStoreToken(keyAttributes, key);
            try {
                let srpAttributes: SRPAttributes | null =
                    getData("srpAttributes");
                if (!srpAttributes && user) {
                    srpAttributes = await getSRPAttributes(user.email);
                    if (srpAttributes) {
                        setData("srpAttributes", srpAttributes);
                    }
                }
                log.debug(() => `userSRPSetupPending ${!srpAttributes}`);
                if (!srpAttributes) {
                    const loginSubKey = await generateLoginSubKey(kek);
                    const srpSetupAttributes =
                        await generateSRPSetupAttributes(loginSubKey);
                    await configureSRP(srpSetupAttributes);
                }
            } catch (e) {
                log.error("migrate to srp failed", e);
            }
            void router.push(unstashRedirect() ?? appHomeRoute);
        } catch (e) {
            log.error("useMasterPassword failed", e);
        }
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
            <PasswordHeader>{user?.email ?? ""}</PasswordHeader>

            <VerifyMasterPasswordForm
                buttonText={t("sign_in")}
                callback={useMasterPassword}
                user={user}
                keyAttributes={keyAttributes}
                getKeyAttributes={getKeyAttributes}
                srpAttributes={srpAttributes}
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
