import "@fontsource-variable/inter";
import { CssBaseline, Typography } from "@mui/material";
import { styled, ThemeProvider } from "@mui/material/styles";
import { savedLocalUser } from "ente-accounts/services/accounts-db";
import { CenteredRow } from "ente-base/components/containers";
import { accountLogout } from "ente-accounts/services/logout";
import { isDesktop, staticAppTitle } from "ente-base/app";
import { CustomHead } from "ente-base/components/Head";
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
import { authTheme } from "ente-base/components/utils/theme";
import { BaseContext, deriveBaseContext } from "ente-base/context";
import { logStartupBanner } from "ente-base/log-web";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useCallback, useEffect, useMemo } from "react";

import "styles/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const isI18nReady = useSetupI18n();
    const isChangingRoute = useIsRouteChangeInProgress();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();

    useEffect(() => {
        logStartupBanner(savedLocalUser()?.id);
    }, []);

    const logout = useCallback(() => {
        void accountLogout().then(() => window.location.replace("/"));
    }, []);

    const baseContext = useMemo(
        () => deriveBaseContext({ logout, showMiniDialog }),
        [logout, showMiniDialog],
    );

    const title = isI18nReady ? t("title_auth") : staticAppTitle;

    return (
        <ThemeProvider theme={authTheme}>
            <CustomHead {...{ title }} />
            <CssBaseline enableColorScheme />
            <AttributedMiniDialog {...miniDialogProps} />

            {isDesktop && <WindowTitlebar>{title}</WindowTitlebar>}
            <BaseContext value={baseContext}>
                {!isI18nReady ? (
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

const WindowTitlebar: React.FC<React.PropsWithChildren> = ({ children }) => (
    <WindowTitlebarArea>
        <Typography variant="small" sx={{ mt: "2px", fontWeight: "bold" }}>
            {children}
        </Typography>
    </WindowTitlebarArea>
);

// See: [Note: Customize the desktop title bar]
const WindowTitlebarArea = styled(CenteredRow)`
    width: 100%;
    height: env(titlebar-area-height, 30px /* fallback */);
    /* LoadingIndicator is 100vh, so resist shrinking when shown with it. */
    flex-shrink: 0;
    /* Allow using the titlebar to drag the window. */
    app-region: drag;
`;
