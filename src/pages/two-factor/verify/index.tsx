import VerifyTwoFactor, {
    VerifyTwoFactorCallback,
} from 'components/TwoFactor/VerifyForm';
import router from 'next/router';
import React, { useContext, useEffect, useState } from 'react';
import { logoutUser, verifyTwoFactor } from 'services/userService';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import { User } from 'types/user';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

import LinkButton from 'components/pages/gallery/LinkButton';
import FormContainer from 'components/Form/FormContainer';
import FormPaper from 'components/Form/FormPaper';
import FormTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';

export default function Home() {
    const [sessionID, setSessionID] = useState('');
    const appContext = useContext(AppContext);

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.CREDENTIALS);
            const user: User = getData(LS_KEYS.USER);
            if (!user?.email || !user.twoFactorSessionID) {
                router.push(PAGES.ROOT);
            } else if (
                !user.isTwoFactorEnabled &&
                (user.encryptedToken || user.token)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setSessionID(user.twoFactorSessionID);
            }
        };
        main();
    }, []);

    const showContactSupport = () => {
        appContext.setDialogMessage({
            title: t('CONTACT_SUPPORT'),
            close: {},
            content: (
                <Trans i18nKey="NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE">
                    Please drop an email to{' '}
                    <a href="mailto:support@ente.io">support@ente.io</a> from
                    your registered email address
                </Trans>
            ),
        });
    };

    const onSubmit: VerifyTwoFactorCallback = async (otp) => {
        try {
            const resp = await verifyTwoFactor(otp, sessionID);
            const { keyAttributes, encryptedToken, token, id } = resp;
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            if (e.status === 404) {
                logoutUser();
            } else {
                throw e;
            }
        }
    };
    return (
        <FormContainer>
            <FormPaper sx={{ maxWidth: '410px' }}>
                <FormTitle>{t('TWO_FACTOR')}</FormTitle>
                <VerifyTwoFactor onSubmit={onSubmit} buttonText={t('VERIFY')} />

                <FormPaperFooter>
                    <LinkButton onClick={showContactSupport}>
                        {t('LOST_DEVICE')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </FormContainer>
    );
}
