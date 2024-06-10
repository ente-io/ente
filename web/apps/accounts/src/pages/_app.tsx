import { CustomHead } from "@/next/components/Head";
import { setClientPackageForAuthenticatedRequests } from "@/next/http";
import { setupI18n } from "@/next/i18n";
import { logUnhandledErrorsAndRejections } from "@/next/log-web";
import { appTitle, type AppName, type BaseAppContextT } from "@/next/types/app";
import { ensure } from "@/utils/ensure";
import { PAGES } from "@ente/accounts/constants/pages";
import { accountLogout } from "@ente/accounts/services/logout";
import { Overlay } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { AppNavbar } from "@ente/shared/components/Navbar/app";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import { createContext, useContext, useEffect, useState } from "react";
import "styles/global.css";

/** The accounts app has no extra properties on top of the base context. */
type AppContextT = BaseAppContextT;

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/** Utility hook to reduce amount of boilerplate in account related pages. */
export const useAppContext = () => ensure(useContext(AppContext));

export default function App({ Component, pageProps }: AppProps) {
    const appName: AppName = "accounts";

    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);

    const [showNavbar, setShowNavBar] = useState(false);

    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] = useState<
        DialogBoxAttributesV2 | undefined
    >();

    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);

    useEffect(() => {
        setDialogBoxV2View(true);
    }, [dialogBoxAttributeV2]);

    const showNavBar = (show: boolean) => setShowNavBar(show);

    const isMobile = useMediaQuery("(max-width: 428px)");

    const router = useRouter();

    const [themeColor] = useLocalState(LS_KEYS.THEME, THEME_COLOR.DARK);

    useEffect(() => {
        setupI18n().finally(() => setIsI18nReady(true));
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    const setupPackageName = () => {
        const clientPackage = localStorage.getItem("clientPackage");
        if (!clientPackage) return;
        setClientPackageForAuthenticatedRequests(clientPackage);
        HTTPService.setHeaders({
            "X-Client-Package": clientPackage,
        });
    };

    useEffect(() => {
        router.events.on("routeChangeComplete", setupPackageName);
        return () => {
            router.events.off("routeChangeComplete", setupPackageName);
        };
    }, [router.events]);

    const closeDialogBoxV2 = () => setDialogBoxV2View(false);

    const theme = getTheme(themeColor, "photos");

    const logout = () => {
        void accountLogout().then(() => router.push(PAGES.ROOT));
    };

    const appContext = {
        appName,
        logout,
        showNavBar,
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
                    attributes={dialogBoxAttributeV2 as any}
                />

                <AppContext.Provider value={appContext}>
                    {!isI18nReady && (
                        <Overlay
                            sx={(theme) => ({
                                display: "flex",
                                justifyContent: "center",
                                alignItems: "center",
                                zIndex: 2000,
                                backgroundColor: (theme as any).colors
                                    .background.base,
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
}
