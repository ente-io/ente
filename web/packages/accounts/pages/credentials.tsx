import log from "@/next/log";
import { APP_HOMES } from "@ente/shared/apps/constants";
import { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import { B64EncryptionResult } from "@ente/shared/crypto/types";
import { CustomError } from "@ente/shared/error";
import { getAccountsURL } from "@ente/shared/network/api";
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
import { KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { getSRPAttributes } from "../api/srp";
import { PAGES } from "../constants/pages";
import {
    configureSRP,
    generateSRPSetupAttributes,
    loginViaSRP,
} from "../services/srp";
import { logoutUser } from "../services/user";
import { SRPAttributes } from "../types/srp";

export default function Credentials({ appContext, appName }: PageProps) {
    const [srpAttributes, setSrpAttributes] = useState<SRPAttributes>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [user, setUser] = useState<User>();

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
                    key = await electron.getEncryptionKey();
                } catch (e) {
                    log.error("getEncryptionKey failed", e);
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
                router.push(APP_HOMES.get(appName));
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
                } = await loginViaSRP(srpAttributes, kek);
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
                    window.location.href = `${getAccountsURL()}/passkeys/flow?passkeySessionID=${passkeySessionID}&redirect=${
                        window.location.origin
                    }/passkeys/finish`;
                    return;
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
                    setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
                    return keyAttributes;
                }
            } catch (e) {
                if (e.message !== CustomError.TWO_FACTOR_ENABLED) {
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
                let srpAttributes: SRPAttributes = getData(
                    LS_KEYS.SRP_ATTRIBUTES,
                );
                if (!srpAttributes) {
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
            router.push(redirectURL ?? APP_HOMES.get(appName));
        } catch (e) {
            log.error("useMasterPassword failed", e);
        }
    };

    const redirectToRecoverPage = () => router.push(PAGES.RECOVER);

    if (!keyAttributes && !srpAttributes) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    return (
        <VerticallyCentered>
            <FormPaper style={{ minWidth: "320px" }}>
                <FormPaperTitle>{t("PASSWORD")}</FormPaperTitle>

                <VerifyMasterPasswordForm
                    buttonText={t("VERIFY_PASSPHRASE")}
                    callback={useMasterPassword}
                    user={user}
                    keyAttributes={keyAttributes}
                    getKeyAttributes={getKeyAttributes}
                    srpAttributes={srpAttributes}
                />
                <FormPaperFooter style={{ justifyContent: "space-between" }}>
                    <LinkButton onClick={redirectToRecoverPage}>
                        {t("FORGOT_PASSWORD")}
                    </LinkButton>
                    <LinkButton onClick={logoutUser}>
                        {t("CHANGE_EMAIL")}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
