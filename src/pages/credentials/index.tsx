import React, { useContext, useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { KeyAttributes } from 'types';
import { SESSION_KEYS, getKey } from 'utils/storage/sessionStorage';
import CryptoWorker, {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    SaveKeyInSessionStore,
} from 'utils/crypto';
import { logoutUser } from 'services/userService';
import { isFirstLogin } from 'utils/storage';
import SingleInputForm from 'components/SingleInputForm';
import Container from 'components/Container';
import { Button, Card } from 'react-bootstrap';
import { AppContext } from 'pages/_app';
import LogoImg from 'components/LogoImg';
import { logError } from 'utils/sentry';

export default function Credentials() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const appContext = useContext(AppContext);

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (
            (!user?.token && !user?.encryptedToken) ||
            !keyAttributes?.memLimit
        ) {
            clearData();
            router.push('/');
        } else if (!keyAttributes) {
            router.push('/generate');
        } else if (key) {
            router.push('/gallery');
        } else {
            setKeyAttributes(keyAttributes);
        }
        appContext.showNavBar(false);
    }, []);

    const verifyPassphrase = async (passphrase, setFieldError) => {
        try {
            const cryptoWorker = await new CryptoWorker();
            let kek: string = null;
            try {
                kek = await cryptoWorker.deriveKey(
                    passphrase,
                    keyAttributes.kekSalt,
                    keyAttributes.opsLimit,
                    keyAttributes.memLimit
                );
            } catch (e) {
                console.error('failed to deriveKey ', e.message);
                throw e;
            }
            try {
                const key: string = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                if (isFirstLogin()) {
                    await generateAndSaveIntermediateKeyAttributes(
                        passphrase,
                        keyAttributes,
                        key
                    );
                }
                await SaveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
                await decryptAndStoreToken(key);

                router.push('/gallery');
            } catch (e) {
                logError(e);
                setFieldError('passphrase', constants.INCORRECT_PASSPHRASE);
            }
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`
            );
            console.error('failed to verifyPassphrase ', e.message);
        }
    };

    return (
        <>
            <Container>
                <Card style={{ minWidth: '320px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src="/icon.svg" />
                            {constants.PASSWORD}
                        </Card.Title>
                        <SingleInputForm
                            callback={verifyPassphrase}
                            placeholder={constants.RETURN_PASSPHRASE_HINT}
                            buttonText={constants.VERIFY_PASSPHRASE}
                            fieldType="password"
                        />
                        <div
                            style={{
                                display: 'flex',
                                flexDirection: 'column',
                                marginTop: '12px',
                            }}>
                            <Button
                                variant="link"
                                onClick={() => router.push('/recover')}>
                                {constants.FORGOT_PASSWORD}
                            </Button>
                            <Button variant="link" onClick={logoutUser}>
                                {constants.GO_BACK}
                            </Button>
                        </div>
                    </Card.Body>
                </Card>
            </Container>
        </>
    );
}
