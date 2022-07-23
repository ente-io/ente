import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import {
    clearData,
    getData,
    LS_KEYS,
    setData,
} from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { PAGES } from 'constants/pages';
import CryptoWorker, {
    decryptAndStoreToken,
    saveKeyInSessionStore,
} from 'utils/crypto';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import VerticallyCentered from 'components/Container';
import { Button } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { KeyAttributes, User } from 'types/user';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
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
        if (
            (!user?.token && !user?.encryptedToken) ||
            !keyAttributes?.memLimit
        ) {
            clearData();
            router.push(PAGES.ROOT);
        } else if (!keyAttributes) {
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
            // check if user is entering mnemonic recovery key
            if (recoveryKey.trim().indexOf(' ') > 0) {
                if (recoveryKey.trim().split(' ').length !== 24) {
                    throw new Error('recovery code should have 24 words');
                }
                recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
            }
            const cryptoWorker = await new CryptoWorker();
            const masterKey: string = await cryptoWorker.decryptB64(
                keyAttributes.masterKeyEncryptedWithRecoveryKey,
                keyAttributes.masterKeyDecryptionNonce,
                await cryptoWorker.fromHex(recoveryKey)
            );
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            await decryptAndStoreToken(masterKey);

            setData(LS_KEYS.SHOW_BACK_BUTTON, { value: false });
            router.push(PAGES.CHANGE_PASSWORD);
        } catch (e) {
            logError(e, 'password recovery failed');
            setFieldError(constants.INCORRECT_RECOVERY_KEY);
        }
    };

    const showNoRecoveryKeyMessage = () => {
        appContext.setDialogMessage({
            title: constants.SORRY,
            close: {},
            content: constants.NO_RECOVERY_KEY_MESSAGE,
        });
    };

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{constants.RECOVER_ACCOUNT}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={constants.RECOVERY_KEY_HINT}
                    buttonText={constants.RECOVER}
                />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <Button variant="link" onClick={showNoRecoveryKeyMessage}>
                        {constants.NO_RECOVERY_KEY}
                    </Button>
                    <Button variant="link" onClick={router.back}>
                        {constants.GO_BACK}
                    </Button>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
