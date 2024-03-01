import { useEffect, useState } from "react";

import { t } from "i18next";

import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    saveKeyInSessionStore,
} from "@ente/shared/crypto/helpers";
import {
    LS_KEYS,
    clearData,
    getData,
    setData,
} from "@ente/shared/storage/localStorage";
import {
    SESSION_KEYS,
    getKey,
    removeKey,
    setKey,
} from "@ente/shared/storage/sessionStorage";
import { PAGES } from "../constants/pages";
import { generateSRPSetupAttributes } from "../services/srp";
import { logoutUser } from "../services/user";

import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import FormPaperFooter from "@ente/shared/components/Form/FormPaper/Footer";
import FormPaperTitle from "@ente/shared/components/Form/FormPaper/Title";
import LinkButton from "@ente/shared/components/LinkButton";
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import { getAccountsURL } from "@ente/shared/network/api";
import {
    isFirstLogin,
    setIsFirstLogin,
} from "@ente/shared/storage/localStorage/helpers";
import { KeyAttributes, User } from "@ente/shared/user/types";
import isElectron from "is-electron";
import { getSRPAttributes } from "../api/srp";
import { configureSRP, loginViaSRP } from "../services/srp";
import { SRPAttributes } from "../types/srp";
// import { APPS, getAppName } from '@ente/shared/apps';
import { APP_HOMES } from "@ente/shared/apps/constants";
import { PageProps } from "@ente/shared/apps/types";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { B64EncryptionResult } from "@ente/shared/crypto/types";
import ElectronAPIs from "@ente/shared/electron";
import { CustomError } from "@ente/shared/error";
import { addLocalLog } from "@ente/shared/logging";
import { logError } from "@ente/shared/sentry";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";

export default function Credentials({
    appContext,
    router,
    appName,
}: PageProps) {
    const [srpAttributes, setSrpAttributes] = useState<SRPAttributes>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [user, setUser] = useState<User>();

    useEffect(() => {
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email) {
                router.push(PAGES.ROOT);
                return;
            }
            setUser(user);
            let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            if (!key && isElectron()) {
                try {
                    key = await ElectronAPIs.getEncryptionKey();
                } catch (e) {
                    logError(e, "getEncryptionKey failed");
                }
                if (key) {
                    await saveKeyInSessionStore(
                        SESSION_KEYS.ENCRYPTION_KEY,
                        key,
                        true,
                    );
                }
            }
            if (key) {
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
                    logError(e, "getKeyAttributes failed");
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
                addLocalLog(() => `userSRPSetupPending ${!srpAttributes}`);
                if (!srpAttributes) {
                    const loginSubKey = await generateLoginSubKey(kek);
                    const srpSetupAttributes =
                        await generateSRPSetupAttributes(loginSubKey);
                    await configureSRP(srpSetupAttributes);
                }
            } catch (e) {
                logError(e, "migrate to srp failed");
            }
            const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
            InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
            router.push(redirectURL ?? APP_HOMES.get(appName));
        } catch (e) {
            logError(e, "useMasterPassword failed");
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
