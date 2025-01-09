import { staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { LoadingOverlay } from "@/base/components/LoadingOverlay";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { AppNavbar } from "@/base/components/Navbar";
import { useAttributedMiniDialog } from "@/base/components/utils/dialog";
import { getTheme, THEME_COLOR } from "@/base/components/utils/theme";
import { setupI18n } from "@/base/i18n";
import { disableDiskLogs } from "@/base/log";
import { logUnhandledErrorsAndRejections } from "@/base/log-web";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useEffect, useMemo, useState } from "react";
import { AppContext } from "../types/context";

import "@fontsource-variable/inter";
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
                    {!isI18nReady && <LoadingOverlay />}
                    {showNavbar && <AppNavbar />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
