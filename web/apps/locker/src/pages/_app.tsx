import "@fontsource-variable/inter";
import { CssBaseline, ThemeProvider } from "@mui/material";
import { staticAppTitle } from "ente-base/app";
import { CustomHead } from "ente-base/components/Head";
import { useSetupLogs } from "ente-base/components/utils/hooks-app";
import { lockerTheme } from "ente-base/components/utils/theme";
import type { AppProps } from "next/app";
import React from "react";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs({ disableDiskLogs: true });

    // We don't provide BaseContext. Nothing in the cast app needs it yet.

    return (
        <ThemeProvider theme={lockerTheme}>
            <CustomHead title={staticAppTitle} />
            <CssBaseline enableColorScheme />
            <Component {...pageProps} />
        </ThemeProvider>
    );
};

export default App;
