import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import { Box, Input, TextField, Typography } from '@mui/material';

export interface SetPasswordFormProps {
    userEmail: string;
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

                    <Input
                        hidden
                        name="email"
                        id="email"
                        autoComplete="username"
                        type="email"
                        value={props.userEmail}
                    />
                    <TextField
                        fullWidth
                        name="password"
                        id="password"
                        autoComplete="new-password"
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
                        name="confirm-password"
                        id="confirm-password"
                        autoComplete="new-password"
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

                    <Box my={4}>
                        <SubmitButton
                            sx={{ my: 0 }}
                            loading={loading}
                            buttonText={props.buttonText}
                        />
                        {loading && (
                            <Typography
                                textAlign="center"
                                mt={1}
                                color="text.secondary"
                                variant="body2">
                                {constants.KEY_GENERATION_IN_PROGRESS_MESSAGE}
                            </Typography>
                        )}
                    </Box>
                </form>
            )}
        </Formik>
    );
}
export default SetPasswordForm;
