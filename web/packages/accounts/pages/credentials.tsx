import { isDevBuild } from "@/next/env";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import LinkButton from "@ente/shared/components/LinkButton";
import {
    ConnectionDetails,
    PasswordHeader,
    VerifyingPasskey,
} from "@ente/shared/components/LoginComponents";
import VerifyMasterPasswordForm, {
    type VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import type { B64EncryptionResult } from "@ente/shared/crypto/types";
import { CustomError } from "@ente/shared/error";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import {
    LS_KEYS,
    clearData,
    getData,
    setData,
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
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { getSRPAttributes } from "../api/srp";
import { PAGES } from "../constants/pages";
import {
    openPasskeyVerificationURL,
    passkeyVerificationRedirectURL,
} from "../services/passkey";
import { appHomeRoute } from "../services/redirect";
import {
    configureSRP,
    generateSRPSetupAttributes,
    loginViaSRP,
} from "../services/srp";
import type { PageProps } from "../types/page";
import type { SRPAttributes } from "../types/srp";

const Page: React.FC<PageProps> = ({ appContext }) => {
    const { appName, logout } = appContext;

    const [srpAttributes, setSrpAttributes] = useState<SRPAttributes>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [user, setUser] = useState<User>();
    const [passkeyVerificationData, setPasskeyVerificationData] = useState<
        { passkeySessionID: string; url: string } | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email) {
                router.push(PAGES.ROOT);
                return;
            }
            setUser(user);
            let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const electron = globalThis.electron;
            if (!key && electron) {
                try {
                    key = await electron.encryptionKey();
                } catch (e) {
                    log.error("Failed to get encryption key from electron", e);
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
                router.push(appHomeRoute(appName));
                return;
            }
            const kekEncryptedAttributes: B64EncryptionResult = getKey(
                SESSION_KEYS.KEY_ENCRYPTION_KEY,
            );
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.KEY_ATTRIBUTES,
            );
            if (kekEncryptedAttributes && keyAttributes) {
                removeKey(SESSION_KEYS.KEY_ENCRYPTION_KEY);
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
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
                useMasterPassword(key, kek, keyAttributes);
                return;
            }
            if (keyAttributes) {
                if (
                    (!user?.token && !user?.encryptedToken) ||
                    (keyAttributes && !keyAttributes.memLimit)
                ) {
                    clearData();
                    router.push(PAGES.ROOT);
                    return;
                }
                setKeyAttributes(keyAttributes);
                return;
            }

            const srpAttributes: SRPAttributes = getData(
                LS_KEYS.SRP_ATTRIBUTES,
            );
            if (srpAttributes) {
                setSrpAttributes(srpAttributes);
            } else {
                router.push(PAGES.ROOT);
            }
        };
        main();
        appContext.showNavBar(true);
    }, []);

    const getKeyAttributes: VerifyMasterPasswordFormProps["getKeyAttributes"] =
        async (kek: string) => {
            try {
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
                const {
                    keyAttributes,
                    encryptedToken,
                    token,
                    id,
                    twoFactorSessionID,
                    passkeySessionID,
                } = await loginViaSRP(ensure(srpAttributes), kek);
                setIsFirstLogin(true);
                if (passkeySessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey(
                        SESSION_KEYS.KEY_ENCRYPTION_KEY,
                        sessionKeyAttributes,
                    );
                    const user = getData(LS_KEYS.USER);
                    setData(LS_KEYS.USER, {
                        ...user,
                        passkeySessionID,
                        isTwoFactorEnabled: true,
                        isTwoFactorPasskeysEnabled: true,
                    });
                    InMemoryStore.set(MS_KEYS.REDIRECT_URL, PAGES.ROOT);
                    const url = passkeyVerificationRedirectURL(
                        appName,
                        passkeySessionID,
                    );
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
                    setData(LS_KEYS.USER, {
                        ...user,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    router.push(PAGES.TWO_FACTOR_VERIFY);
                    throw Error(CustomError.TWO_FACTOR_ENABLED);
                } else {
                    const user = getData(LS_KEYS.USER);
                    setData(LS_KEYS.USER, {
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
            const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
            InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
            router.push(redirectURL ?? appHomeRoute(appName));
        } catch (e) {
            log.error("useMasterPassword failed", e);
        }
    };

    if (!keyAttributes && !srpAttributes) {
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
                email={user?.email}
                passkeySessionID={passkeyVerificationData?.passkeySessionID}
                onRetry={() =>
                    openPasskeyVerificationURL(passkeyVerificationData)
                }
                appContext={appContext}
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

                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton onClick={() => router.push(PAGES.RECOVER)}>
                        {t("FORGOT_PASSWORD")}
                    </LinkButton>
                    <LinkButton onClick={logout}>
                        {t("CHANGE_EMAIL")}
                    </LinkButton>
                </FormPaperFooter>

                {isDevBuild && <ConnectionDetails />}
            </FormPaper>
        </VerticallyCentered>
    );
};

export default Page;
