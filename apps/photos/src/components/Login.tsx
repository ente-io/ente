import { useRouter } from 'next/router';
import {
    clearFiles,
    getSRPAttributes,
    loginViaSRP,
    sendOtt,
} from 'services/userService';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { PAGES } from 'constants/pages';
import FormPaperTitle from './Form/FormPaper/Title';
import FormPaperFooter from './Form/FormPaper/Footer';
import LinkButton from './pages/gallery/LinkButton';
import { t } from 'i18next';
import { setIsFirstLogin, setUserSRPSetupPending } from 'utils/storage';
import { addLocalLog } from 'utils/logging';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import { TextField } from '@mui/material';
import { VerticallyCentered } from './Container';
import ShowHidePassword from './Form/ShowHidePassword';
import { useContext, useState } from 'react';
import SubmitButton from './SubmitButton';
import { SESSION_KEYS, clearKeys } from 'utils/storage/sessionStorage';
import { getAppName, APPS } from 'constants/apps';
import {
    generateAndSaveIntermediateKeyAttributes,
    saveKeyInSessionStore,
    decryptAndStoreToken,
} from 'utils/crypto';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';
import { AppContext } from 'pages/_app';

interface LoginProps {
    signUp: () => void;
}

interface FormValues {
    email: string;
    passphrase: string;
}

export default function Login(props: LoginProps) {
    const appContext = useContext(AppContext);
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
                const {
                    keyAttributes,
                    encryptedToken,
                    token,
                    id,
                    twoFactorSessionID,
                } = await loginViaSRP(srpAttributes, passphrase);
                if (twoFactorSessionID) {
                    setData(LS_KEYS.USER, {
                        email,
                        twoFactorSessionID,
                        isTwoFactorEnabled: true,
                    });
                    setIsFirstLogin(true);
                    router.push(PAGES.TWO_FACTOR_VERIFY);
                } else {
                    setData(LS_KEYS.USER, {
                        email,
                        token,
                        encryptedToken,
                        id,
                        isTwoFactorEnabled: false,
                    });
                    if (keyAttributes) {
                        try {
                            const cryptoWorker =
                                await ComlinkCryptoWorker.getInstance();
                            let kek: string = null;
                            try {
                                kek = await cryptoWorker.deriveKey(
                                    passphrase,
                                    keyAttributes.kekSalt,
                                    keyAttributes.opsLimit,
                                    keyAttributes.memLimit
                                );
                            } catch (e) {
                                logError(e, 'failed to derive key');
                                throw Error(CustomError.WEAK_DEVICE);
                            }
                            try {
                                const key = await cryptoWorker.decryptB64(
                                    keyAttributes.encryptedKey,
                                    keyAttributes.keyDecryptionNonce,
                                    kek
                                );
                                clearFiles();
                                clearKeys();
                                await generateAndSaveIntermediateKeyAttributes(
                                    passphrase,
                                    keyAttributes,
                                    key
                                );

                                await saveKeyInSessionStore(
                                    SESSION_KEYS.ENCRYPTION_KEY,
                                    key
                                );
                                await decryptAndStoreToken(key);
                                const redirectURL = appContext.redirectURL;
                                appContext.setRedirectURL(null);
                                const appName = getAppName();
                                if (appName === APPS.AUTH) {
                                    router.push(PAGES.AUTH);
                                } else {
                                    router.push(redirectURL ?? PAGES.GALLERY);
                                }
                            } catch (e) {
                                logError(e, 'user entered a wrong password');
                                throw Error(CustomError.INCORRECT_PASSWORD);
                            }
                        } catch (e) {
                            switch (e.message) {
                                case CustomError.WEAK_DEVICE:
                                    setFieldError(
                                        'passphrase',
                                        t('WEAK_DEVICE')
                                    );
                                    break;
                                case CustomError.INCORRECT_PASSWORD:
                                    setFieldError(
                                        'passphrase',
                                        t('INCORRECT_PASSPHRASE')
                                    );
                                    break;
                                default:
                                    setFieldError(
                                        'passphrase',
                                        `${t('UNKNOWN_ERROR')} ${e.message}`
                                    );
                            }
                        }
                    }
                }
            }
        } catch (e) {
            setFieldError('passphrase', `${t('UNKNOWN_ERROR} ${e.message}')}`);
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
