import React, { useState, useEffect, useContext } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Button from 'react-bootstrap/Button';
import { putAttributes } from 'services/userService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import * as Comlink from "comlink";

const CryptoWorker: any = typeof window !== 'undefined'
    && Comlink.wrap(new Worker("worker/crypto.worker.js", { type: 'module' }));

const Image = styled.img`
    width: 200px;
    margin-bottom: 20px;
    max-width: 100%;
`;

interface formValues {
    passphrase: string;
    confirm: string;
}

export default function Generate() {
    const [loading, setLoading] = useState(false);
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push("/");
        } else if (key) {
            router.push('/gallery');
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit = async (values: formValues, { setFieldError }: FormikHelpers<formValues>) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                const cryptoWorker = await new CryptoWorker();
                const key = await cryptoWorker.generateMasterKey();
                const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
                const kek = await cryptoWorker.deriveKey(
                    await cryptoWorker.fromString(passphrase), kekSalt);
                const kekHash = await cryptoWorker.hash(kek);
                const encryptedKeyAttributes = await cryptoWorker.encrypt(key, kek);
                const keyPair = await cryptoWorker.generateKeyPair();
                const encryptedKeyPairAttributes = await cryptoWorker.encrypt(keyPair.privateKey, key);
                const keyAttributes = {
                    kekSalt: await cryptoWorker.toB64(kekSalt),
                    kekHash: kekHash,
                    encryptedKey: await cryptoWorker.toB64(encryptedKeyAttributes.encryptedData),
                    keyDecryptionNonce: await cryptoWorker.toB64(encryptedKeyAttributes.nonce),
                    publicKey: await cryptoWorker.toB64(keyPair.publicKey),
                    encryptedSecretKey: await cryptoWorker.toB64(encryptedKeyPairAttributes.encryptedData),
                    secretKeyDecryptionNonce: await cryptoWorker.toB64(encryptedKeyPairAttributes.nonce)
                };
                await putAttributes(token, getData(LS_KEYS.USER).name, keyAttributes);
                setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);

                const sessionKeyAttributes = await cryptoWorker.encrypt(key);
                const sessionKey = await cryptoWorker.toB64(sessionKeyAttributes.key);
                const sessionNonce = await cryptoWorker.toB64(sessionKeyAttributes.nonce);
                const encryptionKey = await cryptoWorker.toB64(sessionKeyAttributes.encryptedData);
                setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
                setData(LS_KEYS.SESSION, { sessionKey, sessionNonce });
                router.push('/gallery');
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            setFieldError('passphrase', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    }

    return (<Container>
        <Image alt='vault' src='/vault.svg' />
        <Card>
            <Card.Body>
                <div className="text-center">
                    <p>{constants.ENTER_ENC_PASSPHRASE}</p>
                    <p>{constants.PASSPHRASE_DISCLAIMER()}</p>
                </div>
                <Formik<formValues>
                    initialValues={{ passphrase: '', confirm: '' }}
                    validationSchema={Yup.object().shape({
                        passphrase: Yup.string().required(constants.REQUIRED),
                        confirm: Yup.string().required(constants.REQUIRED),
                    })}
                    onSubmit={onSubmit}
                >
                    {({ values, touched, errors, handleChange, handleBlur, handleSubmit }) => (
                        <Form noValidate onSubmit={handleSubmit}>
                            <Form.Group>
                                <Form.Control
                                    type="text"
                                    placeholder={constants.PASSPHRASE_HINT}
                                    value={values.passphrase}
                                    onChange={handleChange('passphrase')}
                                    onBlur={handleBlur('passphrase')}
                                    isInvalid={Boolean(touched.passphrase && errors.passphrase)}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type='invalid'>
                                    {errors.passphrase}
                                </Form.Control.Feedback>
                            </Form.Group>
                            <Form.Group>
                                <Form.Control
                                    type="text"
                                    placeholder={constants.PASSPHRASE_CONFIRM}
                                    value={values.confirm}
                                    onChange={handleChange('confirm')}
                                    onBlur={handleBlur('confirm')}
                                    isInvalid={Boolean(touched.confirm && errors.confirm)}
                                    disabled={loading}
                                />
                                <Form.Control.Feedback type='invalid'>
                                    {errors.confirm}
                                </Form.Control.Feedback>
                            </Form.Group>
                            <Button type="submit" block disabled={loading}>{constants.SET_PASSPHRASE}</Button>
                        </Form>
                    )}
                </Formik>
            </Card.Body>
        </Card>
    </Container>)
}
