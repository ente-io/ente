import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import { Formik, FormikHelpers } from 'formik';
import React, { useEffect, useRef, useState } from 'react';
import { Button, Card, Form, FormControl } from 'react-bootstrap';
import * as Yup from 'yup';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import router from 'next/router';
import { getOTTForEmailChange } from 'services/userService';

interface formValues {
    email: string;
}

function ChangeEmail() {
    const [loading, setLoading]=useState(false);

    const requestOTT= async( { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await getOTTForEmailChange(email);
        } catch (e) {
            setFieldError('email', `${constants.EMAIl_ALREADY_OWNED}`);
        }
        setLoading(false);
    };

    const inputElement = useRef(null);
    useEffect(() => {
        setTimeout(() => {
            inputElement.current?.focus();
        }, 250);
    }, []);

    return (
        <Container>
            <Card style={{ minWidth: '320px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src="/icon.svg" />
                        {constants.UPDATE_EMAIL}
                    </Card.Title>
                    <Formik<formValues>
                        initialValues={{ email: '' }}
                        validationSchema={Yup.object().shape({
                            email: Yup.string()
                                .email(constants.EMAIL_ERROR)
                                .required(constants.REQUIRED),
                        })}
                        validateOnChange={false}
                        validateOnBlur={false}
                        onSubmit={requestOTT}
                    >
                        {({
                            values,
                            errors,
                            touched,
                            handleChange,
                            handleSubmit,
                        }) => (
                            <Form noValidate onSubmit={handleSubmit}>
                                <Form.Group controlId="formBasicEmail">
                                    <Form.Control
                                        ref={inputElement}
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
                                <SubmitButton
                                    buttonText={constants.SEND_OTT}
                                    loading={loading}
                                />
                                <br />
                                <Button block variant="link" className="text-center" onClick={router.back}>
                                    {constants.GO_BACK}
                                </Button>
                            </Form>
                        )}
                    </Formik>
                </Card.Body>
            </Card>
        </Container>);
}

export default ChangeEmail;
