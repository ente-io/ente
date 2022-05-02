import VerifyTwoFactor from 'components/TwoFactor/VerifyForm';
import router from 'next/router';
import React, { useEffect, useState } from 'react';
import { logoutUser, verifyTwoFactor } from 'services/userService';
import { PAGES } from 'constants/pages';
import { User } from 'types/user';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import LinkButton from 'components/pages/gallery/LinkButton';
import FormContainer from 'components/Form/FormContainer';
import FormPaper from 'components/Form/FormPaper';
import FormPaperHeaderText from 'components/Form/FormPaper/HeaderText';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import { Divider } from '@mui/material';

export default function Home() {
    const [sessionID, setSessionID] = useState('');

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.CREDENTIALS);
            const user: User = getData(LS_KEYS.USER);
            if (
                user &&
                !user.isTwoFactorEnabled &&
                (user.encryptedToken || user.token)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else if (!user?.email || !user.twoFactorSessionID) {
                router.push(PAGES.ROOT);
            } else {
                setSessionID(user.twoFactorSessionID);
            }
        };
        main();
    }, []);

    const onSubmit = async (otp: string) => {
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
            <FormPaper sx={{ maxWidth: '400px' }}>
                <FormPaperHeaderText>
                    {constants.TWO_FACTOR}
                </FormPaperHeaderText>
                <VerifyTwoFactor
                    onSubmit={onSubmit}
                    buttonText={constants.VERIFY}
                />
                <Divider />
                <FormPaperFooter>
                    <LinkButton
                        onClick={() => router.push(PAGES.TWO_FACTOR_RECOVER)}>
                        {constants.LOST_DEVICE}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </FormContainer>
    );
}
