import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import CodeBlock from "@ente/shared/components/CodeBlock";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { styled, Typography } from "@mui/material";
import { t } from "i18next";
import { useState } from "react";
import { type SetupMode } from "../../pages/two-factor/setup";
import type { TwoFactorSecret } from "../../services/user";

interface TwoFactorSetupProps {
    twoFactorSecret?: TwoFactorSecret;
}

export function TwoFactorSetup({ twoFactorSecret }: TwoFactorSetupProps) {
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

interface SetupManualModeProps {
    twoFactorSecret?: TwoFactorSecret;
    changeToQRMode: () => void;
}
function SetupManualMode({
    twoFactorSecret,
    changeToQRMode,
}: SetupManualModeProps) {
    return (
        <>
            <Typography>{t("two_factor_manual_entry_message")}</Typography>
            <CodeBlock code={twoFactorSecret?.secretCode ?? ""} my={2} />
            <LinkButton onClick={changeToQRMode}>
                {t("scan_qr_title")}
            </LinkButton>
        </>
    );
}

interface SetupQRModeProps {
    twoFactorSecret?: TwoFactorSecret;
    changeToManualMode: () => void;
}

function SetupQRMode({
    twoFactorSecret,
    changeToManualMode,
}: SetupQRModeProps) {
    return (
        <>
            <Typography>{t("two_factor_qr_help")}</Typography>
            {!twoFactorSecret ? (
                <LoadingQRCode>
                    <ActivityIndicator />
                </LoadingQRCode>
            ) : (
                <QRCode
                    src={`data:image/png;base64,${twoFactorSecret?.qrCode}`}
                />
            )}
            <LinkButton onClick={changeToManualMode}>
                {t("two_factor_manual_entry_title")}
            </LinkButton>
        </>
    );
}

const QRCode = styled("img")(
    ({ theme }) => `
    height: 200px;
    width: 200px;
    margin: ${theme.spacing(2)};
`,
);

const LoadingQRCode = styled(VerticallyCentered)(
    ({ theme }) => `
    width: 200px;
    aspect-ratio:1;
    border: 1px solid ${theme.palette.grey.A200};
    margin: ${theme.spacing(2)};
    `,
);
