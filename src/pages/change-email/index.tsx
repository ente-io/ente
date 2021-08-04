import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import { Formik, FormikHelpers } from 'formik';
import React, { useEffect, useRef, useState } from 'react';
import { Alert, Button, Card, Col, Form, FormControl, Row } from 'react-bootstrap';
import * as Yup from 'yup';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import router from 'next/router';
import { changeEmail, getOTTForEmailChange } from 'services/userService';

interface formValues {
    email: string;
    ott?:string;
}

function ChangeEmailForm() {
    const [loading, setLoading]=useState(false);
    const [showOttInput, setShowOttInput]=useState(false);

    const emailInputElement = useRef(null);
    const ottInputRef=useRef(null);

    useEffect(() => {
        setTimeout(() => {
            emailInputElement.current?.focus();
        }, 250);
    }, []);

    const requestOTT= async( { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await getOTTForEmailChange(email);
            setShowOttInput(true);
            setTimeout(() => {
                ottInputRef.current?.focus();
            }, 250);
        } catch (e) {
            setFieldError('email', `${constants.EMAIl_ALREADY_OWNED}`);
        }
        setLoading(false);
    };


    const requestEmailChange= async( { email, ott }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await changeEmail(email, ott);
            router.push('/gallery');
        } catch (e) {
            setFieldError('ott', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    };
    return (
        <Container>
            <Card style={{ minWidth: '420px', padding: '10px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src="/icon.svg" />
                        {constants.UPDATE_EMAIL}
                    </Card.Title>
                    {showOttInput &&<Alert
                        variant="success"
                        style={{
                            textAlign: 'center',
                            height: '2rem',
                            padding: 0,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                        }}
                    >
                        ott sent !!!
                    </Alert>}
                    <Formik<formValues>
                        initialValues={{ email: '' }}
                        validationSchema={Yup.object().shape({
                            email: Yup.string()
                                .email(constants.EMAIL_ERROR)
                                .required(constants.REQUIRED),
                        })}
                        validateOnChange={false}
                        validateOnBlur={false}
                        onSubmit={!showOttInput?requestOTT:requestEmailChange}
                    >
                        {({
                            values,
                            errors,
                            touched,
                            handleChange,
                            handleSubmit,
                        }) => (
                            <Form noValidate onSubmit={handleSubmit}>
                                {!showOttInput ?
                                    <Form.Group controlId="formBasicEmail">
                                        <Form.Control
                                            ref={emailInputElement}
                                            type="email"
                                            placeholder={constants.ENTER_EMAIL}
                                            value={values.email}
                                            onChange={handleChange('email')}
                                            isInvalid={Boolean(
                                                touched.email && errors.email,
                                            )}
                                            autoFocus
                                            disabled={loading || showOttInput}
                                        />
                                        <FormControl.Feedback type="invalid">
                                            {errors.email}
                                        </FormControl.Feedback>
                                    </Form.Group> :
                                    <>
                                        <Row>
                                            <Col xs="8">
                                                <div style={{ marginBottom: '10px' }}>
                                                    {values.email}
                                                </div>
                                            </Col>
                                            <Col xs ="4">
                                                <div onClick={()=>setShowOttInput(false)}>
                                                    change
                                                </div>
                                            </Col>
                                        </Row>
                                        <Form.Group controlId="formBasicEmail">
                                            <Form.Control
                                                ref={ottInputRef}
                                                type="email"
                                                placeholder={constants.ENTER_OTT}
                                                value={values.ott}
                                                onChange={handleChange('ott')}
                                                isInvalid={Boolean(
                                                    touched.ott && errors.ott,
                                                )}
                                                autoFocus
                                                disabled={loading}
                                            />
                                            <FormControl.Feedback type="invalid">
                                                {errors.ott}
                                            </FormControl.Feedback>
                                        </Form.Group>
                                    </>}
                                <SubmitButton
                                    buttonText={!showOttInput?constants.SEND_OTT:constants.VERIFY}
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

export default ChangeEmailForm;
