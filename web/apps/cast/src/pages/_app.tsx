import { CustomHead } from "@/next/components/Head";
import { disableDiskLogs } from "@/next/log";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { appTitle } from "@/next/types/app";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, ThemeProvider } from "@mui/material";
import type { AppProps } from "next/app";
import { useEffect } from "react";

import "styles/global.css";

export default function App({ Component, pageProps }: AppProps) {
    useEffect(() => {
        disableDiskLogs();
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    return (
        <>
            <CustomHead title={appTitle["photos"]} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, "photos")}>
                <CssBaseline enableColorScheme />
                <Component {...pageProps} />
            </ThemeProvider>
        </>
    );
}
