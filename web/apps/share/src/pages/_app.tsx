import "@fontsource-variable/inter";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { staticAppTitle } from "ente-base/app";
import { CustomHead } from "ente-base/components/Head";
import { useSetupLogs } from "ente-base/components/utils/hooks-app";
import { shareTheme } from "ente-base/components/utils/theme";
import type { AppProps } from "next/app";
import React from "react";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs({ disableDiskLogs: true });

    // Detect system color scheme preference and set as default mode
    const prefersDarkMode = useMediaQuery("(prefers-color-scheme: dark)");
    const defaultMode = prefersDarkMode ? "dark" : "light";

    return (
        <ThemeProvider theme={shareTheme} defaultMode={defaultMode}>
            <CustomHead title={staticAppTitle} />
            <CssBaseline enableColorScheme />
            <Component {...pageProps} />
        </ThemeProvider>
    );
};

export default App;
