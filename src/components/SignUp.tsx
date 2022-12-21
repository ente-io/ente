import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { sendOtt } from 'services/userService';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import SubmitButton from 'components/SubmitButton';
import {
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAttributes,
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
    TextField,
    Typography,
} from '@mui/material';
import FormPaperTitle from './Form/FormPaper/Title';
import LinkButton from './pages/gallery/LinkButton';
import FormPaperFooter from './Form/FormPaper/Footer';
import VerticallyCentered from './Container';

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

    const registerUser = async (
        { email, passphrase, confirm }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            if (passphrase !== confirm) {
                setFieldError('confirm', constants.PASSPHRASE_MATCH_ERROR);
                return;
            }
            setLoading(true);
            try {
                setData(LS_KEYS.USER, { email });
                await sendOtt(email);
            } catch (e) {
                setFieldError(
                    'confirm',
                    `${constants.UNKNOWN_ERROR} ${e.message}`
                );
                throw e;
            }
            try {
                const { keyAttributes, masterKey } =
                    await generateKeyAttributes(passphrase);
                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
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
                setFieldError('confirm', constants.PASSWORD_GENERATION_FAILED);
                throw e;
            }
        } catch (err) {
            logError(err, 'signup failed');
        }
        setLoading(false);
    };

    return (
        <>
            <FormPaperTitle> {constants.SIGN_UP}</FormPaperTitle>
            <Formik<FormValues>
                initialValues={{
                    email: '',
                    passphrase: '',
                    confirm: '',
                }}
                validationSchema={Yup.object().shape({
                    email: Yup.string()
                        .email(constants.EMAIL_ERROR)
                        .required(constants.REQUIRED),
                    passphrase: Yup.string().required(constants.REQUIRED),
                    confirm: Yup.string().required(constants.REQUIRED),
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
                                label={constants.ENTER_EMAIL}
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
                                type="password"
                                label={constants.PASSPHRASE_HINT}
                                value={values.passphrase}
                                onChange={handleChange('passphrase')}
                                error={Boolean(errors.passphrase)}
                                helperText={errors.passphrase}
                                disabled={loading}
                            />

                            <TextField
                                fullWidth
                                id="confirm-password"
                                name="confirm-password"
                                autoComplete="new-password"
                                type="password"
                                label={constants.CONFIRM_PASSPHRASE}
                                value={values.confirm}
                                onChange={handleChange('confirm')}
                                error={Boolean(errors.confirm)}
                                helperText={errors.confirm}
                                disabled={loading}
                            />
                            <FormGroup sx={{ width: '100%' }}>
                                <FormControlLabel
                                    sx={{
                                        color: 'text.secondary',
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
                                    label={constants.TERMS_AND_CONDITIONS()}
                                />
                            </FormGroup>
                        </VerticallyCentered>
                        <Box my={4}>
                            <SubmitButton
                                sx={{ my: 0 }}
                                buttonText={constants.CREATE_ACCOUNT}
                                loading={loading}
                                disabled={!acceptTerms}
                            />
                            {loading && (
                                <Typography
                                    mt={1}
                                    textAlign={'center'}
                                    color="text.secondary"
                                    variant="body2">
                                    {
                                        constants.KEY_GENERATION_IN_PROGRESS_MESSAGE
                                    }
                                </Typography>
                            )}
                        </Box>
                    </form>
                )}
            </Formik>

            <FormPaperFooter>
                <LinkButton onClick={props.login}>
                    {constants.ACCOUNT_EXISTS}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
