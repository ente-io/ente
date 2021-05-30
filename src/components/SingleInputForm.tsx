import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Form } from 'react-bootstrap';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';

interface formValues {
    passphrase: string;
}
interface Props {
    callback: (passphrase: string, setFieldError) => void;
    fieldType: string;
    placeholder: string;
    buttonText: string;
}

export default function SingleInputForm(props: Props) {
    const [loading, SetLoading] = useState(false);
    const submitForm = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>,
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
            validateOnBlur={false}
        >
            {({
                values, touched, errors, handleChange, handleSubmit,
            }) => (
                <Form noValidate onSubmit={handleSubmit}>
                    <Form.Group>
                        <Form.Control
                            type={props.fieldType}
                            placeholder={props.placeholder}
                            value={values.passphrase}
                            onChange={handleChange('passphrase')}
                            isInvalid={Boolean(
                                touched.passphrase && errors.passphrase,
                            )}
                            disabled={loading}
                            autoFocus
                        />
                        <Form.Control.Feedback type="invalid">
                            {errors.passphrase}
                        </Form.Control.Feedback>
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
