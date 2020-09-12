import React, { useEffect, useState, useContext } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import { getData, SESSION_KEYS } from 'utils/sessionStorage';
import { useRouter } from 'next/router';
import * as Yup from 'yup';
import { hash } from 'utils/crypto/scrypt';
import { strToUint8, base64ToUint8 } from 'utils/crypto/common';
import { AppContext } from 'pages/_app';
import { decrypt } from 'utils/crypto/aes';
import { keyAttributes } from 'types';

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
    const context = useContext(AppContext);

    useEffect(() => {
        const user = getData(SESSION_KEYS.USER);
        const keyAttributes = getData(SESSION_KEYS.KEY_ATTRIBUTES);
        if (!user?.token) {
            router.push('/');
        } else if (!keyAttributes) {
            router.push('/generate');
        } else if (context.key) {
            router.push('/gallery')
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, []);

    const verifyPassphrase = async (values: formValues, { setFieldError }: FormikHelpers<formValues>) => {
        setLoading(true);
        try {
            const { passphrase } = values;
            const kek = await hash(strToUint8(passphrase), base64ToUint8(keyAttributes.kekSalt));
            const kekHash = await hash(base64ToUint8(kek), base64ToUint8(keyAttributes.kekHashSalt));
    
            if (kekHash === keyAttributes.kekHash) {
                const key = await decrypt(keyAttributes.encryptedKey, kek, keyAttributes.encryptedKeyIV);
                context.setKey(key);
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
        <Image src='/vault.svg' />
        <Card style={{ minWidth: '300px'}}>
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
                            <Button block type='submit' disabled={loading}>{constants.SET_PASSPHRASE}</Button>
                        </Form>
                    )}
                </Formik>
            </Card.Body>
        </Card>
    </Container>)
}
