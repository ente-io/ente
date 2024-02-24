import SetupManualMode from "@ente/accounts/components/two-factor/setup/ManualMode";
import SetupQRMode from "@ente/accounts/components/two-factor/setup/QRMode";
import { SetupMode } from "@ente/accounts/pages/two-factor/setup";
import { TwoFactorSecret } from "@ente/accounts/types/user";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { useState } from "react";

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
