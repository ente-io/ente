import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { accountLogout } from "ente-accounts/services/logout";
import { clientPackageName, staticAppTitle } from "ente-base/app";
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
import HTTPService from "ente-shared/network/HTTPService";
import { getData } from "ente-shared/storage/localStorage";
import type { User } from "ente-shared/user/types";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useCallback, useEffect, useMemo } from "react";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const isI18nReady = useSetupI18n();
    const isChangingRoute = useIsRouteChangeInProgress();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();

    useEffect(() => {
        const user = getData("user") as User | undefined | null;
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
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
