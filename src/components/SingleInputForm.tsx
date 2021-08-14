import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Form } from 'react-bootstrap';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import styled from 'styled-components';
import Visibility from './icons/Visibility';
import VisibilityOff from './icons/VisibilityOff';

interface formValues {
    passphrase: string;
}
interface Props {
    callback: (passphrase: string, setFieldError) => void;
    fieldType: string;
    placeholder: string;
    buttonText: string;
}

const Group = styled.div`
    position: relative;
`;

const Button = styled.button`
    background: transparent;
    border: none;
    width: 46px;
    height: 34px;
    position: absolute;
    top: 1px;
    right: 1px;
    border-radius: 5px;
    align-items: center;
`;

export default function SingleInputForm(props: Props) {
    const [loading, SetLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const submitForm = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        SetLoading(true);
        await props.callback(values.passphrase, setFieldError);
        SetLoading(false);
    };
    return (
        <Formik<formValues>
            initialValues={{ passphrase: '' }}
            onSubmit={submitForm}
            validationSchema={Yup.object().shape({
                passphrase: Yup.string().required(constants.REQUIRED),
            })}
            validateOnChange={false}
            validateOnBlur={false}>
            {({ values, touched, errors, handleChange, handleSubmit }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Group>
                        <Group>
                            <Form.Control
                                type={showPassword ? 'text' : props.fieldType}
                                placeholder={props.placeholder}
                                value={values.passphrase}
                                onChange={handleChange('passphrase')}
                                isInvalid={Boolean(
                                    touched.passphrase && errors.passphrase
                                )}
                                disabled={loading}
                                autoFocus
                            />
                            {props.fieldType === 'password' && (
                                <Button
                                    type="button"
                                    onClick={() =>
                                        setShowPassword(!showPassword)
                                    }>
                                    {showPassword ? (
                                        <VisibilityOff />
                                    ) : (
                                        <Visibility />
                                    )}
                                </Button>
                            )}
                            <Form.Control.Feedback type="invalid">
                                {errors.passphrase}
                            </Form.Control.Feedback>
                        </Group>
                    </Form.Group>
                    <SubmitButton
                        buttonText={props.buttonText}
                        loading={loading}
                    />

                    <br />
                </Form>
            )}
        </Formik>
    );
}
