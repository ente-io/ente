import type { TwoFactorSecret } from "@/accounts/types/user";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import LinkButton from "@ente/shared/components/LinkButton";
import { Typography } from "@mui/material";
import { t } from "i18next";
import { LoadingQRCode, QRCode } from "../styledComponents";

interface Iprops {
    twoFactorSecret?: TwoFactorSecret;
    changeToManualMode: () => void;
}

export default function SetupQRMode({
    twoFactorSecret,
    changeToManualMode,
}: Iprops) {
    return (
        <>
            <Typography>{t("TWO_FACTOR_QR_INSTRUCTION")}</Typography>
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
                {t("ENTER_CODE_MANUALLY")}
            </LinkButton>
        </>
    );
}
