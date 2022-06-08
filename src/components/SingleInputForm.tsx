import React, { useMemo, useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import TextField from '@mui/material/TextField';
import ShowHidePassword from './Form/ShowHidePassword';
import { FlexWrapper } from './Container';

interface formValues {
    inputValue: string;
}
export interface SingleInputFormProps {
    callback: (
        inputValue: string,
        setFieldError: (errorMessage: string) => void
    ) => Promise<void>;
    fieldType: 'text' | 'email' | 'password';
    placeholder: string;
    buttonText: string;
    customSubmitButton?: any;
}

export default function SingleInputForm(props: SingleInputFormProps) {
    const [loading, SetLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const submitForm = async (
        values: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        SetLoading(true);
        await props.callback(values.inputValue, (message) =>
            setFieldError('inputValue', message)
        );
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

    const validationSchema = useMemo(() => {
        switch (props.fieldType) {
            case 'text':
                return Yup.object().shape({
                    inputValue: Yup.string().required(constants.REQUIRED),
                });
            case 'password':
                return Yup.object().shape({
                    inputValue: Yup.string().required(constants.REQUIRED),
                });
            case 'email':
                return Yup.object().shape({
                    inputValue: Yup.string()
                        .email(constants.EMAIL_ERROR)
                        .required(constants.REQUIRED),
                });
        }
    }, [props.fieldType]);

    return (
        <Formik<formValues>
            initialValues={{ inputValue: '' }}
            onSubmit={submitForm}
            validationSchema={validationSchema}
            validateOnChange={false}
            validateOnBlur={false}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <TextField
                        variant="filled"
                        fullWidth
                        type={showPassword ? 'text' : props.fieldType}
                        label={props.placeholder}
                        value={values.inputValue}
                        onChange={handleChange('inputValue')}
                        error={Boolean(errors.inputValue)}
                        helperText={errors.inputValue}
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
                    <FlexWrapper></FlexWrapper>
                    {props.customSubmitButton ? (
                        <props.customSubmitButton
                            buttonText={props.buttonText}
                            loading={loading}
                        />
                    ) : (
                        <SubmitButton
                            sx={{ mt: 2 }}
                            buttonText={props.buttonText}
                            loading={loading}
                        />
                    )}
                </form>
            )}
        </Formik>
    );
}
