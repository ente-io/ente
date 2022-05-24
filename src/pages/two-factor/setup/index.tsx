import LogoImg from 'components/LogoImg';
import React, { useContext, useEffect, useState } from 'react';
import { enableTwoFactor, setupTwoFactor } from 'services/userService';
import constants from 'utils/strings/constants';
import VerticallyCentered from 'components/Container';
import { useRouter } from 'next/router';
import VerifyTwoFactor from 'components/TwoFactor/VerifyForm';
import { encryptWithRecoveryKey } from 'utils/crypto';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import { AppContext, FLASH_MESSAGE_TYPE } from 'pages/_app';
import { PAGES } from 'constants/pages';
import { TwoFactorSecret } from 'types/user';
import Card from '@mui/material/Card';
import { Box, CardContent } from '@mui/material';
import { TwoFactorSetup } from 'components/TwoFactor/Setup';
import LinkButton from 'components/pages/gallery/LinkButton';

export enum SetupMode {
    QR_CODE,
    MANUAL_CODE,
}

export default function SetupTwoFactor() {
    const [twoFactorSecret, setTwoFactorSecret] =
        useState<TwoFactorSecret>(null);

    const router = useRouter();
    const appContext = useContext(AppContext);
    useEffect(() => {
        if (twoFactorSecret) {
            return;
        }
        const main = async () => {
            try {
                const twoFactorSecret = await setupTwoFactor();
                setTwoFactorSecret(twoFactorSecret);
            } catch (e) {
                appContext.setDisappearingFlashMessage({
                    message: constants.TWO_FACTOR_SETUP_FAILED,
                    type: FLASH_MESSAGE_TYPE.DANGER,
                });
                router.push(PAGES.GALLERY);
            }
        };
        main();
    }, []);

    const onSubmit = async (otp: string) => {
        const recoveryEncryptedTwoFactorSecret = await encryptWithRecoveryKey(
            twoFactorSecret.secretCode
        );
        await enableTwoFactor(otp, recoveryEncryptedTwoFactorSecret);
        setData(LS_KEYS.USER, {
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: true,
        });
        appContext.setDisappearingFlashMessage({
            message: constants.TWO_FACTOR_SETUP_SUCCESS,
            type: FLASH_MESSAGE_TYPE.SUCCESS,
        });
        router.push(PAGES.GALLERY);
    };

    return (
        <VerticallyCentered>
            <Card>
                <CardContent>
                    <VerticallyCentered sx={{ p: 3 }}>
                        <Box mb={4}>
                            <LogoImg src="/icon.svg" />
                            {constants.TWO_FACTOR}
                        </Box>
                        <TwoFactorSetup twoFactorSecret={twoFactorSecret} />
                        <VerifyTwoFactor
                            onSubmit={onSubmit}
                            buttonText={constants.ENABLE}
                        />
                        <LinkButton sx={{ mt: 2 }} onClick={router.back}>
                            {constants.GO_BACK}
                        </LinkButton>
                    </VerticallyCentered>
                </CardContent>
            </Card>
        </VerticallyCentered>
    );
}
