import React from 'react';
import { Typography } from '@mui/material';
import CodeBlock from 'components/CodeBlock';
import { TwoFactorSecret } from 'types/user';
import constants from 'utils/strings/constants';
import LinkButton from 'components/pages/gallery/LinkButton';

interface Iprops {
    twoFactorSecret: TwoFactorSecret;
    changeToQRMode: () => void;
}
export default function SetupManualMode({
    twoFactorSecret,
    changeToQRMode,
}: Iprops) {
    return (
        <>
            <Typography>
                {constants.TWO_FACTOR_MANUAL_CODE_INSTRUCTION}
            </Typography>
            <CodeBlock code={twoFactorSecret?.secretCode} my={2} />
            <LinkButton onClick={changeToQRMode}>
                {constants.SCAN_QR_CODE}
            </LinkButton>
        </>
    );
}
