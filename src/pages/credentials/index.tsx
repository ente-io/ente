import React, { useEffect, useState } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import * as Yup from 'yup';
import { KeyAttributes } from 'types';
import { setKey, SESSION_KEYS, getKey } from 'utils/storage/sessionStorage';
import CryptoWorker from 'utils/crypto';
import { logoutUser } from 'services/userService';
import { isFirstLogin } from 'utils/common';
import { generateIntermediateKeyAttributes } from 'utils/crypto';

const Image = styled.img`
    width: 200px;
    margin-bottom: 20px;
    max-width: 100%;
`;

interface formValues {
    passphrase: string;
}

export default function Credentials() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!user?.token) {
            router.push('/');
        } else if (!keyAttributes) {
            router.push('/generate');
        } else if (key) {
            router.push('/gallery');
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, []);

    const verifyPassphrase = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        setLoading(true);
        try {
            const cryptoWorker = await new CryptoWorker();
            const { passphrase } = values;
            const kek: string = await cryptoWorker.deriveKey(
                passphrase,
                keyAttributes.kekSalt,
                keyAttributes.opsLimit,
                keyAttributes.memLimit
            );

            try {
                const key: string = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                if (isFirstLogin()) {
                    const intermediateKeyAttributes = await generateIntermediateKeyAttributes(
                        passphrase,
                        keyAttributes,
                        key
                    );
                    setData(LS_KEYS.KEY_ATTRIBUTES, intermediateKeyAttributes);
                }
                const sessionKeyAttributes = await cryptoWorker.encryptToB64(
                    key
                );
                const sessionKey = sessionKeyAttributes.key;
                const sessionNonce = sessionKeyAttributes.nonce;
                const encryptionKey = sessionKeyAttributes.encryptedData;
                setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
                setData(LS_KEYS.SESSION, { sessionKey, sessionNonce });
                router.push('/gallery');
            } catch (e) {
                console.error(e);
                setFieldError('passphrase', constants.INCORRECT_PASSPHRASE);
            }
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`
            );
        }
        setLoading(false);
    };

    return (
        <Container>
            {/* <Image alt="vault" src="/vault.png" /> */}
            <Card
                style={{ minWidth: '320px', padding: '40px 30px' }}
                className="text-center"
            >
                <Card.Body>
                    <Card.Title style={{ marginBottom: '24px' }}>
                        {constants.ENTER_PASSPHRASE}
                    </Card.Title>
                    <Formik<formValues>
                        initialValues={{ passphrase: '' }}
                        onSubmit={verifyPassphrase}
                        validationSchema={Yup.object().shape({
                            passphrase: Yup.string().required(
                                constants.REQUIRED
                            ),
                        })}
                    >
                        {({
                            values,
                            touched,
                            errors,
                            handleChange,
                            handleBlur,
                            handleSubmit,
                        }) => (
                            <Form noValidate onSubmit={handleSubmit}>
                                <Form.Group>
                                    <Form.Control
                                        type="password"
                                        placeholder={
                                            constants.RETURN_PASSPHRASE_HINT
                                        }
                                        value={values.passphrase}
                                        onChange={handleChange('passphrase')}
                                        onBlur={handleBlur('passphrase')}
                                        isInvalid={Boolean(
                                            touched.passphrase &&
                                                errors.passphrase
                                        )}
                                        disabled={loading}
                                        autoFocus={true}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.passphrase}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <Button block type="submit" disabled={loading}>
                                    {constants.VERIFY_PASSPHRASE}
                                </Button>
                                <br />
                                <div>
                                    <a href="#" onClick={logoutUser}>
                                        {constants.LOGOUT}
                                    </a>
                                </div>
                            </Form>
                        )}
                    </Formik>
                </Card.Body>
            </Card>
        </Container>
    );
}
