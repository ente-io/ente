import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { KeyAttributes } from 'types';
import CryptoWorker, { setSessionKeys } from 'utils/crypto';
import SingleInputForm from 'components/SingleInputForm';
import MessageDialog from 'components/MessageDialog';
import Container from 'components/Container';
import { Card, Button } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import LogoImg from 'components/LogoImg';

export default function Recover() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [messageDialogView, SetMessageDialogView] = useState(false);
    const appContext = useContext(AppContext);

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        if (!user?.token) {
            router.push('/');
        } else if (!keyAttributes) {
            router.push('/generate');
        } else {
            setKeyAttributes(keyAttributes);
        }
        appContext.showNavBar(false);
    }, []);

    const recover = async (recoveryKey: string, setFieldError) => {
        try {
            const cryptoWorker = await new CryptoWorker();
            const masterKey: string = await cryptoWorker.decryptB64(
                keyAttributes.masterKeyEncryptedWithRecoveryKey,
                keyAttributes.masterKeyDecryptionNonce,
                await cryptoWorker.fromHex(recoveryKey),
            );
            setSessionKeys(masterKey);
            router.push('/changePassword');
        } catch (e) {
            console.error(e);
            setFieldError('passphrase', constants.INCORRECT_RECOVERY_KEY);
        }
    };

    return (
        <>
            <Container>
                <Card
                    style={{ minWidth: '320px' }}
                    className="text-center"
                >
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src='/icon.svg' />
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
                            }}
                        >
                            <Button
                                variant="link"
                                onClick={() => SetMessageDialogView(true)}
                            >
                                {constants.NO_RECOVERY_KEY}
                            </Button>
                            <Button variant="link" onClick={router.back}>
                                {constants.GO_BACK}
                            </Button>
                        </div>
                    </Card.Body>
                </Card>
            </Container>
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
