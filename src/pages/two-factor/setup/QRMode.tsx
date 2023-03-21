import React from 'react';
import EnteSpinner from 'components/EnteSpinner';
import { TwoFactorSecret } from 'types/user';
import { t } from 'i18next';

import {
    LoadingQRCode,
    QRCode,
} from '../../../components/TwoFactor/styledComponents';
import { Typography } from '@mui/material';
import LinkButton from 'components/pages/gallery/LinkButton';

interface Iprops {
    twoFactorSecret: TwoFactorSecret;
    changeToManualMode: () => void;
}

export default function SetupQRMode({
    twoFactorSecret,
    changeToManualMode,
}: Iprops) {
    return (
        <>
            <Typography>{t('TWO_FACTOR_QR_INSTRUCTION')}</Typography>
            {!twoFactorSecret ? (
                <LoadingQRCode>
                    <EnteSpinner />
                </LoadingQRCode>
            ) : (
                <QRCode
                    src={`data:image/png;base64,${twoFactorSecret?.qrCode}`}
                />
            )}
            <LinkButton onClick={changeToManualMode}>
                {t('ENTER_CODE_MANUALLY')}
            </LinkButton>
        </>
    );
}
