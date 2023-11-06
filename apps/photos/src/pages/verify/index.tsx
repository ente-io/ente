import React, { useState, useEffect, useContext } from 'react';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

import { LS_KEYS, getData, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import {
    verifyOtt,
    sendOtt,
    logoutUser,
    clearFiles,
    putAttributes,
    configureSRP,
} from 'services/userService';
import { setIsFirstLogin } from 'utils/storage';
import { clearKeys } from 'utils/storage/sessionStorage';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import {
    KeyAttributes,
    UserVerificationResponse,
    User,
    SRPSetupAttributes,
} from 'types/user';
import { Box, Typography } from '@mui/material';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaper from 'components/Form/FormPaper';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import EnteSpinner from 'components/EnteSpinner';
import { VerticallyCentered } from 'components/Container';
import InMemoryStore, { MS_KEYS } from 'services/InMemoryStore';
import { ApiError } from 'utils/error';
import { HttpStatusCode } from 'axios';

export default function Verify() {
    const [email, setEmail] = useState('');
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
        appContext.showNavBar(true);
    }, []);

    const onSubmit: SingleInputFormProps['callback'] = async (
        ott,
        setFieldError
    ) => {
        try {
            const resp = await verifyOtt(email, ott);
            const {
                keyAttributes,
                encryptedToken,
                token,
                id,
                twoFactorSessionID,
            } = resp.data as UserVerificationResponse;
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
                } else {
                    if (getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)) {
                        await putAttributes(
                            token,
                            getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)
                        );
                    }
                    if (getData(LS_KEYS.SRP_SETUP_ATTRIBUTES)) {
                        const srpSetupAttributes: SRPSetupAttributes = getData(
                            LS_KEYS.SRP_SETUP_ATTRIBUTES
                        );
                        await configureSRP(srpSetupAttributes);
                    }
                }
                clearFiles();
                setIsFirstLogin(true);
                const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
                InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
                if (keyAttributes?.encryptedKey) {
                    clearKeys();
                    router.push(redirectURL ?? PAGES.CREDENTIALS);
                } else {
                    router.push(redirectURL ?? PAGES.GENERATE);
                }
            }
        } catch (e) {
            if (e instanceof ApiError) {
                if (e?.httpStatusCode === HttpStatusCode.Unauthorized) {
                    setFieldError(t('INVALID_CODE'));
                } else if (e?.httpStatusCode === HttpStatusCode.Gone) {
                    setFieldError(t('EXPIRED_CODE'));
                }
            } else {
                setFieldError(`${t('UNKNOWN_ERROR')} ${e.message}`);
            }
        }
    };

    const resendEmail = async () => {
        setResend(1);
        await sendOtt(email);
        setResend(2);
        setTimeout(() => setResend(0), 3000);
    };

    if (!email) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle sx={{ mb: 14, wordBreak: 'break-word' }}>
                    <Trans
                        i18nKey="EMAIL_SENT"
                        components={{
                            a: <Box color="text.muted" component={'span'} />,
                        }}
                        values={{ email }}
                    />
                </FormPaperTitle>
                <Typography color={'text.muted'} mb={2} variant="small">
                    {t('CHECK_INBOX')}
                </Typography>
                <SingleInputForm
                    fieldType="text"
                    autoComplete="one-time-code"
                    placeholder={t('ENTER_OTT')}
                    buttonText={t('VERIFY')}
                    callback={onSubmit}
                />

                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    {resend === 0 && (
                        <LinkButton onClick={resendEmail}>
                            {t('RESEND_MAIL')}
                        </LinkButton>
                    )}
                    {resend === 1 && <span>{t('SENDING')}</span>}
                    {resend === 2 && <span>{t('SENT')}</span>}
                    <LinkButton onClick={logoutUser}>
                        {t('CHANGE_EMAIL')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
