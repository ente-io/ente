/* eslint-disable @typescript-eslint/no-unused-vars */
import { Formik, FormikHelpers } from 'formik';
import router from 'next/router';
import { DeadCenter } from 'pages/gallery';
import React, { useRef, useState } from 'react';
import { Form, FormControl } from 'react-bootstrap';
import OtpInput from 'react-otp-input';
import constants from 'utils/strings/constants';
import SubmitButton from './SubmitButton';

interface formValues {
    otp: string;
}
interface Props {
    onSubmit: any
    back: any
    buttonText: string;
}

export default function VerifyTwoFactor(props: Props) {
    const [waiting, setWaiting] = useState(false);
    const otpInputRef = useRef(null);
    const submitForm = async (
        { otp }: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>,
    ) => {
        try {
            setWaiting(true);
            await props.onSubmit(otp);
        } catch (e) {
            resetForm();
            for (let i = 0; i < 6; i++) {
                otpInputRef.current?.focusPrevInput();
            }
            setFieldError('otp', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setWaiting(false);
    };

    const onChange = (otp: string, callback: Function, triggerSubmit: Function) => {
        callback(otp);
        if (otp.length === 6) {
            triggerSubmit(otp);
        }
    };
    return (
        <>
            <p style={{ marginBottom: '30px' }}>enter the 6-digit code from your authenticator app.</p>
            <Formik<formValues>
                initialValues={{ otp: '' }}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={submitForm}
            >
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                    submitForm,
                }) => (
                    <Form noValidate onSubmit={handleSubmit} style={{ width: '100%' }}>
                        <Form.Group style={{ marginBottom: '32px' }} controlId="formBasicEmail">
                            <DeadCenter>
                                <OtpInput
                                    ref={otpInputRef}
                                    value={values.otp}
                                    onChange={(otp) => {
                                        onChange(otp, handleChange('otp'), submitForm);
                                    }}
                                    numInputs={6}
                                    separator={'-'}
                                    isInputNum
                                    className={'otp-input'}
                                />
                                {errors.otp &&
                                    <div style={{ display: 'block', marginTop: '16px' }} className="invalid-feedback">{constants.INCORRECT_CODE}</div>
                                }
                            </DeadCenter>
                        </Form.Group>
                        <SubmitButton
                            buttonText={props.buttonText}
                            loading={waiting}
                            disabled={values.otp.length < 6}
                        />
                    </Form>
                )}
            </Formik>


        </>
    );
}


