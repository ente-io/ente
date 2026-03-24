import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { savedLocalUser } from "ente-accounts-rs/services/accounts-db";
import { accountLogout } from "ente-accounts-rs/services/logout";
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
import Head from "next/head";
import React, { useCallback, useEffect, useMemo } from "react";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const isI18nReady = useSetupI18n();
    const isChangingRoute = useIsRouteChangeInProgress();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();

    useEffect(() => {
        logStartupBanner(savedLocalUser()?.id);
    }, []);

    const logout = useCallback(() => {
        void accountLogout().then(() => window.location.replace("/login"));
    }, []);

    const baseContext = useMemo(
        () => deriveBaseContext({ logout, showMiniDialog }),
        [logout, showMiniDialog],
    );

    return (
        <ThemeProvider theme={lockerTheme}>
            <Head>
                <title>
                    Ente Locker - Safe space for your most important documents
                </title>
                <meta
                    name="description"
                    content="Store your important documents and credentials. Share them with trusted contacts or pass them on in emergencies."
                />
                <meta name="twitter:site" content="@enteio" />
                <meta property="og:type" content="website" />
                <meta property="og:url" content="https://locker.ente.io" />
                <meta
                    property="og:title"
                    content="Ente Locker - Safe space for your most important documents"
                />
                <meta
                    property="og:description"
                    content="Store your important documents and credentials. Share them with trusted contacts or pass them on in emergencies."
                />
                <meta
                    property="og:image"
                    content="https://ente.io/static/locker-meta-preview-0db171b861bdbc3262b8289e40cf7efe.png"
                />
                <meta
                    property="og:image:secure_url"
                    content="https://ente.io/static/locker-meta-preview-0db171b861bdbc3262b8289e40cf7efe.png"
                />
                <meta property="og:image:type" content="image/png" />
                <meta property="og:image:width" content="1200" />
                <meta property="og:image:height" content="630" />
                <meta property="og:site_name" content="Locker" />
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:url" content="https://locker.ente.io" />
                <meta
                    name="twitter:title"
                    content="Ente Locker - Safe space for your most important documents"
                />
                <meta
                    name="twitter:description"
                    content="Store your important documents and credentials. Share them with trusted contacts or pass them on in emergencies."
                />
                <meta
                    name="twitter:image"
                    content="https://ente.io/static/locker-meta-preview-0db171b861bdbc3262b8289e40cf7efe.png"
                />
                <meta name="theme-color" content="#1071FF" />
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1"
                />
                <meta
                    name="referrer"
                    content="strict-origin-when-cross-origin"
                />
            </Head>
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
