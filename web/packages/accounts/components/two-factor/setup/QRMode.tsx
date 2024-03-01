import { TwoFactorSecret } from "@ente/accounts/types/user";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { t } from "i18next";

import LinkButton from "@ente/shared/components/LinkButton";
import { Typography } from "@mui/material";
import { LoadingQRCode, QRCode } from "../styledComponents";

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
            <Typography>{t("TWO_FACTOR_QR_INSTRUCTION")}</Typography>
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
                {t("ENTER_CODE_MANUALLY")}
            </LinkButton>
        </>
    );
}
