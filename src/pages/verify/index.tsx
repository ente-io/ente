import React, { useState, useEffect, useContext } from 'react';
import constants from 'utils/strings/constants';
import { LS_KEYS, getData, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { Formik, FormikHelpers } from 'formik';
import * as Yup from 'yup';
import {
    verifyOtt,
    getOtt,
    logoutUser,
    clearFiles,
    putAttributes,
} from 'services/userService';
import { setIsFirstLogin } from 'utils/storage';
import SubmitButton from 'components/SubmitButton';
import { clearKeys } from 'utils/storage/sessionStorage';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import { KeyAttributes, EmailVerificationResponse, User } from 'types/user';
import { Divider, TextField, Typography } from '@mui/material';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaper from 'components/Form/FormPaper';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import FormContainer from 'components/Form/FormContainer';

interface formValues {
    ott: string;
}

export default function Verify() {
    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [resend, setResend] = useState(0);
    const router = useRouter();
    const appContext = useContext(AppContext);

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.TWO_FACTOR_VERIFY);
            router.prefetch(PAGES.CREDENTIALS);
            router.prefetch(PAGES.GENERATE);
            const user: User = getData(LS_KEYS.USER);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.KEY_ATTRIBUTES
            );
            if (!user?.email) {
                router.push(PAGES.ROOT);
            } else if (
                keyAttributes?.encryptedKey &&
                (user.token || user.encryptedToken)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setEmail(user.email);
            }
        };
        main();
        appContext.showNavBar(false);
    }, []);

    const onSubmit = async (
        { ott }: formValues,
        { setFieldError }: FormikHelpers<formValues>
    ) => {
        try {
            setLoading(true);
            const resp = await verifyOtt(email, ott);
            const {
                keyAttributes,
                encryptedToken,
                token,
                id,
                twoFactorSessionID,
            } = resp.data as EmailVerificationResponse;
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
                    setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
                    setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, keyAttributes);
                } else if (getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)) {
                    await putAttributes(
                        token,
                        getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)
                    );
                }
                clearFiles();
                setIsFirstLogin(true);
                if (keyAttributes?.encryptedKey) {
                    clearKeys();
                    router.push(PAGES.CREDENTIALS);
                } else {
                    router.push(PAGES.GENERATE);
                }
            }
        } catch (e) {
            if (e?.status === 401) {
                setFieldError('ott', constants.INVALID_CODE);
            } else if (e?.status === 410) {
                setFieldError('ott', constants.EXPIRED_CODE);
            } else {
                setFieldError('ott', `${constants.UNKNOWN_ERROR} ${e.message}`);
            }
        }
        setLoading(false);
    };

    const resendEmail = async () => {
        setResend(1);
        await getOtt(email);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    };

    if (!email) {
        return null;
    }

    return (
        <FormContainer>
            <FormPaper>
                <FormPaperTitle sx={{ mb: 14 }}>
                    {constants.EMAIL_SENT({ email })}
                </FormPaperTitle>
                <Typography color={'text.secondary'} mb={2} variant="body2">
                    {constants.CHECK_INBOX}
                </Typography>
                <Formik<formValues>
                    initialValues={{ ott: '' }}
                    validationSchema={Yup.object().shape({
                        ott: Yup.string().required(constants.REQUIRED),
                    })}
                    validateOnChange={false}
                    validateOnBlur={false}
                    onSubmit={onSubmit}>
                    {({ values, errors, handleChange, handleSubmit }) => (
                        <form noValidate onSubmit={handleSubmit}>
                            <TextField
                                variant="filled"
                                fullWidth
                                type="text"
                                value={values.ott}
                                onChange={handleChange('ott')}
                                error={Boolean(errors.ott)}
                                helperText={errors.ott}
                                label={constants.ENTER_OTT}
                                disabled={loading}
                                autoFocus
                            />

                            <SubmitButton
                                sx={{ mt: 2 }}
                                buttonText={constants.VERIFY}
                                loading={loading}
                            />
                        </form>
                    )}
                </Formik>
                <Divider />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    {resend === 0 && (
                        <LinkButton onClick={resendEmail}>
                            {constants.RESEND_MAIL}
                        </LinkButton>
                    )}
                    {resend === 1 && <span>{constants.SENDING}</span>}
                    {resend === 2 && <span>{constants.SENT}</span>}
                    <LinkButton onClick={logoutUser}>
                        {constants.CHANGE_EMAIL}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </FormContainer>
    );
}
