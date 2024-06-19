import { CustomHead } from "@/next/components/Head";
import { disableDiskLogs } from "@/next/log";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { appTitle } from "@/next/types/app";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, ThemeProvider } from "@mui/material";
import type { AppProps } from "next/app";
import React, { useEffect } from "react";

import "styles/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useEffect(() => {
        disableDiskLogs();
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    return (
        <>
            <CustomHead title={appTitle.photos} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, "photos")}>
                <CssBaseline enableColorScheme />
                <Component {...pageProps} />
            </ThemeProvider>
        </>
    );
};

export default App;
