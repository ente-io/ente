
import { Formik, FormikHelpers } from 'formik';
import React, { useContext, useEffect, useRef, useState } from 'react';
import { Button, Col, Form, FormControl } from 'react-bootstrap';
import * as Yup from 'yup';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import router from 'next/router';
import { changeEmail, getOTTForEmailChange } from 'services/userService';
import styled from 'styled-components';
import { AppContext } from 'pages/_app';
import englishConstants from 'utils/strings/englishConstants';

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

interface Props{
showMessage:(value:boolean)=>void;
setEmail:(email:string)=>void;
}
function ChangeEmailForm(props:Props) {
    const [loading, setLoading]=useState(false);
    const [ottInputVisible, setShowOttInputVisibility]=useState(false);
    const emailInputElement = useRef(null);
    const ottInputRef=useRef(null);
    const appContext = useContext(AppContext);

    useEffect(() => {
        setTimeout(() => {
            emailInputElement.current?.focus();
        }, 250);
    }, []);

    useEffect(()=>{
        if (!ottInputVisible) {
            props.showMessage(false);
        }
    }, [ottInputVisible]);

    const requestOTT= async( { email }: formValues,
        { setFieldError }: FormikHelpers<formValues>)=>{
        try {
            setLoading(true);
            await getOTTForEmailChange(email);
            props.setEmail(email);
            setShowOttInputVisibility(true);
            props.showMessage(true);
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
            appContext.setDisappearingFlashMessage({ message: constants.EMAIL_UDPATE_SUCCESSFUL, severity: 'success' });
            router.push('/gallery');
        } catch (e) {
            setFieldError('ott', `${constants.INCORRECT_CODE}`);
        }
        setLoading(false);
    };

    return (
        <Formik<formValues>
            initialValues={{ email: '' }}
            validationSchema={Yup.object().shape({
                email: Yup.string()
                    .email(constants.EMAIL_ERROR)
                    .required(constants.REQUIRED),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={!ottInputVisible?requestOTT:requestEmailChange}
        >
            {({
                values,
                errors,
                touched,
                handleChange,
                handleSubmit,
            }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    {!ottInputVisible ?
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
                                        {englishConstants.CHANGE}
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
                        buttonText={!ottInputVisible?constants.SEND_OTT:constants.VERIFY}
                        loading={loading}
                    />
                    <br />
                    <Button block variant="link" className="text-center" onClick={router.back}>
                        {constants.GO_BACK}
                    </Button>
                </Form>
            )}
        </Formik>
    );
}

export default ChangeEmailForm;
