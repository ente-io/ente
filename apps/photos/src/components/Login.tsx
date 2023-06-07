import { useRouter } from 'next/router';
import { getSRPAttributes, sendOtt, verifySRP } from 'services/userService';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { PAGES } from 'constants/pages';
import FormPaperTitle from './Form/FormPaper/Title';
import FormPaperFooter from './Form/FormPaper/Footer';
import LinkButton from './pages/gallery/LinkButton';
import { t } from 'i18next';
import { setUserSRPSetupPending } from 'utils/storage';
import { addLocalLog } from 'utils/logging';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { TextField } from '@mui/material';
import { VerticallyCentered } from './Container';
import ShowHidePassword from './Form/ShowHidePassword';
import { useState } from 'react';
import SubmitButton from './SubmitButton';

interface LoginProps {
    signUp: () => void;
}

interface FormValues {
    email: string;
    passphrase: string;
}

export default function Login(props: LoginProps) {
    const router = useRouter();
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

    const loginUser = async (
        { email, passphrase }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>
    ) => {
        try {
            setLoading(true);
            const srpAttributes = await getSRPAttributes(email);
            addLocalLog(
                () => ` srpAttributes: ${JSON.stringify(srpAttributes)}`
            );
            if (!srpAttributes) {
                setUserSRPSetupPending(true);
                await sendOtt(email);
                setData(LS_KEYS.USER, { email });
                router.push(PAGES.VERIFY);
            } else {
                verifySRP(srpAttributes.srpSalt, email, passphrase);
                // TODO , make the srp login flow
            }
        } catch (e) {
            setFieldError('password', `${t('UNKNOWN_ERROR} ${e.message}')}`);
        }
        setLoading(false);
    };

    return (
        <>
            <FormPaperTitle>{t('LOGIN')}</FormPaperTitle>
            <Formik<FormValues>
                initialValues={{
                    email: '',
                    passphrase: '',
                }}
                validationSchema={Yup.object().shape({
                    email: Yup.string()
                        .email(t('EMAIL_ERROR'))
                        .required(t('REQUIRED')),
                    passphrase: Yup.string().required(t('REQUIRED')),
                })}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={loginUser}>
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
                                autoComplete="password"
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
                        </VerticallyCentered>
                        <SubmitButton
                            sx={{ my: 0 }}
                            buttonText={t('LOGIN')}
                            loading={loading}
                        />
                    </form>
                )}
            </Formik>

            <FormPaperFooter>
                <LinkButton onClick={props.signUp}>
                    {t('NO_ACCOUNT')}
                </LinkButton>
            </FormPaperFooter>
        </>
    );
}
