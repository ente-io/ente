import React from 'react';
import { Typography } from '@mui/material';
import CodeBlock from 'components/CodeBlock';
import { TwoFactorSecret } from 'types/user';
import { useTranslation } from 'react-i18next';

import LinkButton from 'components/pages/gallery/LinkButton';

interface Iprops {
    twoFactorSecret: TwoFactorSecret;
    changeToQRMode: () => void;
}
export default function SetupManualMode({
    twoFactorSecret,
    changeToQRMode,
}: Iprops) {
    const { t } = useTranslation();

    return (
        <>
            <Typography>{t('TWO_FACTOR_MANUAL_CODE_INSTRUCTION')}</Typography>
            <CodeBlock code={twoFactorSecret?.secretCode} my={2} />
            <LinkButton onClick={changeToQRMode}>
                {t('SCAN_QR_CODE')}
            </LinkButton>
        </>
    );
}
