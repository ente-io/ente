/* eslint-disable @typescript-eslint/no-unused-vars */
import { Formik, FormikHelpers } from 'formik';
import React, { FC, useRef, useState } from 'react';
import OtpInput from 'react-otp-input';
import constants from 'utils/strings/constants';
import SubmitButton from 'components/SubmitButton';
import VerticallyCentered, { CenteredFlex } from 'components/Container';
import { Box, Typography, TypographyProps } from '@mui/material';
import InvalidInputMessage from './InvalidInputMessage';

interface formValues {
    otp: string;
}
interface Props {
    onSubmit: any;
    buttonText: string;
}

export default function VerifyTwoFactor(props: Props) {
    const [waiting, setWaiting] = useState(false);
    const otpInputRef = useRef(null);
    const submitForm = async (
        { otp }: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>
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

    const onChange =
        (callback: Function, triggerSubmit: Function) => (otp: string) => {
            callback(otp);
            if (otp.length === 6) {
                triggerSubmit(otp);
            }
        };
    return (
        <Formik<formValues>
            initialValues={{ otp: '' }}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={submitForm}>
            {({ values, errors, handleChange, handleSubmit, submitForm }) => (
                <form
                    noValidate
                    onSubmit={handleSubmit}
                    style={{ width: '100%' }}>
                    <Typography mb={2} variant="body2" color="text.secondary">
                        {constants.ENTER_TWO_FACTOR_OTP}
                    </Typography>
                    <Box my={2}>
                        <OtpInput
                            ref={otpInputRef}
                            shouldAutoFocus
                            value={values.otp}
                            onChange={onChange(handleChange('otp'), submitForm)}
                            numInputs={6}
                            separator={'-'}
                            isInputNum
                            className={'otp-input'}
                        />
                        {errors.otp && (
                            <CenteredFlex sx={{ mt: 1 }}>
                                <InvalidInputMessage>
                                    {constants.INCORRECT_CODE}
                                </InvalidInputMessage>
                            </CenteredFlex>
                        )}
                    </Box>
                    <SubmitButton
                        buttonText={props.buttonText}
                        loading={waiting}
                        disabled={values.otp.length < 6}
                    />
                </form>
            )}
        </Formik>
    );
}
