import {
    VerifyTwoFactor,
    type VerifyTwoFactorCallback,
} from "@/accounts/components/two-factor/VerifyTwoFactor";
import { appHomeRoute } from "@/accounts/services/redirect";
import type { TwoFactorSecret } from "@/accounts/services/user";
import { enableTwoFactor, setupTwoFactor } from "@/accounts/services/user";
import { CenteredFill } from "@/base/components/containers";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import log from "@/base/log";
import { encryptWithRecoveryKey } from "@ente/shared/crypto/helpers";
import { getData, LS_KEYS, setLSUser } from "@ente/shared/storage/localStorage";
import { Paper, Stack, styled, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { TwoFactorSetup } from "../../components/two-factor/TwoFactorSetup";

export type SetupMode = "qrCode" | "manualCode";

const Page: React.FC = () => {
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
        <Stack sx={{ minHeight: "100svh" }}>
            <CenteredFill>
                <ContentsPaper>
                    <Typography variant="h5" sx={{ textAlign: "center" }}>
                        {t("two_factor")}
                    </Typography>
                    <Stack>
                        <TwoFactorSetup twoFactorSecret={twoFactorSecret} />
                        <VerifyTwoFactor
                            onSubmit={onSubmit}
                            buttonText={t("enable")}
                        />
                        <Stack sx={{ alignItems: "center" }}>
                            <FocusVisibleButton
                                variant="text"
                                onClick={router.back}
                            >
                                {t("go_back")}
                            </FocusVisibleButton>
                        </Stack>
                    </Stack>
                </ContentsPaper>
            </CenteredFill>
        </Stack>
    );
};

const ContentsPaper = styled(Paper)(({ theme }) => ({
    marginBlock: theme.spacing(2),
    padding: theme.spacing(4, 2),
    // Wide enough to fit the QR code secret in one line under default settings.
    width: "min(440px, 95vw)",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(4),
}));

export default Page;
