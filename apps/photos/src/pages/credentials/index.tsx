import React, { useContext, useEffect, useState } from 'react';

import { t } from 'i18next';

import {
    clearData,
    getData,
    LS_KEYS,
    setData,
} from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { PAGES } from 'constants/pages';
import {
    SESSION_KEYS,
    getKey,
    removeKey,
    setKey,
} from 'utils/storage/sessionStorage';
import {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    generateSRPSetupAttributes,
    saveKeyInSessionStore,
} from 'utils/crypto';
import { logoutUser, configureSRP, loginViaSRP } from 'services/userService';
import {
    getUserSRPSetupPending,
    isFirstLogin,
    setIsFirstLogin,
} from 'utils/storage';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { KeyAttributes, SRPAttributes, User } from 'types/user';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import isElectron from 'is-electron';
import safeStorageService from 'services/electron/safeStorage';
import { VerticallyCentered } from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from 'components/VerifyMasterPasswordForm';
import { APPS, getAppName } from 'constants/apps';
import { addLocalLog } from 'utils/logging';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { B64EncryptionResult } from 'types/crypto';
import { CustomError } from 'utils/error';

export default function Credentials() {
    const router = useRouter();
    const [srpAttributes, setSrpAttributes] = useState<SRPAttributes>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const appContext = useContext(AppContext);
    const [user, setUser] = useState<User>();

    useEffect(() => {
        router.prefetch(PAGES.GALLERY);
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email) {
                router.push(PAGES.ROOT);
                return;
            }
            setUser(user);
            let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            if (!key && isElectron()) {
                key = await safeStorageService.getEncryptionKey();
                if (key) {
                    await saveKeyInSessionStore(
                        SESSION_KEYS.ENCRYPTION_KEY,
                        key,
                        true
                    );
                }
                router.push(PAGES.GALLERY);
                return;
            }
            const kekEncryptedAttributes: B64EncryptionResult = getKey(
                SESSION_KEYS.KEY_ENCRYPTION_KEY
            );
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.KEY_ATTRIBUTES
            );
            if (kekEncryptedAttributes && keyAttributes) {
                removeKey(SESSION_KEYS.KEY_ENCRYPTION_KEY);
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
                const kek = await cryptoWorker.decryptB64(
                    kekEncryptedAttributes.encryptedData,
                    kekEncryptedAttributes.nonce,
                    kekEncryptedAttributes.key
                );
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                useMasterPassword(key, kek, keyAttributes, kek);
                return;
            }

            const srpAttributes: SRPAttributes = getData(
                LS_KEYS.SRP_ATTRIBUTES
            );
            if (srpAttributes) {
                setSrpAttributes(srpAttributes);
                return;
            }

            if (
                (!user?.token && !user?.encryptedToken) ||
                (keyAttributes && !keyAttributes.memLimit)
            ) {
                clearData();
                router.push(PAGES.ROOT);
                return;
            }

            if (!keyAttributes) {
                router.push(PAGES.GENERATE);
                return;
            }
            setKeyAttributes(keyAttributes);
        };
        main();
        appContext.showNavBar(true);
    }, []);

    const getKeyAttributes: VerifyMasterPasswordFormProps['getKeyAttributes'] =
        async (kek: string) => {
            try {
                const cryptoWorker = await ComlinkCryptoWorker.getInstance();
                const {
                    keyAttributes,
                    encryptedToken,
                    token,
                    id,
                    twoFactorSessionID,
                } = await loginViaSRP(srpAttributes, kek);
                setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
                if (twoFactorSessionID) {
                    const sessionKeyAttributes =
                        await cryptoWorker.generateKeyAndEncryptToB64(kek);
                    setKey(
                        SESSION_KEYS.KEY_ENCRYPTION_KEY,
                        sessionKeyAttributes
                    );
                    const user = getData(LS_KEYS.USER);
                    setData(LS_KEYS.USER, {
                        ...user,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    setIsFirstLogin(true);
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
                    return keyAttributes;
                }
            } catch (e) {
                if (e.message !== CustomError.TWO_FACTOR_ENABLED) {
                    logError(e, 'getKeyAttributes failed');
                }
                throw e;
            }
        };

    const useMasterPassword: VerifyMasterPasswordFormProps['callback'] = async (
        key,
        kek,
        keyAttributes,
        passphrase
    ) => {
        try {
            if (isFirstLogin() && passphrase) {
                await generateAndSaveIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    key
                );
            }
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
            await decryptAndStoreToken(keyAttributes, key);
            try {
                const userSRPSetupPending = getUserSRPSetupPending();
                addLocalLog(() => `userSRPSetupPending ${userSRPSetupPending}`);
                if (userSRPSetupPending) {
                    const loginSubKey = await generateLoginSubKey(kek);
                    const srpSetupAttributes = await generateSRPSetupAttributes(
                        loginSubKey
                    );
                    await configureSRP(srpSetupAttributes);
                }
            } catch (e) {
                logError(e, 'migrate to srp failed');
            }
            const redirectURL = appContext.redirectURL;
            appContext.setRedirectURL(null);
            const appName = getAppName();
            if (appName === APPS.AUTH) {
                router.push(PAGES.AUTH);
            } else {
                router.push(redirectURL ?? PAGES.GALLERY);
            }
        } catch (e) {
            logError(e, 'useMasterPassword failed');
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
            <FormPaper style={{ minWidth: '320px' }}>
                <FormPaperTitle>{t('PASSWORD')}</FormPaperTitle>

                <VerifyMasterPasswordForm
                    buttonText={t('VERIFY_PASSPHRASE')}
                    callback={useMasterPassword}
                    user={user}
                    keyAttributes={keyAttributes}
                    getKeyAttributes={getKeyAttributes}
                    srpAttributes={srpAttributes}
                />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton onClick={redirectToRecoverPage}>
                        {t('FORGOT_PASSWORD')}
                    </LinkButton>
                    <LinkButton onClick={logoutUser}>
                        {t('CHANGE_EMAIL')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
