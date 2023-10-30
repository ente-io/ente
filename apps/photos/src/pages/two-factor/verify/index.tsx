import VerifyTwoFactor, {
    VerifyTwoFactorCallback,
} from 'components/TwoFactor/VerifyForm';
import router from 'next/router';
import { useEffect, useState } from 'react';
import { logoutUser, verifyTwoFactor } from 'services/userService';
import { PAGES } from 'constants/pages';
import { User } from 'types/user';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { t } from 'i18next';

import LinkButton from 'components/pages/gallery/LinkButton';
import FormPaper from 'components/Form/FormPaper';
import FormTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import { VerticallyCentered } from 'components/Container';
import InMemoryStore, { MS_KEYS } from 'services/InMemoryStore';
import { ApiError } from 'utils/error';
import { HttpStatusCode } from 'axios';

export default function Home() {
    const [sessionID, setSessionID] = useState('');

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
            const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
            InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
            router.push(redirectURL ?? PAGES.CREDENTIALS);
        } catch (e) {
            if (
                e instanceof ApiError &&
                e.httpStatusCode === HttpStatusCode.NotFound
            ) {
                logoutUser();
            } else {
                throw e;
            }
        }
    };
    return (
        <VerticallyCentered>
            <FormPaper sx={{ maxWidth: '410px' }}>
                <FormTitle>{t('TWO_FACTOR')}</FormTitle>
                <VerifyTwoFactor onSubmit={onSubmit} buttonText={t('VERIFY')} />

                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton
                        onClick={() => router.push(PAGES.TWO_FACTOR_RECOVER)}>
                        {t('LOST_DEVICE')}
                    </LinkButton>
                    <LinkButton onClick={logoutUser}>
                        {t('CHANGE_EMAIL')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
