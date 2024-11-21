import log from "@/base/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { encryptWithRecoveryKey } from "@ente/shared/crypto/helpers";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Box, CardContent, Typography } from "@mui/material";
import Card from "@mui/material/Card";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { TwoFactorSetup } from "../../components/two-factor/TwoFactorSetup";
import VerifyTwoFactor, {
    type VerifyTwoFactorCallback,
} from "../../components/two-factor/VerifyForm";
import { appHomeRoute } from "../../services/redirect";
import type { TwoFactorSecret } from "../../services/user";
import { enableTwoFactor, setupTwoFactor } from "../../services/user";
import type { PageProps } from "../../types/page";

export type SetupMode = "qrCode" | "manualCode";

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
        void main();
    }, []);

    const onSubmit: VerifyTwoFactorCallback = async (
        otp: string,
        markSuccessful,
    ) => {
        const recoveryEncryptedTwoFactorSecret = await encryptWithRecoveryKey(
            twoFactorSecret!.secretCode,
        );
        await enableTwoFactor(otp, recoveryEncryptedTwoFactorSecret);
        markSuccessful();
        await setLSUser({
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: true,
        });
        void router.push(appHomeRoute);
    };

    return (
        <VerticallyCentered>
            <Card>
                <CardContent>
                    <VerticallyCentered sx={{ p: 3 }}>
                        <Box mb={4}>
                            <Typography variant="h2">
                                {t("two_factor")}
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
