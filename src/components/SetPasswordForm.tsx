import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import { TextField, Typography } from '@mui/material';

export interface SetPasswordFormProps {
    callback: (
        passphrase: string,
        setFieldError: (
            field: keyof SetPasswordFormValues,
            message: string
        ) => void
    ) => Promise<void>;
    buttonText: string;
    back: () => void;
}
export interface SetPasswordFormValues {
    passphrase: string;
    confirm: string;
}
function SetPasswordForm(props: SetPasswordFormProps) {
    const [loading, setLoading] = useState(false);

    const onSubmit = async (
        values: SetPasswordFormValues,
        {
            setFieldError,
        }: {
            setFieldError: (
                field: keyof SetPasswordFormValues,
                message: string
            ) => void;
        }
    ) => {
        setLoading(true);
        try {
            const { passphrase, confirm } = values;
            if (passphrase === confirm) {
                await props.callback(passphrase, setFieldError);
            } else {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
            }
        } catch (e) {
            setFieldError('confirm', `${constants.UNKNOWN_ERROR} ${e.message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Formik<SetPasswordFormValues>
            initialValues={{ passphrase: '', confirm: '' }}
            validationSchema={Yup.object().shape({
                passphrase: Yup.string().required(constants.REQUIRED),
                confirm: Yup.string().required(constants.REQUIRED),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <Typography mb={2} color="text.secondary" variant="body2">
                        {constants.ENTER_ENC_PASSPHRASE}
                    </Typography>

                    <TextField
                        fullWidth
                        variant="filled"
                        margin="dense"
                        type="password"
                        label={constants.PASSPHRASE_HINT}
                        value={values.passphrase}
                        onChange={handleChange('passphrase')}
                        error={Boolean(errors.passphrase)}
                        helperText={errors.passphrase}
                        autoFocus
                        disabled={loading}
                    />
                    <TextField
                        fullWidth
                        variant="filled"
                        margin="dense"
                        type="password"
                        label={constants.CONFIRM_PASSPHRASE}
                        value={values.confirm}
                        onChange={handleChange('confirm')}
                        disabled={loading}
                        error={Boolean(errors.confirm)}
                        helperText={errors.confirm}
                    />

                    <Typography my={2} variant="body2">
                        {constants.PASSPHRASE_DISCLAIMER()}
                    </Typography>

                    <SubmitButton
                        loading={loading}
                        buttonText={props.buttonText}
                    />
                </form>
            )}
        </Formik>
    );
}
export default SetPasswordForm;
