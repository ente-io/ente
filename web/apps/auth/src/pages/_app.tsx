import { accountLogout } from "@/accounts/services/logout";
import { clientPackageName, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { LoadingOverlay } from "@/base/components/loaders";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { useAttributedMiniDialog } from "@/base/components/utils/dialog";
import { useSetupI18n, useSetupLogs } from "@/base/components/utils/hooks-app";
import { THEME_COLOR, getTheme } from "@/base/components/utils/theme";
import { logStartupBanner } from "@/base/log-web";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    getData,
    migrateKVToken,
} from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { AppContext } from "types/context";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const router = useRouter();
    const [loading, setLoading] = useState(false);

    const isI18nReady = useSetupI18n();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
        const user = getData(LS_KEYS.USER) as User | undefined | null;
        void migrateKVToken(user);
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
    }, []);

    useEffect(() => {
        router.events.on("routeChangeStart", (url: string) => {
            const newPathname = url.split("?")[0];
            if (window.location.pathname !== newPathname) {
                setLoading(true);
            }
        });

        router.events.on("routeChangeComplete", () => {
            setLoading(false);
        });
    }, [router]);

    const logout = useCallback(() => {
        void accountLogout().then(() => window.location.replace("/"));
    }, []);

    const appContext = useMemo(
        () => ({
            logout,
            showMiniDialog,
            themeColor,
            setThemeColor,
        }),
        [logout, showMiniDialog, themeColor, setThemeColor],
    );

    const title = isI18nReady ? t("title_auth") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(themeColor, "auth")}>
                <CssBaseline enableColorScheme />

                <AttributedMiniDialog {...miniDialogProps} />

                <AppContext.Provider value={appContext}>
                    {(loading || !isI18nReady) && <LoadingOverlay />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
