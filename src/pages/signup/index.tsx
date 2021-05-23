import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { getOtt } from 'services/userService';
import Container from 'components/Container';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import SubmitButton from 'components/SubmitButton';
import { Button } from 'react-bootstrap';
import { generateKeyAttributes } from 'utils/crypto';

interface FormValues {
    email: string;
    passphrase: string;
    confirm: string;
}

export default function SignUp() {
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    useEffect(() => {
        router.prefetch('/verify');
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push('/verify');
        }
    }, []);

    const registerUser = async (
        { email, passphrase, confirm }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
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
                const keyAttributes = await generateKeyAttributes(passphrase);
                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
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

    return (
        <Container>
            <Card style={{ minWidth: '400px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px' }}>
                    <Card.Title style={{ marginBottom: '20px' }}>
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
                                constants.REQUIRED
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
                                            touched.email && errors.email
                                        )}
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
                                            constants.RE_ENTER_PASSPHRASE
                                        }
                                        value={values.confirm}
                                        onChange={handleChange('confirm')}
                                        isInvalid={Boolean(
                                            touched.confirm && errors.confirm
                                        )}
                                        disabled={loading}
                                    />
                                    <Form.Control.Feedback type="invalid">
                                        {errors.confirm}
                                    </Form.Control.Feedback>
                                </Form.Group>

                                <SubmitButton
                                    buttonText={constants.SUBMIT}
                                    loading={loading}
                                />
                            </Form>
                        )}
                    </Formik>
                    <br />
                    <Button variant="link" onClick={router.back}>
                        {constants.GO_BACK}
                    </Button>
                </Card.Body>
            </Card>
        </Container>
    );
}
