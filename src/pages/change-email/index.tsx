import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import { Formik, FormikHelpers } from 'formik';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Alert, Button, Card, Col, Form, FormControl } from 'react-bootstrap';
import * as Yup from 'yup';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import router from 'next/router';
import { changeEmail, getOTTForEmailChange } from 'services/userService';
import styled from 'styled-components';
import { AppContext } from 'pages/_app';
import { getToken } from 'utils/common/key';
import EnteSpinner from 'components/EnteSpinner';

interface formValues {
    email: string;
    ott?:string;
}

const EmailRow =styled.div`
    display: flex;
    flex-wrap: wrap;
    border: 1px solid grey;
    margin-bottom: 19px;
    align-items: center;
    text-align: left;
    color: #fff;
`;

function ChangeEmailForm() {
    const [email, setEmail]=useState('');
    const [loading, setLoading]=useState(false);
    const [waiting, setWaiting]=useState(true);
    const [OttInputVisible, setShowOttInputVisibility]=useState(false);
    const [showMessage, setShwoMessage]=useState(false);
    const emailInputElement = useRef(null);
    const ottInputRef=useRef(null);
    const appContext = useContext(AppContext);
    useEffect(() => {
        setTimeout(() => {
            emailInputElement.current?.focus();
        }, 250);
        const token=getToken();
        if (!token) {
            router.push('/');
            return;
        }
        setWaiting(false);
    }, []);

    const requestOTT= async( { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await getOTTForEmailChange(email);
            setEmail(email);
            setShwoMessage(true);
            setShowOttInputVisibility(true);
            setTimeout(() => {
                ottInputRef.current?.focus();
            }, 250);
        } catch (e) {
            setFieldError('email', `${constants.EMAIl_ALREADY_OWNED}`);
        }
        setLoading(false);
    };


    const requestEmailChange= async( { ott }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await changeEmail(email, ott);
            appContext.setDisappearingFlashMessage({ message: constants.EMAIL_UDPATE_SUCCESSFUL, severity: 'success' });
            router.push('/gallery');
        } catch (e) {
            setFieldError('ott', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setLoading(false);
    };
    return (
        <Container>{waiting ?
            <EnteSpinner>
                <span className="sr-only">Loading...</span>
            </EnteSpinner>:
            <Card style={{ minWidth: '420px', padding: '10px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src="/icon.svg" />
                        {constants.UPDATE_EMAIL}
                    </Card.Title>
                    <Alert
                        variant="success"
                        show={showMessage}
                        style={{ paddingBottom: 0 }}
                        transition
                        dismissible
                        onClose={()=>setShwoMessage(false)}
                    >
                        {constants.EMAIL_SENT({ email })}
                    </Alert>
                    <Formik<formValues>
                        initialValues={{ email: '' }}
                        validationSchema={Yup.object().shape({
                            email: Yup.string()
                                .email(constants.EMAIL_ERROR)
                                .required(constants.REQUIRED),
                        })}
                        validateOnChange={false}
                        validateOnBlur={false}
                        onSubmit={!OttInputVisible?requestOTT:requestEmailChange}
                    >
                        {({
                            values,
                            errors,
                            touched,
                            handleChange,
                            handleSubmit,
                        }) => (
                            <Form noValidate onSubmit={handleSubmit}>
                                {!OttInputVisible ?
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
                                            disabled={loading}
                                        />
                                        <FormControl.Feedback type="invalid">
                                            {errors.email}
                                        </FormControl.Feedback>
                                    </Form.Group> :
                                    <>
                                        <EmailRow>
                                            <Col xs="8">
                                                {values.email}
                                            </Col>
                                            <Col xs ="4" >
                                                <Button variant="link" onClick={()=>setShowOttInputVisibility(false)}>
                                                    change
                                                </Button>
                                            </Col>
                                        </EmailRow>
                                        <Form.Group controlId="formBasicEmail">
                                            <Form.Control
                                                ref={ottInputRef}
                                                type="text"
                                                placeholder={constants.ENTER_OTT}
                                                value={values.ott}
                                                onChange={handleChange('ott')}
                                                isInvalid={Boolean(
                                                    touched.ott && errors.ott,
                                                )}
                                                disabled={loading}
                                            />
                                            <FormControl.Feedback type="invalid">
                                                {errors.ott}
                                            </FormControl.Feedback>
                                        </Form.Group>
                                    </>}

                                <SubmitButton
                                    buttonText={!OttInputVisible?constants.SEND_OTT:constants.VERIFY}
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
        }
        </Container>);
}

export default ChangeEmailForm;
