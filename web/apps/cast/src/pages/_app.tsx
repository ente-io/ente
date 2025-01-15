import { staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { useSetupLogs } from "@/base/components/utils/hooks-app";
import { photosTheme } from "@/base/components/utils/theme";
import "@fontsource-variable/inter";
import { CssBaseline, ThemeProvider } from "@mui/material";
import type { AppProps } from "next/app";
import React from "react";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs({ disableDiskLogs: true });

    return (
        <>
            <CustomHead title={staticAppTitle} />

            <ThemeProvider theme={photosTheme}>
                <CssBaseline enableColorScheme />
                <Component {...pageProps} />
            </ThemeProvider>
        </>
    );
};

export default App;
