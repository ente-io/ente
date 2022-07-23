import React, { useState, useEffect, useContext } from 'react';
import constants from 'utils/strings/constants';
import { LS_KEYS, getData, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import {
    verifyOtt,
    sendOtt,
    logoutUser,
    clearFiles,
    putAttributes,
} from 'services/userService';
import { setIsFirstLogin } from 'utils/storage';
import { clearKeys } from 'utils/storage/sessionStorage';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import { KeyAttributes, EmailVerificationResponse, User } from 'types/user';
import { Typography } from '@mui/material';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaper from 'components/Form/FormPaper';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import FormContainer from 'components/Form/FormContainer';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import EnteSpinner from 'components/EnteSpinner';
import VerticallyCentered from 'components/Container';

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
                setFieldError(constants.INVALID_CODE);
            } else if (e?.status === 410) {
                setFieldError(constants.EXPIRED_CODE);
            } else {
                setFieldError(`${constants.UNKNOWN_ERROR} ${e.message}`);
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
        <FormContainer>
            <FormPaper>
                <FormPaperTitle sx={{ mb: 14, wordBreak: 'break-word' }}>
                    {constants.EMAIL_SENT({ email })}
                </FormPaperTitle>
                <Typography color={'text.secondary'} mb={2} variant="body2">
                    {constants.CHECK_INBOX}
                </Typography>
                <SingleInputForm
                    fieldType="text"
                    autoComplete="one-time-code"
                    placeholder={constants.ENTER_OTT}
                    buttonText={constants.VERIFY}
                    callback={onSubmit}
                />

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
