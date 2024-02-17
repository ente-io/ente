import { t } from 'i18next';
import { useEffect, useState } from 'react';
import { Trans } from 'react-i18next';

import { UserVerificationResponse } from '@ente/accounts/types/user';
import { PageProps } from '@ente/shared/apps/types';
import { VerticallyCentered } from '@ente/shared/components/Container';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import FormPaperFooter from '@ente/shared/components/Form/FormPaper/Footer';
import FormPaperTitle from '@ente/shared/components/Form/FormPaper/Title';
import LinkButton from '@ente/shared/components/LinkButton';
import SingleInputForm, {
    SingleInputFormProps,
} from '@ente/shared/components/SingleInputForm';
import { ApiError } from '@ente/shared/error';
import { getAccountsURL } from '@ente/shared/network/api';
import InMemoryStore, { MS_KEYS } from '@ente/shared/storage/InMemoryStore';
import { clearFiles } from '@ente/shared/storage/localForage/helpers';
import { LS_KEYS, getData, setData } from '@ente/shared/storage/localStorage';
import {
    getLocalReferralSource,
    setIsFirstLogin,
} from '@ente/shared/storage/localStorage/helpers';
import { clearKeys } from '@ente/shared/storage/sessionStorage';
import { KeyAttributes, User } from '@ente/shared/user/types';
import { Box, Typography } from '@mui/material';
import { HttpStatusCode } from 'axios';
import { putAttributes, sendOtt, verifyOtt } from '../api/user';
import { PAGES } from '../constants/pages';
import { configureSRP } from '../services/srp';
import { logoutUser } from '../services/user';
import { SRPSetupAttributes } from '../types/srp';

export default function VerifyPage({ appContext, router, appName }: PageProps) {
    const [email, setEmail] = useState('');
    const [resend, setResend] = useState(0);

    useEffect(() => {
        const main = async () => {
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
            const referralSource = getLocalReferralSource();
            const resp = await verifyOtt(email, ott, referralSource);
            const {
                keyAttributes,
                encryptedToken,
                token,
                id,
                twoFactorSessionID,
                passkeySessionID,
            } = resp.data as UserVerificationResponse;
            if (passkeySessionID) {
                const user = getData(LS_KEYS.USER);
                setData(LS_KEYS.USER, {
                    ...user,
                    passkeySessionID,
                    isTwoFactorEnabled: true,
                    isTwoFactorPasskeysEnabled: true,
                });
                setIsFirstLogin(true);
                window.location.href = `${getAccountsURL()}/passkeys/flow?passkeySessionID=${passkeySessionID}&redirect=${
                    window.location.origin
                }/passkeys/finish`;
                router.push(PAGES.CREDENTIALS);
            } else if (twoFactorSessionID) {
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
                setFieldError(`${t('UNKNOWN_ERROR')} ${JSON.stringify(e)}`);
            }
        }
    };

    const resendEmail = async () => {
        setResend(1);
        await sendOtt(appName, email);
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
