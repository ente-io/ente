import React, { useState } from 'react';
import { Formik } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import { Box, Input, TextField, Typography } from '@mui/material';
import { PasswordStrengthHint } from './PasswordStrength';
import { isWeakPassword } from 'utils/crypto';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import ShowHidePassword from './Form/ShowHidePassword';

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
}
export interface SetPasswordFormValues {
    passphrase: string;
    confirm: string;
}
function SetPasswordForm(props: SetPasswordFormProps) {
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleClickShowPassword = () => {
        setShowPassword(!showPassword);
    };

    const handleMouseDownPassword = (
        event: React.MouseEvent<HTMLButtonElement>
    ) => {
        event.preventDefault();
    };

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
                setFieldError('confirm', t('PASSPHRASE_MATCH_ERROR'));
            }
        } catch (e) {
            setFieldError('confirm', `${t('UNKNOWN_ERROR')} ${e.message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Formik<SetPasswordFormValues>
            initialValues={{ passphrase: '', confirm: '' }}
            validationSchema={Yup.object().shape({
                passphrase: Yup.string().required(t('REQUIRED')),
                confirm: Yup.string().required(t('REQUIRED')),
            })}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    <Typography mb={2} color="text.muted" variant="small">
                        {t('ENTER_ENC_PASSPHRASE')}
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
                        type={showPassword ? 'text' : 'password'}
                        label={t('PASSPHRASE_HINT')}
                        value={values.passphrase}
                        onChange={handleChange('passphrase')}
                        error={Boolean(errors.passphrase)}
                        helperText={errors.passphrase}
                        autoFocus
                        disabled={loading}
                        InputProps={{
                            endAdornment: (
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
                    <TextField
                        fullWidth
                        name="confirm-password"
                        id="confirm-password"
                        autoComplete="new-password"
                        type="password"
                        label={t('CONFIRM_PASSPHRASE')}
                        value={values.confirm}
                        onChange={handleChange('confirm')}
                        disabled={loading}
                        error={Boolean(errors.confirm)}
                        helperText={errors.confirm}
                    />
                    <PasswordStrengthHint password={values.passphrase} />

                    <Typography my={2} variant="small">
                        <Trans i18nKey={'PASSPHRASE_DISCLAIMER'} />
                    </Typography>

                    <Box my={4}>
                        <SubmitButton
                            sx={{ my: 0 }}
                            loading={loading}
                            buttonText={props.buttonText}
                            disabled={isWeakPassword(values.passphrase)}
                        />
                        {loading && (
                            <Typography
                                textAlign="center"
                                mt={1}
                                color="text.muted"
                                variant="small">
                                {t('KEY_GENERATION_IN_PROGRESS_MESSAGE')}
                            </Typography>
                        )}
                    </Box>
                </form>
            )}
        </Formik>
    );
}
export default SetPasswordForm;
