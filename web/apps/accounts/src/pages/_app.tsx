import { staticAppTitle } from "@/next/app";
import { CustomHead } from "@/next/components/Head";
import { setupI18n } from "@/next/i18n";
import { disableDiskLogs } from "@/next/log";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { Overlay } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { AppNavbar } from "@ente/shared/components/Navbar/app";
import { clearData } from "@ente/shared/storage/localStorage";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import React, { useEffect, useState } from "react";
import { AppContext } from "../types/context";

import "styles/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [showNavbar, setShowNavbar] = useState(false);
    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] = useState<
        DialogBoxAttributesV2 | undefined
    >();
    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);

    const isMobile = useMediaQuery("(max-width: 428px)");

    useEffect(() => {
        disableDiskLogs();
        // The accounts app has no local state, but some older builds might've
        // leftover some scraps. Clear it out.
        //
        // This code added on 1 July 2024, can be removed soon since this data
        // was never saved before this was released (tag: Migration).
        clearData();
        void setupI18n().finally(() => setIsI18nReady(true));
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    useEffect(() => {
        setDialogBoxV2View(true);
    }, [dialogBoxAttributeV2]);

    const closeDialogBoxV2 = () => setDialogBoxV2View(false);

    const appContext = {
        showNavBar: setShowNavbar,
        isMobile,
        setDialogBoxAttributesV2,
    };

    const title = isI18nReady
        ? t("title", { context: "accounts" })
        : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(THEME_COLOR.DARK, "photos")}>
                <CssBaseline enableColorScheme />
                <DialogBoxV2
                    sx={{ zIndex: 1600 }}
                    open={dialogBoxV2View}
                    onClose={closeDialogBoxV2}
                    attributes={dialogBoxAttributeV2}
                />

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
                            <EnteSpinner />
                        </Overlay>
                    )}
                    {showNavbar && <AppNavbar isMobile={isMobile} />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
};

export default App;
