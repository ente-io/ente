import { TwoFactorSecret } from "@ente/accounts/types/user";
import CodeBlock from "@ente/shared/components/CodeBlock";
import { Typography } from "@mui/material";
import { t } from "i18next";

import LinkButton from "@ente/shared/components/LinkButton";

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
            <Typography>{t("TWO_FACTOR_MANUAL_CODE_INSTRUCTION")}</Typography>
            <CodeBlock code={twoFactorSecret?.secretCode} my={2} />
            <LinkButton onClick={changeToQRMode}>
                {t("SCAN_QR_CODE")}
            </LinkButton>
        </>
    );
}
