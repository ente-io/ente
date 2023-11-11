import VerifyTwoFactor, {
    VerifyTwoFactorCallback,
} from '@ente/accounts/components/two-factor/VerifyForm';
import { useEffect, useState } from 'react';
import { logoutUser } from '@ente/accounts/services/user';
import { verifyTwoFactor } from '@ente/accounts/api/user';
import { PAGES } from '@ente/accounts/constants/pages';
import { User } from '@ente/shared/user/types';
import { setData, LS_KEYS, getData } from '@ente/shared/storage/localStorage';
import { t } from 'i18next';

import LinkButton from '@ente/shared/components/LinkButton';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import FormTitle from '@ente/shared/components/Form/FormPaper/Title';
import FormPaperFooter from '@ente/shared/components/Form/FormPaper/Footer';
import { VerticallyCentered } from '@ente/shared/components/Container';
import InMemoryStore, { MS_KEYS } from '@ente/shared/storage/InMemoryStore';
import { ApiError } from '@ente/shared/error';
import { HttpStatusCode } from 'axios';
import { PageProps } from '@ente/shared/apps/types';

export default function TwoFactorVerify({ router }: PageProps) {
    const [sessionID, setSessionID] = useState('');

    useEffect(() => {
        const main = async () => {
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
