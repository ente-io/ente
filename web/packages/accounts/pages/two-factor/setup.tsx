import { enableTwoFactor, setupTwoFactor } from "@/accounts/api/user";
import VerifyTwoFactor, {
    type VerifyTwoFactorCallback,
} from "@/accounts/components/two-factor/VerifyForm";
import { TwoFactorSetup } from "@/accounts/components/two-factor/setup";
import type { TwoFactorSecret } from "@/accounts/types/user";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { encryptWithRecoveryKey } from "@ente/shared/crypto/helpers";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Box, CardContent, Typography } from "@mui/material";
import Card from "@mui/material/Card";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { appHomeRoute } from "../../services/redirect";
import type { PageProps } from "../../types/page";

export enum SetupMode {
    QR_CODE,
    MANUAL_CODE,
}

const Page: React.FC<PageProps> = () => {
    const [twoFactorSecret, setTwoFactorSecret] = useState<
        TwoFactorSecret | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        if (twoFactorSecret) {
            return;
        }
        const main = async () => {
            try {
                const twoFactorSecret = await setupTwoFactor();
                setTwoFactorSecret(twoFactorSecret);
            } catch (e) {
                log.error("failed to get two factor setup code", e);
            }
        };
        main();
    }, []);

    const onSubmit: VerifyTwoFactorCallback = async (
        otp: string,
        markSuccessful,
    ) => {
        const recoveryEncryptedTwoFactorSecret = await encryptWithRecoveryKey(
            ensure(twoFactorSecret).secretCode,
        );
        await enableTwoFactor(otp, recoveryEncryptedTwoFactorSecret);
        await markSuccessful();
        await setLSUser({
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: true,
        });
        router.push(appHomeRoute);
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
                            buttonText={t("enable")}
                        />
                        <LinkButton sx={{ mt: 2 }} onClick={router.back}>
                            {t("GO_BACK")}
                        </LinkButton>
                    </VerticallyCentered>
                </CardContent>
            </Card>
        </VerticallyCentered>
    );
};

export default Page;
