import React, { useState } from 'react';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { getOtt } from 'services/userService';
import Card from 'react-bootstrap/Card';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import SubmitButton from 'components/SubmitButton';
import { Button } from 'react-bootstrap';
import {
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAttributes,
    setSessionKeys,
} from 'utils/crypto';
import { setJustSignedUp } from 'utils/storage';
import styled from 'styled-components';

interface FormValues {
    email: string;
    passphrase: string;
    confirm: string;
}

interface SignUpProps {
    login: () => void;
}

const Img = styled.img`
    height: 25px;
    vertical-align: bottom;
    padding-right: 15px;
    border-right: 2px solid #aaa;
    margin-right: 15px;
`;

export default function SignUp(props: SignUpProps) {
    const router = useRouter();
    const [acceptTerms, setAcceptTerms] = useState(false);
    const [loading, setLoading] = useState(false);

    const registerUser = async (
        { email, passphrase, confirm }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>,
    ) => {
        setLoading(true);
        try {
            setData(LS_KEYS.USER, { email });
            await getOtt(email);
        } catch (e) {
            setFieldError('email', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        try {
            if (passphrase === confirm) {
                const { keyAttributes, masterKey } = await generateKeyAttributes(passphrase);
                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
                await generateAndSaveIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    masterKey,
                );

                await setSessionKeys(masterKey);
                setJustSignedUp(true);
                router.push('/verify');
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            console.error(e);
            setFieldError('passphrase', constants.PASSWORD_GENERATION_FAILED);
        }
        setLoading(false);
    };

    return (<>
        <Card.Title style={{ marginBottom: '32px' }}>
            <Img src="/icon.svg" />
            {constants.SIGN_UP}
        </Card.Title>
        <Formik<FormValues>
            initialValues={{
                email: '',
                passphrase: '',
                confirm: '',
            }}
            validationSchema={Yup.object().shape({
                email: Yup.string()
                    .email(constants.EMAIL_ERROR)
                    .required(constants.REQUIRED),
                passphrase: Yup.string().required(
                    constants.REQUIRED,
                ),
                confirm: Yup.string().required(constants.REQUIRED),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={registerUser}
        >
            {({
                values,
                errors,
                touched,
                handleChange,
                handleSubmit,
            }): JSX.Element => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Group controlId="registrationForm.email">
                        <Form.Control
                            type="email"
                            placeholder={constants.ENTER_EMAIL}
                            value={values.email}
                            onChange={handleChange('email')}
                            isInvalid={Boolean(
                                touched.email && errors.email,
                            )}
                            autoFocus
                            disabled={loading}
                        />
                        <FormControl.Feedback type="invalid">
                            {errors.email}
                        </FormControl.Feedback>
                    </Form.Group>
                    <Form.Group>
                        <Form.Control
                            type="password"
                            placeholder={constants.PASSPHRASE_HINT}
                            value={values.passphrase}
                            onChange={handleChange('passphrase')}
                            isInvalid={Boolean(
                                touched.passphrase &&
                                    errors.passphrase,
                            )}
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
                                constants.RE_ENTER_PASSPHRASE
                            }
                            value={values.confirm}
                            onChange={handleChange('confirm')}
                            isInvalid={Boolean(
                                touched.confirm && errors.confirm,
                            )}
                            disabled={loading}
                        />
                        <Form.Control.Feedback type="invalid">
                            {errors.confirm}
                        </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group
                        style={{
                            marginBottom: '0',
                            textAlign: 'left',
                        }}
                        controlId="formBasicCheckbox-1"
                    >
                        <Form.Check
                            checked={acceptTerms}
                            onChange={(e) => setAcceptTerms(e.target.checked)}
                            type="checkbox"
                            label={constants.TERMS_AND_CONDITIONS()}
                        />
                    </Form.Group>
                    <br />
                    <SubmitButton
                        buttonText={constants.SUBMIT}
                        loading={loading}
                        disabled={!acceptTerms}
                    />
                </Form>
            )}
        </Formik>
        <br />
        <Button variant="link" onClick={props.login}>
            {constants.ACCOUNT_EXISTS}
        </Button>
    </>);
}
