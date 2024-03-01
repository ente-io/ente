import { enableTwoFactor, setupTwoFactor } from "@ente/accounts/api/user";
import { t } from "i18next";
import { useEffect, useState } from "react";

import VerifyTwoFactor, {
    VerifyTwoFactorCallback,
} from "@ente/accounts/components/two-factor/VerifyForm";
import { TwoFactorSetup } from "@ente/accounts/components/two-factor/setup";
import { TwoFactorSecret } from "@ente/accounts/types/user";
import { APP_HOMES } from "@ente/shared/apps/constants";
import { PageProps } from "@ente/shared/apps/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { encryptWithRecoveryKey } from "@ente/shared/crypto/helpers";
import { logError } from "@ente/shared/sentry";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { Box, CardContent, Typography } from "@mui/material";
import Card from "@mui/material/Card";

export enum SetupMode {
    QR_CODE,
    MANUAL_CODE,
}

export default function SetupTwoFactor({ router, appName }: PageProps) {
    const [twoFactorSecret, setTwoFactorSecret] =
        useState<TwoFactorSecret>(null);

    useEffect(() => {
        if (twoFactorSecret) {
            return;
        }
        const main = async () => {
            try {
                const twoFactorSecret = await setupTwoFactor();
                setTwoFactorSecret(twoFactorSecret);
            } catch (e) {
                logError(e, "failed to get two factor setup code");
            }
        };
        main();
    }, []);

    const onSubmit: VerifyTwoFactorCallback = async (
        otp: string,
        markSuccessful,
    ) => {
        const recoveryEncryptedTwoFactorSecret = await encryptWithRecoveryKey(
            twoFactorSecret.secretCode,
        );
        await enableTwoFactor(otp, recoveryEncryptedTwoFactorSecret);
        await markSuccessful();
        setData(LS_KEYS.USER, {
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: true,
        });
        router.push(APP_HOMES.get(appName));
    };

    return (
        <VerticallyCentered>
            <Card>
                <CardContent>
                    <VerticallyCentered sx={{ p: 3 }}>
                        <Box mb={4}>
                            <Typography variant="h2">
                                {t("TWO_FACTOR")}
                            </Typography>
                        </Box>
                        <TwoFactorSetup twoFactorSecret={twoFactorSecret} />
                        <VerifyTwoFactor
                            onSubmit={onSubmit}
                            buttonText={t("ENABLE")}
                        />
                        <LinkButton sx={{ mt: 2 }} onClick={router.back}>
                            {t("GO_BACK")}
                        </LinkButton>
                    </VerticallyCentered>
                </CardContent>
            </Card>
        </VerticallyCentered>
    );
}
