import { TwoFactorSetup } from "@/accounts/components/two-factor/TwoFactorSetup";
import { Verify2FACodeForm } from "@/accounts/components/Verify2FACodeForm";
import { appHomeRoute } from "@/accounts/services/redirect";
import type { TwoFactorSecret } from "@/accounts/services/user";
import { enableTwoFactor, setupTwoFactor } from "@/accounts/services/user";
import { CenteredFill } from "@/base/components/containers";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { encryptWithRecoveryKey } from "@ente/shared/crypto/helpers";
import { getData, LS_KEYS, setLSUser } from "@ente/shared/storage/localStorage";
import { Paper, Stack, styled, Typography } from "@mui/material";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";

export type SetupMode = "qrCode" | "manualCode";

const Page: React.FC = () => {
    const [twoFactorSecret, setTwoFactorSecret] = useState<
        TwoFactorSecret | undefined
    >();

    const router = useRouter();

    useEffect(() => {
        if (twoFactorSecret) return; // HMR
        void setupTwoFactor().then(setTwoFactorSecret);
    }, []);

    const handleSubmit = useCallback(async (otp: string) => {
        const recoveryEncryptedTwoFactorSecret = await encryptWithRecoveryKey(
            twoFactorSecret!.secretCode,
        );
        await enableTwoFactor(otp, recoveryEncryptedTwoFactorSecret);
        await setLSUser({
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: true,
        });
    }, []);

    const handleSuccess = useCallback(() => {
        void router.push(appHomeRoute);
    }, [router]);

    return (
        <Stack sx={{ minHeight: "100svh" }}>
            <CenteredFill>
                <ContentsPaper>
                    <Typography variant="h5" sx={{ textAlign: "center" }}>
                        {t("two_factor")}
                    </Typography>
                    <Stack>
                        <TwoFactorSetup twoFactorSecret={twoFactorSecret} />
                        <Verify2FACodeForm
                            onSubmit={handleSubmit}
                            onSuccess={handleSuccess}
                            submitButtonText={t("enable")}
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

export default Page;

const ContentsPaper = styled(Paper)(({ theme }) => ({
    marginBlock: theme.spacing(2),
    padding: theme.spacing(4, 2),
    // Wide enough to fit the QR code secret in one line under default settings.
    width: "min(440px, 95vw)",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(4),
}));
