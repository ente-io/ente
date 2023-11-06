import React, { useState } from 'react';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { sendOtt } from 'services/userService';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import SubmitButton from 'components/SubmitButton';
import {
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAndSRPAttributes,
    isWeakPassword,
    saveKeyInSessionStore,
} from 'utils/crypto';
import { setJustSignedUp } from 'utils/storage';
import { logError } from 'utils/sentry';
import { SESSION_KEYS } from 'utils/storage/sessionStorage';
import { PAGES } from 'constants/pages';
import {
    Box,
    Checkbox,
    FormControlLabel,
    FormGroup,
    Link,
    TextField,
    Typography,
} from '@mui/material';
import FormPaperTitle from './Form/FormPaper/Title';
import LinkButton from './pages/gallery/LinkButton';
import FormPaperFooter from './Form/FormPaper/Footer';
import { VerticallyCentered } from './Container';
import { PasswordStrengthHint } from './PasswordStrength';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import ShowHidePassword from './Form/ShowHidePassword';

interface FormValues {
    email: string;
    passphrase: string;
    confirm: string;
}

interface SignUpProps {
    login: () => void;
}

export default function SignUp(props: SignUpProps) {
    const router = useRouter();
    const [acceptTerms, setAcceptTerms] = useState(false);
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

    const registerUser = async (
        { email, passphrase, confirm }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            if (passphrase !== confirm) {
                setFieldError('confirm', t('PASSPHRASE_MATCH_ERROR'));
                return;
            }
            setLoading(true);
            try {
                setData(LS_KEYS.USER, { email });
                await sendOtt(email);
            } catch (e) {
                setFieldError('confirm', `${t('UNKNOWN_ERROR')} ${e.message}`);
                throw e;
            }
            try {
                const { keyAttributes, masterKey, srpSetupAttributes } =
                    await generateKeyAndSRPAttributes(passphrase);

                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
                setData(LS_KEYS.SRP_SETUP_ATTRIBUTES, srpSetupAttributes);
                await generateAndSaveIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    masterKey
                );

                await saveKeyInSessionStore(
                    SESSION_KEYS.ENCRYPTION_KEY,
                    masterKey
                );
                setJustSignedUp(true);
                router.push(PAGES.VERIFY);
            } catch (e) {
                setFieldError('confirm', t('PASSWORD_GENERATION_FAILED'));
                throw e;
            }
        } catch (err) {
            logError(err, 'signup failed');
        }
        setLoading(false);
    };

    return (
        <>
            <FormPaperTitle> {t('SIGN_UP')}</FormPaperTitle>
            <Formik<FormValues>
                initialValues={{
                    email: '',
                    passphrase: '',
                    confirm: '',
                }}
                validationSchema={Yup.object().shape({
                    email: Yup.string()
                        .email(t('EMAIL_ERROR'))
                        .required(t('REQUIRED')),
                    passphrase: Yup.string().required(t('REQUIRED')),
                    confirm: Yup.string().required(t('REQUIRED')),
                })}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={registerUser}>
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                }): JSX.Element => (
                    <form noValidate onSubmit={handleSubmit}>
                        <VerticallyCentered sx={{ mb: 1 }}>
                            <TextField
                                fullWidth
                                id="email"
                                name="email"
                                autoComplete="username"
                                type="email"
                                label={t('ENTER_EMAIL')}
                                value={values.email}
                                onChange={handleChange('email')}
                                error={Boolean(errors.email)}
                                helperText={errors.email}
                                autoFocus
                                disabled={loading}
                            />

                            <TextField
                                fullWidth
                                id="password"
                                name="password"
                                autoComplete="new-password"
                                type={showPassword ? 'text' : 'password'}
                                label={t('PASSPHRASE_HINT')}
                                value={values.passphrase}
                                onChange={handleChange('passphrase')}
                                error={Boolean(errors.passphrase)}
                                helperText={errors.passphrase}
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
                                id="confirm-password"
                                name="confirm-password"
                                autoComplete="new-password"
                                type="password"
                                label={t('CONFIRM_PASSPHRASE')}
                                value={values.confirm}
                                onChange={handleChange('confirm')}
                                error={Boolean(errors.confirm)}
                                helperText={errors.confirm}
                                disabled={loading}
                            />
                            <PasswordStrengthHint
                                password={values.passphrase}
                            />
                            <FormGroup sx={{ width: '100%' }}>
                                <FormControlLabel
                                    sx={{
                                        color: 'text.muted',
                                        ml: 0,
                                        mt: 2,
                                    }}
                                    control={
                                        <Checkbox
                                            size="small"
                                            disabled={loading}
                                            checked={acceptTerms}
                                            onChange={(e) =>
                                                setAcceptTerms(e.target.checked)
                                            }
                                            color="accent"
                                        />
                                    }
                                    label={
                                        <Typography variant="small">
                                            <Trans
                                                i18nKey={'TERMS_AND_CONDITIONS'}
                                                components={{
                                                    a: (
                                                        <Link
                                                            href="https://ente.io/terms"
                                                            target="_blank"
                                                        />
                                                    ),
                                                    b: (
                                                        <Link
                                                            href="https://ente.io/privacy"
                                                            target="_blank"
                                                        />
                                                    ),
                                                }}
                                            />
                                        </Typography>
                                    }
                                />
                            </FormGroup>
                        </VerticallyCentered>
                        <Box my={4}>
                            <SubmitButton
                                sx={{ my: 0 }}
                                buttonText={t('CREATE_ACCOUNT')}
                                loading={loading}
                                disabled={
                                    !acceptTerms ||
                                    isWeakPassword(values.passphrase)
                                }
                            />
                            {loading && (
                                <Typography
                                    mt={1}
                                    textAlign={'center'}
                                    color="text.muted"
                                    variant="small">
                                    {t('KEY_GENERATION_IN_PROGRESS_MESSAGE')}
                                </Typography>
                            )}
                        </Box>
                    </form>
                )}
            </Formik>

            <FormPaperFooter>
                <LinkButton onClick={props.login}>
                    {t('ACCOUNT_EXISTS')}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
