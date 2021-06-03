import React, { useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { KeyAttributes } from 'types';
import { SESSION_KEYS, getKey } from 'utils/storage/sessionStorage';
import CryptoWorker, {
    generateAndSaveIntermediateKeyAttributes,
    setSessionKeys,
} from 'utils/crypto';
import { logoutUser } from 'services/userService';
import { isFirstLogin } from 'utils/storage';
import SingleInputForm from 'components/SingleInputForm';
import Container from 'components/Container';
import { Button, Card } from 'react-bootstrap';

export default function Credentials() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!user?.token || !keyAttributes?.memLimit) {
            clearData();
        } else if (!keyAttributes) {
            router.push('/generate');
        } else if (key) {
            router.push('/gallery');
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, []);

    const verifyPassphrase = async (passphrase, setFieldError) => {
        try {
            const cryptoWorker = await new CryptoWorker();
            const kek: string = await cryptoWorker.deriveKey(
                passphrase,
                keyAttributes.kekSalt,
                keyAttributes.opsLimit,
                keyAttributes.memLimit,
            );

            try {
                const key: string = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek,
                );
                if (isFirstLogin()) {
                    await generateAndSaveIntermediateKeyAttributes(
                        passphrase,
                        keyAttributes,
                        key,
                    );
                }
                setSessionKeys(key);
                router.push('/gallery');
            } catch (e) {
                console.error(e);
                setFieldError('passphrase', constants.INCORRECT_PASSPHRASE);
            }
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`,
            );
        }
    };

    return (
        <>
            <Container>
                <Card
                    style={{ minWidth: '320px', padding: '40px 30px' }}
                    className="text-center"
                >
                    <Card.Body>
                        <Card.Title style={{ marginBottom: '24px' }}>
                            {constants.ENTER_PASSPHRASE}
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
                            }}
                        >
                            <Button
                                variant="link"
                                onClick={() => router.push('/recover')}
                            >
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
