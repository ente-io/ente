import React, { useState, useEffect, useContext } from 'react';
import Container from 'components/Container';
import styled from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import Button from 'react-bootstrap/Button';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { B64EncryptionResult } from 'services/uploadService';
import CryptoWorker from 'utils/crypto';
import { generateIntermediateKeyAttributes } from 'utils/crypto';
import { Spinner } from 'react-bootstrap';
import { getActualKey } from 'utils/common/key';
import { setKeys, UpdatedKey } from 'services/userService';

const Image = styled.img`
    width: 200px;
    margin-bottom: 20px;
    max-width: 100%;
`;

interface formValues {
    passphrase: string;
    confirm: string;
}

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [loading, setLoading] = useState(false);
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push('/');
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                const cryptoWorker = await new CryptoWorker();
                const key: string = await getActualKey();
                const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
                const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
                let kek: KEK;
                try {
                    kek = await cryptoWorker.deriveSensitiveKey(
                        passphrase,
                        kekSalt
                    );
                } catch (e) {
                    setFieldError(
                        'confirm',
                        constants.PASSWORD_GENERATION_FAILED
                    );
                    return;
                }
                const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
                    key,
                    kek.key
                );
                const updatedKey: UpdatedKey = {
                    kekSalt,
                    encryptedKey: encryptedKeyAttributes.encryptedData,
                    keyDecryptionNonce: encryptedKeyAttributes.nonce,
                    opsLimit: kek.opsLimit,
                    memLimit: kek.memLimit,
                };

                await setKeys(token, updatedKey);

                const updatedKeyAttributes = Object.assign(
                    keyAttributes,
                    updatedKey
                );
                setData(
                    LS_KEYS.KEY_ATTRIBUTES,
                    await generateIntermediateKeyAttributes(
                        passphrase,
                        updatedKeyAttributes,
                        key
                    )
                );

                const sessionKeyAttributes = await cryptoWorker.encryptToB64(
                    key
                );
                const sessionKey = sessionKeyAttributes.key;
                const sessionNonce = sessionKeyAttributes.nonce;
                const encryptionKey = sessionKeyAttributes.encryptedData;
                setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
                setData(LS_KEYS.SESSION, { sessionKey, sessionNonce });
                router.push('/gallery');
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            setFieldError(
                'passphrase',
                `${constants.UNKNOWN_ERROR} ${e.message}`
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <Container>
            {/* <Image alt="vault" src="/vault.png" style={{ paddingBottom: '40px' }} /> */}
            <Card style={{ maxWidth: '540px', padding: '20px' }}>
                <Card.Body>
                    <div
                        className="text-center"
                        style={{ marginBottom: '40px' }}
                    >
                        <p>{constants.ENTER_ENC_PASSPHRASE}</p>
                        {constants.PASSPHRASE_DISCLAIMER()}
                    </div>
                    <Formik<formValues>
                        initialValues={{ passphrase: '', confirm: '' }}
                        validationSchema={Yup.object().shape({
                            passphrase: Yup.string().required(
                                constants.REQUIRED
                            ),
                            confirm: Yup.string().required(constants.REQUIRED),
                        })}
                        onSubmit={onSubmit}
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
                                        placeholder={constants.PASSPHRASE_HINT}
                                        value={values.passphrase}
                                        onChange={handleChange('passphrase')}
                                        onBlur={handleBlur('passphrase')}
                                        isInvalid={Boolean(
                                            touched.passphrase &&
                                                errors.passphrase
                                        )}
                                        autoFocus={true}
                                        disabled={loading}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.passphrase}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <Form.Group>
                                    <Form.Control
                                        type="password"
                                        placeholder={
                                            constants.PASSPHRASE_CONFIRM
                                        }
                                        value={values.confirm}
                                        onChange={handleChange('confirm')}
                                        onBlur={handleBlur('confirm')}
                                        isInvalid={Boolean(
                                            touched.confirm && errors.confirm
                                        )}
                                        disabled={loading}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.confirm}
                                    </Form.Control.Feedback>
                                </Form.Group>
                                <Button
                                    type="submit"
                                    block
                                    disabled={loading}
                                    style={{ marginTop: '28px' }}
                                >
                                    {loading ? (
                                        <Spinner animation="border" />
                                    ) : (
                                        constants.SET_PASSPHRASE
                                    )}
                                </Button>
                            </Form>
                        )}
                    </Formik>
                    <div className="text-center" style={{ marginTop: '20px' }}>
                        <Button variant="link" onClick={() => router.push('/')}>
                            {constants.LOGOUT}
                        </Button>
                    </div>
                </Card.Body>
            </Card>
        </Container>
    );
}
