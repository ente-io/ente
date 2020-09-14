import React, { useState, useEffect, useContext } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Button from 'react-bootstrap/Button';
import { secureRandomString, strToUint8, base64ToUint8, binToBase64 } from 'utils/crypto/common';
import { hash } from 'utils/crypto/scrypt';
import { encrypt } from 'utils/crypto/aes';
import { putKeyAttributes } from 'services/userService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';

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
                const key = secureRandomString(32);
                const kekSalt = secureRandomString(32);
                const kek = await hash(strToUint8(passphrase), base64ToUint8(kekSalt));
                const kekHashSalt = secureRandomString(32);
                const kekHash = await hash(base64ToUint8(kek), base64ToUint8(kekHashSalt));
                const encryptedKeyIV = secureRandomString(16);
                const encryptedKey = await encrypt(key, kek, encryptedKeyIV);
                const keyAttributes = {
                    kekSalt, kekHashSalt, kekHash,
                    encryptedKeyIV, encryptedKey,
                };
                await putKeyAttributes(token, keyAttributes);
                setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
                const sessionKey = secureRandomString(32);
                const sessionIV = secureRandomString(16);
                const encryptionKey = await encrypt(key, sessionKey, sessionIV);
                setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
                setData(LS_KEYS.SESSION, { sessionKey, sessionIV });
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
