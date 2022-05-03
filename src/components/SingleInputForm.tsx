import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import TextField from '@mui/material/TextField';
import ShowHidePassword from './Form/ShowHidePassword';

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
    const [showPassword, setShowPassword] = useState(false);

    const submitForm = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        SetLoading(true);
        await props.callback(values.passphrase, setFieldError);
        SetLoading(false);
    };

    const handleClickShowPassword = () => {
        setShowPassword(!showPassword);
    };

    const handleMouseDownPassword = (
        event: React.MouseEvent<HTMLButtonElement>
    ) => {
        event.preventDefault();
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
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <TextField
                        fullWidth
                        type={showPassword ? 'text' : props.fieldType}
                        label={props.placeholder}
                        value={values.passphrase}
                        onChange={handleChange('passphrase')}
                        error={Boolean(errors.passphrase)}
                        helperText={errors.passphrase}
                        disabled={loading}
                        autoFocus
                        InputProps={{
                            endAdornment: props.fieldType === 'password' && (
                                <ShowHidePassword
                                    showPassword={showPassword}
                                    handleClickShowPassword={
                                        handleClickShowPassword
                                    }
                                    handleMouseDownPassword={
                                        handleMouseDownPassword
                                    }
                                />
                            ),
                        }}
                    />

                    <SubmitButton
                        buttonText={props.buttonText}
                        loading={loading}
                    />

                    <br />
                </form>
            )}
        </Formik>
    );
}
