import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { savedLocalUser } from "ente-accounts-rs/services/accounts-db";
import { accountLogout } from "ente-accounts-rs/services/logout";
import { LockerHead } from "components/LockerHead";
import {
    LoadingIndicator,
    TranslucentLoadingOverlay,
} from "ente-base/components/loaders";
import { AttributedMiniDialog } from "ente-base/components/MiniDialog";
import { useAttributedMiniDialog } from "ente-base/components/utils/dialog";
import {
    useIsRouteChangeInProgress,
    useSetupI18n,
    useSetupLogs,
} from "ente-base/components/utils/hooks-app";
import { lockerTheme } from "ente-base/components/utils/theme";
import { BaseContext, deriveBaseContext } from "ente-base/context";
import { logStartupBanner } from "ente-base/log-web";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useMemo } from "react";

const publicRoutes = new Set([
    "/login",
    "/signup",
    "/verify",
    "/recover",
    "/change-password",
    "/change-email",
    "/credentials",
    "/generate",
    "/two-factor/verify",
    "/two-factor/setup",
    "/two-factor/recover",
    "/passkeys/finish",
    "/passkeys/recover",
]);

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const router = useRouter();
    const isI18nReady = useSetupI18n();
    const isChangingRoute = useIsRouteChangeInProgress();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const isLoggedIn = !!savedLocalUser();
    const requiresLogin = !publicRoutes.has(router.pathname);

    useEffect(() => {
        logStartupBanner(savedLocalUser()?.id);
    }, []);

    useEffect(() => {
        if (!router.isReady || isLoggedIn || !requiresLogin) return;
        void router.replace("/login");
    }, [isLoggedIn, requiresLogin, router]);

    const logout = useCallback(() => {
        void accountLogout().then(() => window.location.replace("/login"));
    }, []);

    const baseContext = useMemo(
        () => deriveBaseContext({ logout, showMiniDialog }),
        [logout, showMiniDialog],
    );

    return (
        <ThemeProvider theme={lockerTheme}>
            <LockerHead />
            <CssBaseline enableColorScheme />
            <AttributedMiniDialog {...miniDialogProps} />

            <BaseContext value={baseContext}>
                {!isI18nReady || (!isLoggedIn && requiresLogin) ? (
                    <LoadingIndicator />
                ) : (
                    <>
                        {isChangingRoute && <TranslucentLoadingOverlay />}
                        <Component {...pageProps} />
                    </>
                )}
            </BaseContext>
        </ThemeProvider>
    );
};

export default App;
