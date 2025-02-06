import { staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { LoadingIndicator } from "@/base/components/loaders";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { useAttributedMiniDialog } from "@/base/components/utils/dialog";
import { useSetupI18n, useSetupLogs } from "@/base/components/utils/hooks-app";
import { photosTheme } from "@/base/components/utils/theme";
import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useMemo } from "react";
import { AppContext } from "../types/context";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs({ disableDiskLogs: true });

    const isI18nReady = useSetupI18n();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();

    const appContext = useMemo(() => ({ showMiniDialog }), [showMiniDialog]);

    const title = isI18nReady ? t("title_accounts") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={photosTheme}>
                <CssBaseline enableColorScheme />
                <AttributedMiniDialog {...miniDialogProps} />

                <AppContext.Provider value={appContext}>
                    {!isI18nReady && <LoadingIndicator />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
