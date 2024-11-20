import SetupManualMode from "@/accounts/components/two-factor/setup/ManualMode";
import SetupQRMode from "@/accounts/components/two-factor/setup/QRMode";
import { type SetupMode } from "@/accounts/pages/two-factor/setup";
import type { TwoFactorSecret } from "@/accounts/types/user";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { useState } from "react";

interface Iprops {
    twoFactorSecret?: TwoFactorSecret;
}
export function TwoFactorSetup({ twoFactorSecret }: Iprops) {
    const [setupMode, setSetupMode] = useState<SetupMode>("qrCode");

    const changeToManualMode = () => setSetupMode("manualCode");

    const changeToQRMode = () => setSetupMode("qrCode");

    return (
        <VerticallyCentered sx={{ mb: 3 }}>
            {setupMode == "qrCode" ? (
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
