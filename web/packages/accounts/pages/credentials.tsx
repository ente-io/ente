import { sessionExpiredDialogAttributes } from "@/accounts/components/utils/dialog";
import { FormPaper } from "@/base/components/FormPaper";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { sharedCryptoWorker } from "@/base/crypto";
import type { B64EncryptionResult } from "@/base/crypto/libsodium";
import { clearLocalStorage } from "@/base/local-storage";
import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import VerifyMasterPasswordForm, {
    type VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { CustomError } from "@ente/shared/error";
import {
    LS_KEYS,
    getData,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import {
    getToken,
    isFirstLogin,
    setIsFirstLogin,
} from "@ente/shared/storage/localStorage/helpers";
import {
    SESSION_KEYS,
    getKey,
    removeKey,
    setKey,
} from "@ente/shared/storage/sessionStorage";
import type { KeyAttributes, User } from "@ente/shared/user/types";
import { Stack } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";
import {
    LoginFlowFormFooter,
    PasswordHeader,
    VerifyingPasskey,
} from "../components/LoginComponents";
import { SecondFactorChoice } from "../components/SecondFactorChoice";
import { useSecondFactorChoiceIfNeeded } from "../components/utils/second-factor-choice";
import { PAGES } from "../constants/pages";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "../services/passkey";
import {
    appHomeRoute,
    stashRedirect,
    unstashRedirect,
} from "../services/redirect";
import { checkSessionValidity } from "../services/session";
import {
    configureSRP,
    generateSRPSetupAttributes,
    loginViaSRP,
} from "../services/srp";
import type { SRPAttributes } from "../services/srp-remote";
import { getSRPAttributes } from "../services/srp-remote";
import type { PageProps } from "../types/page";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { logout, showNavBar, showMiniDialog } = appContext;

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
                    setData(
                        LS_KEYS.KEY_ATTRIBUTES,
                        session.updatedKeyAttributes,
                    );
                    setData(
                        LS_KEYS.SRP_ATTRIBUTES,
                        session.updatedSRPAttributes,
                    );
                    // Set a flag that causes new interactive key attributes to
                    // be generated.
                    setIsFirstLogin(true);
                    // This should be a rare occurence, instead of building the
                    // scaffolding to update all the in-memory state, just
                    // reload everything.
                    window.location.reload();
            }
        } catch (e) {
            // Ignore errors since we shouldn't be logging the user out for
            // potentially transient issues.
            log.warn("Ignoring error when determining session validity", e);
        }
    }, [showMiniDialog, logout]);

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email) {
                void router.push("/");
                return;
            }
            setUser(user);
            let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const electron = globalThis.electron;
            if (!key && electron) {
                try {
                    key = await electron.masterKeyB64();
                } catch (e) {
                    log.error("Failed to read master key from safe storage", e);
                }
                if (key) {
                    await saveKeyInSessionStore(
                        SESSION_KEYS.ENCRYPTION_KEY,
                        key,
                        true,
                    );
                }
            }
            const token = getToken();
            if (key && token) {
                void router.push(appHomeRoute);
                return;
            }
            const kekEncryptedAttributes: B64EncryptionResult = getKey(
                SESSION_KEYS.KEY_ENCRYPTION_KEY,
            );
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.KEY_ATTRIBUTES,
            );
            const srpAttributes: SRPAttributes = getData(
                LS_KEYS.SRP_ATTRIBUTES,
            );

            if (token) {
                setSessionValidityCheck(validateSession());
            }

            if (kekEncryptedAttributes && keyAttributes) {
                removeKey(SESSION_KEYS.KEY_ENCRYPTION_KEY);
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
        showNavBar(true);
    }, []);
    // TODO: ^ validateSession is a dependency, but add that only after we've
    // wrapped items from the callback (like logout) in useCallback too.

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
                } =
                    await userVerificationResultAfterResolvingSecondFactorChoice(
                        await loginViaSRP(srpAttributes!, kek),
                    );
                setIsFirstLogin(true);

                if (passkeySessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey(
                        SESSION_KEYS.KEY_ENCRYPTION_KEY,
                        sessionKeyAttributes,
                    );
                    const user = getData(LS_KEYS.USER);
                    await setLSUser({
                        ...user,
                        passkeySessionID,
                        isTwoFactorEnabled: true,
                        isTwoFactorPasskeysEnabled: true,
                    });
                    stashRedirect("/");
                    const url =
                        passkeyVerificationRedirectURL(passkeySessionID);
                    setPasskeyVerificationData({ passkeySessionID, url });
                    openPasskeyVerificationURL({ passkeySessionID, url });
                    throw Error(CustomError.TWO_FACTOR_ENABLED);
                } else if (twoFactorSessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey(
                        SESSION_KEYS.KEY_ENCRYPTION_KEY,
                        sessionKeyAttributes,
                    );
                    const user = getData(LS_KEYS.USER);
                    await setLSUser({
                        ...user,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    void router.push(PAGES.TWO_FACTOR_VERIFY);
                    throw Error(CustomError.TWO_FACTOR_ENABLED);
                } else {
                    const user = getData(LS_KEYS.USER);
                    await setLSUser({
                        ...user,
                        token,
                        encryptedToken,
                        id,
                        isTwoFactorEnabled: false,
                    });
                    if (keyAttributes)
                        setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
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
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
            await decryptAndStoreToken(keyAttributes, key);
            try {
                let srpAttributes: SRPAttributes | null = getData(
                    LS_KEYS.SRP_ATTRIBUTES,
                );
                if (!srpAttributes && user) {
                    srpAttributes = await getSRPAttributes(user.email);
                    if (srpAttributes) {
                        setData(LS_KEYS.SRP_ATTRIBUTES, srpAttributes);
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
        <VerticallyCentered>
            <FormPaper style={{ minWidth: "320px" }}>
                <PasswordHeader>{user?.email ?? ""}</PasswordHeader>

                <VerifyMasterPasswordForm
                    buttonText={t("VERIFY_PASSPHRASE")}
                    callback={useMasterPassword}
                    user={user}
                    keyAttributes={keyAttributes}
                    getKeyAttributes={getKeyAttributes}
                    srpAttributes={srpAttributes}
                />

                <LoginFlowFormFooter>
                    <Stack direction="row" justifyContent="space-between">
                        <LinkButton onClick={() => router.push(PAGES.RECOVER)}>
                            {t("FORGOT_PASSWORD")}
                        </LinkButton>
                        <LinkButton onClick={logout}>
                            {t("CHANGE_EMAIL")}
                        </LinkButton>
                    </Stack>
                </LoginFlowFormFooter>
            </FormPaper>

            <SecondFactorChoice {...secondFactorChoiceProps} />
        </VerticallyCentered>
    );
};

export default Page;
