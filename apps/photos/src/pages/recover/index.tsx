import React, { useContext, useEffect, useState } from 'react';
import { t } from 'i18next';

import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { PAGES } from 'constants/pages';
import { decryptAndStoreToken, saveKeyInSessionStore } from 'utils/crypto';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { VerticallyCentered } from 'components/Container';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { KeyAttributes, User } from 'types/user';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { sendOtt } from 'services/userService';
import InMemoryStore, { MS_KEYS } from 'services/InMemoryStore';
const bip39 = require('bip39');
// mobile client library only supports english.
bip39.setDefaultWordlist('english');

export default function Recover() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const appContext = useContext(AppContext);

    useEffect(() => {
        router.prefetch(PAGES.GALLERY);
        const user: User = getData(LS_KEYS.USER);
        const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!user?.email) {
            router.push(PAGES.ROOT);
            return;
        }
        if (!user?.encryptedToken && !user?.token) {
            sendOtt(user.email);
            InMemoryStore.set(MS_KEYS.REDIRECT_URL, PAGES.RECOVER);
            router.push(PAGES.VERIFY);
            return;
        }
        if (!keyAttributes) {
            router.push(PAGES.GENERATE);
        } else if (key) {
            router.push(PAGES.GALLERY);
        } else {
            setKeyAttributes(keyAttributes);
        }
        appContext.showNavBar(true);
    }, []);

    const recover: SingleInputFormProps['callback'] = async (
        recoveryKey: string,
        setFieldError
    ) => {
        try {
            recoveryKey = recoveryKey
                .trim()
                .split(' ')
                .map((part) => part.trim())
                .filter((part) => !!part)
                .join(' ');
            // check if user is entering mnemonic recovery key
            if (recoveryKey.indexOf(' ') > 0) {
                if (recoveryKey.split(' ').length !== 24) {
                    throw new Error('recovery code should have 24 words');
                }
                recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
            }
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
            const masterKey = await cryptoWorker.decryptB64(
                keyAttributes.masterKeyEncryptedWithRecoveryKey,
                keyAttributes.masterKeyDecryptionNonce,
                await cryptoWorker.fromHex(recoveryKey)
            );
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            await decryptAndStoreToken(keyAttributes, masterKey);

            setData(LS_KEYS.SHOW_BACK_BUTTON, { value: false });
            router.push(PAGES.CHANGE_PASSWORD);
        } catch (e) {
            logError(e, 'password recovery failed');
            setFieldError(t('INCORRECT_RECOVERY_KEY'));
        }
    };

    const showNoRecoveryKeyMessage = () => {
        appContext.setDialogMessage({
            title: t('SORRY'),
            close: {},
            content: t('NO_RECOVERY_KEY_MESSAGE'),
        });
    };

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t('RECOVER_ACCOUNT')}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={t('RECOVERY_KEY_HINT')}
                    buttonText={t('RECOVER')}
                    disableAutoComplete
                />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton onClick={showNoRecoveryKeyMessage}>
                        {t('NO_RECOVERY_KEY')}
                    </LinkButton>
                    <LinkButton onClick={router.back}>
                        {t('GO_BACK')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
