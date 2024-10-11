import { staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { AppNavbar } from "@/base/components/Navbar";
import { useAttributedMiniDialog } from "@/base/components/utils/mini-dialog";
import { setupI18n } from "@/base/i18n";
import { disableDiskLogs } from "@/base/log";
import { logUnhandledErrorsAndRejections } from "@/base/log-web";
import { Overlay } from "@ente/shared/components/Container";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useEffect, useMemo, useState } from "react";
import { AppContext } from "../types/context";

import "styles/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [showNavbar, setShowNavbar] = useState(false);
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();

    useEffect(() => {
        disableDiskLogs();
        void setupI18n().finally(() => setIsI18nReady(true));
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    const appContext = useMemo(
        () => ({
            showNavBar: setShowNavbar,
            showMiniDialog,
        }),
        [showMiniDialog],
    );

    const title = isI18nReady ? t("title_accounts") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, "photos")}>
                <CssBaseline enableColorScheme />
                <AttributedMiniDialog {...miniDialogProps} />

                <AppContext.Provider value={appContext}>
                    {!isI18nReady && (
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
                    {showNavbar && <AppNavbar />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
