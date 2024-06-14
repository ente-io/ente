import { CustomHead } from "@/next/components/Head";
import { setupI18n } from "@/next/i18n";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { appTitle, type AppName } from "@/next/types/app";
import { PAGES } from "@ente/accounts/constants/pages";
import { accountLogout } from "@ente/accounts/services/logout";
import { Overlay } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { AppNavbar } from "@ente/shared/components/Navbar/app";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { AppContext } from "components/context";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";

import "styles/global.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    const appName: AppName = "accounts";

    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);

    const [showNavbar, setShowNavbar] = useState(false);

    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] = useState<
        DialogBoxAttributesV2 | undefined
    >();

    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);

    useEffect(() => {
        setDialogBoxV2View(true);
    }, [dialogBoxAttributeV2]);

    const isMobile = useMediaQuery("(max-width: 428px)");

    const router = useRouter();

    const [themeColor] = useLocalState(LS_KEYS.THEME, THEME_COLOR.DARK);

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    const closeDialogBoxV2 = () => setDialogBoxV2View(false);

    const theme = getTheme(themeColor, "photos");

    const logout = useCallback(() => {
        void accountLogout().then(() => router.push(PAGES.ROOT));
    }, [router]);

    const appContext = {
        appName,
        logout,
        showNavBar: setShowNavbar,
        isMobile,
        setDialogBoxAttributesV2,
    };

    const title = isI18nReady
        ? t("title", { context: "accounts" })
        : appTitle[appName];

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={theme}>
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
