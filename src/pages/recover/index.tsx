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
    SaveKeyInSessionStore,
} from 'utils/crypto';
import SingleInputForm from 'components/SingleInputForm';
import MessageDialog from 'components/MessageDialog';
import VerticallyCenteredContainer from 'components/Container';
import { Card, Button } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import LogoImg from 'components/LogoImg';
import { logError } from 'utils/sentry';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { KeyAttributes, User } from 'types/user';
const bip39 = require('bip39');
// mobile client library only supports english.
bip39.setDefaultWordlist('english');

export default function Recover() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [messageDialogView, SetMessageDialogView] = useState(false);
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
        appContext.showNavBar(false);
    }, []);

    const recover = async (recoveryKey: string, setFieldError) => {
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
            await SaveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            await decryptAndStoreToken(masterKey);

            setData(LS_KEYS.SHOW_BACK_BUTTON, { value: false });
            router.push(PAGES.CHANGE_PASSWORD);
        } catch (e) {
            logError(e, 'password recovery failed');
            setFieldError('passphrase', constants.INCORRECT_RECOVERY_KEY);
        }
    };

    return (
        <>
            <VerticallyCenteredContainer>
                <Card style={{ minWidth: '320px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src="/icon.svg" />
                            {constants.RECOVER_ACCOUNT}
                        </Card.Title>
                        <SingleInputForm
                            callback={recover}
                            fieldType="text"
                            placeholder={constants.RETURN_RECOVERY_KEY_HINT}
                            buttonText={constants.RECOVER}
                        />
                        <div
                            style={{
                                display: 'flex',
                                flexDirection: 'column',
                                marginTop: '12px',
                            }}>
                            <Button
                                variant="link"
                                onClick={() => SetMessageDialogView(true)}>
                                {constants.NO_RECOVERY_KEY}
                            </Button>
                            <Button variant="link" onClick={router.back}>
                                {constants.GO_BACK}
                            </Button>
                        </div>
                    </Card.Body>
                </Card>
            </VerticallyCenteredContainer>
            <MessageDialog
                size="lg"
                show={messageDialogView}
                onHide={() => SetMessageDialogView(false)}
                attributes={{
                    title: constants.SORRY,
                    close: {},
                    content: constants.NO_RECOVERY_KEY_MESSAGE,
                }}
            />
        </>
    );
}
