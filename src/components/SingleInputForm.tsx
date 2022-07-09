import React, { useMemo, useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import TextField from '@mui/material/TextField';
import ShowHidePassword from './Form/ShowHidePassword';
import { FlexWrapper } from './Container';
import { Button } from '@mui/material';

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
    submitButtonProps?: any;
    initialValue?: string;
    secondaryButtonAction?: () => void;
    disableAutoFocus?: boolean;
    hiddenPreInput?: any;
    hiddenPostInput?: any;
    autoComplete?: string;
}

export default function SingleInputForm(props: SingleInputFormProps) {
    const { submitButtonProps } = props;
    const { sx: buttonSx, ...restSubmitButtonProps } = submitButtonProps ?? {};

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
            initialValues={{ inputValue: props.initialValue ?? '' }}
            onSubmit={submitForm}
            validationSchema={validationSchema}
            validateOnChange={false}
            validateOnBlur={false}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    {props.hiddenPreInput}
                    <TextField
                        variant="filled"
                        fullWidth
                        type={showPassword ? 'text' : props.fieldType}
                        id={props.fieldType}
                        name={props.fieldType}
                        label={props.placeholder}
                        value={values.inputValue}
                        onChange={handleChange('inputValue')}
                        error={Boolean(errors.inputValue)}
                        helperText={errors.inputValue}
                        disabled={loading}
                        autoFocus={!props.disableAutoFocus}
                        autoComplete={props.autoComplete}
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
                    {props.hiddenPostInput}
                    <FlexWrapper justifyContent={'flex-end'}>
                        {props.secondaryButtonAction && (
                            <Button
                                onClick={props.secondaryButtonAction}
                                size="large"
                                color="secondary"
                                sx={{ mt: 2, mb: 4, mr: 1, ...buttonSx }}
                                {...restSubmitButtonProps}>
                                {constants.CANCEL}
                            </Button>
                        )}
                        <SubmitButton
                            sx={{ mt: 2, ...buttonSx }}
                            buttonText={props.buttonText}
                            loading={loading}
                            {...restSubmitButtonProps}
                        />
                    </FlexWrapper>
                </form>
            )}
        </Formik>
    );
}
