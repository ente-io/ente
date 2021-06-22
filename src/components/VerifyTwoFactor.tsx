/* eslint-disable @typescript-eslint/no-unused-vars */
import { Formik, FormikHelpers } from 'formik';
import router from 'next/router';
import { DeadCenter } from 'pages/gallery';
import React, { useState } from 'react';
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

    const submitForm = async (
        { otp }: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>,
    ) => {
        try {
            setWaiting(true);
            await props.onSubmit(otp);
        } catch (e) {
            resetForm();
            setFieldError('otp', `${constants.UNKNOWN_ERROR} ${e.message}`);
        }
        setWaiting(false);
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
                }) => (
                    <Form noValidate onSubmit={handleSubmit} style={{ width: '100%' }}>
                        <Form.Group controlId="formBasicEmail">
                            <DeadCenter>
                                <OtpInput value={values.otp}
                                    onChange={handleChange('otp')}
                                    numInputs={6}
                                    separator={'-'}
                                    isInputNum
                                    className={'otp-input'}
                                />
                                {errors.otp &&
                                    <div style={{ display: 'block' }} className="invalid-feedback">{constants.INCORRECT_CODE}</div>
                                }
                            </DeadCenter>
                        </Form.Group>
                        <SubmitButton
                            buttonText={props.buttonText}
                            loading={waiting}
                            disabled={values.otp.length < 6}
                        />
                        <br />
                    </Form>
                )}
            </Formik>


        </>
    );
}


