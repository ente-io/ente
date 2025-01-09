import { accountLogout } from "@/accounts/services/logout";
import { clientPackageName, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Overlay } from "@/base/components/mui/Container";
import { AppNavbar } from "@/base/components/Navbar";
import { useAttributedMiniDialog } from "@/base/components/utils/dialog";
import { setupI18n } from "@/base/i18n";
import {
    logStartupBanner,
    logUnhandledErrorsAndRejections,
} from "@/base/log-web";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    getData,
    migrateKVToken,
} from "@ente/shared/storage/localStorage";
import { THEME_COLOR, getTheme } from "@ente/shared/themes";
import type { User } from "@ente/shared/user/types";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { AppContext } from "types/context";

import "../../public/css/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [showNavbar, setShowNavBar] = useState(false);

    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
        const user = getData(LS_KEYS.USER) as User | undefined | null;
        void migrateKVToken(user);
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
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
            showNavBar: (show: boolean) => setShowNavBar(show),
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
                {showNavbar && <AppNavbar />}

                <AttributedMiniDialog {...miniDialogProps} />

                <AppContext.Provider value={appContext}>
                    {(loading || !isI18nReady) && (
                        <Overlay
                            sx={(theme) => ({
                                display: "flex",
                                justifyContent: "center",
                                alignItems: "center",
                                zIndex: 2000,
                                backgroundColor: theme.colors.background.base,
                            })}
                        >
                            <ActivityIndicator />
                        </Overlay>
                    )}
                    {isI18nReady && (
                        <Component setLoading={setLoading} {...pageProps} />
                    )}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
