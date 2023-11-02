import { VerticallyCentered } from 'components/Container';
import { SetupMode } from 'pages/two-factor/setup';
import SetupManualMode from 'pages/two-factor/setup/ManualMode';
import SetupQRMode from 'pages/two-factor/setup/QRMode';
import React, { useState } from 'react';
import { TwoFactorSecret } from 'types/user';

interface Iprops {
    twoFactorSecret: TwoFactorSecret;
}
export function TwoFactorSetup({ twoFactorSecret }: Iprops) {
    const [setupMode, setSetupMode] = useState<SetupMode>(SetupMode.QR_CODE);

    const changeToManualMode = () => setSetupMode(SetupMode.MANUAL_CODE);

    const changeToQRMode = () => setSetupMode(SetupMode.QR_CODE);

    return (
        <VerticallyCentered sx={{ mb: 3 }}>
            {setupMode === SetupMode.QR_CODE ? (
                <SetupQRMode
                    twoFactorSecret={twoFactorSecret}
                    changeToManualMode={changeToManualMode}
                />
            ) : (
                <SetupManualMode
                    twoFactorSecret={twoFactorSecret}
                    changeToQRMode={changeToQRMode}
                />
            )}
        </VerticallyCentered>
    );
}
