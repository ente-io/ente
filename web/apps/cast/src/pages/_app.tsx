import { CustomHead } from "@/next/components/Head";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { APPS, APP_TITLES } from "@ente/shared/apps/constants";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, ThemeProvider } from "@mui/material";
import type { AppProps } from "next/app";
import { useEffect } from "react";

import "styles/global.css";

export default function App({ Component, pageProps }: AppProps) {
    useEffect(() => {
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    return (
        <>
            <CustomHead title={APP_TITLES.get(APPS.PHOTOS)} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, APPS.PHOTOS)}>
                <CssBaseline enableColorScheme />
                <Component {...pageProps} />
            </ThemeProvider>
        </>
    );
}
