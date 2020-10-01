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
import { keyAttributes } from 'types';
import { setKey, SESSION_KEYS, getKey } from 'utils/storage/sessionStorage';
import * as libsodium from 'utils/crypto/libsodium';

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
    const [keyAttributes, setKeyAttributes] = useState<keyAttributes>();
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
            router.push('/gallery')
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, []);

    const verifyPassphrase = async (values: formValues, { setFieldError }: FormikHelpers<formValues>) => {
        setLoading(true);
        try {
            const { passphrase } = values;
            const kek = await libsodium.deriveKey(await libsodium.fromString(passphrase),
                await libsodium.fromB64(keyAttributes.kekSalt));

            if (await libsodium.verifyHash(keyAttributes.kekHash, kek)) {
                const key = await libsodium.decrypt(
                    await libsodium.fromB64(keyAttributes.encryptedKey),
                    await libsodium.fromB64(keyAttributes.keyDecryptionNonce),
                    kek);
                const sessionKeyAttributes = await libsodium.encrypt(key);
                const sessionKey = await libsodium.toB64(sessionKeyAttributes.key);
                const sessionNonce = await libsodium.toB64(sessionKeyAttributes.nonce);
                const encryptionKey = await libsodium.toB64(sessionKeyAttributes.encryptedData);
                setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
                setData(LS_KEYS.SESSION, { sessionKey, sessionNonce });
                router.push('/gallery');
            } else {
                setFieldError('passphrase', constants.INCORRECT_PASSPHRASE);
            }
        } catch (e) {
            setFieldError('passphrase', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    }

    return (<Container>
        <Image alt='vault' src='/vault.svg' />
        <Card style={{ minWidth: '300px' }}>
            <Card.Body>
                <p className="text-center">{constants.ENTER_PASSPHRASE}</p>
                <Formik<formValues>
                    initialValues={{ passphrase: '' }}
                    onSubmit={verifyPassphrase}
                    validationSchema={Yup.object().shape({
                        passphrase: Yup.string().required(constants.REQUIRED),
                    })}
                >
                    {({ values, touched, errors, handleChange, handleBlur, handleSubmit }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Group>
                                <Form.Control
                                    type="password"
                                    placeholder={constants.RETURN_PASSPHRASE_HINT}
                                    value={values.passphrase}
                                    onChange={handleChange('passphrase')}
                                    onBlur={handleBlur('passphrase')}
                                    isInvalid={Boolean(touched.passphrase && errors.passphrase)}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type="invalid">
                                    {errors.passphrase}
                                </Form.Control.Feedback>
                            </Form.Group>
                            <Button block type='submit' disabled={loading}>{constants.VERIFY_PASSPHRASE}</Button>
                        </Form>
                    )}
                </Formik>
            </Card.Body>
        </Card>
    </Container>)
}
