import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import FormControl from 'react-bootstrap/FormControl';
import Button from 'react-bootstrap/Button';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { getOtt } from 'services/userService';
import Container from 'components/Container';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { DisclaimerContainer } from 'components/Container';

interface FormValues {
    name: string;
    email: string;
}

export default function Home() {
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
        { name, email }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            setLoading(true);
            setData(LS_KEYS.USER, { name, email });
            await getOtt(email);
            router.push('/verify');
        } catch (e) {
            setFieldError('email', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    };

    return (
        <Container>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body>
                    <Card.Title style={{ marginBottom: '20px' }}>
                        {constants.SIGN_UP}
                    </Card.Title>
                    <Formik<FormValues>
                        initialValues={{ name: '', email: '' }}
                        validationSchema={Yup.object().shape({
                            name: Yup.string().required(constants.REQUIRED),
                            email: Yup.string()
                                .email(constants.EMAIL_ERROR)
                                .required(constants.REQUIRED),
                        })}
                        onSubmit={registerUser}
                    >
                        {({
                            values,
                            errors,
                            touched,
                            handleChange,
                            handleBlur,
                            handleSubmit,
                        }): JSX.Element => (
                            <Form noValidate onSubmit={handleSubmit}>
                                <Form.Group controlId="registrationForm.name">
                                    <Form.Control
                                        type="text"
                                        placeholder={constants.ENTER_NAME}
                                        value={values.name}
                                        onChange={handleChange('name')}
                                        onBlur={handleBlur('name')}
                                        isInvalid={Boolean(
                                            touched.name && errors.name
                                        )}
                                        disabled={loading}
                                    />
                                    <FormControl.Feedback type="invalid">
                                        {errors.name}
                                    </FormControl.Feedback>
                                </Form.Group>
                                <Form.Group controlId="registrationForm.email">
                                    <Form.Control
                                        type="email"
                                        placeholder={constants.ENTER_EMAIL}
                                        value={values.email}
                                        onChange={handleChange('email')}
                                        onBlur={handleBlur('email')}
                                        isInvalid={Boolean(
                                            touched.email && errors.email
                                        )}
                                        disabled={loading}
                                    />
                                    <FormControl.Feedback type="invalid">
                                        {errors.email}
                                    </FormControl.Feedback>
                                </Form.Group>
                                <DisclaimerContainer>
                                    {constants.DATA_DISCLAIMER}
                                </DisclaimerContainer>
                                <Button
                                    variant="success"
                                    type="submit"
                                    block
                                    disabled={loading}
                                >
                                    {constants.SUBMIT}
                                </Button>
                            </Form>
                        )}
                    </Formik>
                </Card.Body>
            </Card>
        </Container>
    );
}
