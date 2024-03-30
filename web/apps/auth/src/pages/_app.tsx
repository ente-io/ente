import { setupI18n } from "@/ui/i18n";
import {
    APPS,
    APP_TITLES,
    CLIENT_PACKAGE_NAMES,
} from "@ente/shared/apps/constants";
import { Overlay } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import {
    DialogBoxAttributesV2,
    SetDialogBoxAttributesV2,
} from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { MessageContainer } from "@ente/shared/components/MessageContainer";
import AppNavbar from "@ente/shared/components/Navbar/app";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import {
    clearLogsIfLocalStorageLimitExceeded,
    logStartupMessage,
} from "@ente/shared/logging/web";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import { SetTheme } from "@ente/shared/themes/types";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import { AppProps } from "next/app";
import Head from "next/head";
import { useRouter } from "next/router";
import { createContext, useEffect, useRef, useState } from "react";
import LoadingBar from "react-top-loading-bar";
import "../../public/css/global.css";

type AppContextType = {
    showNavBar: (show: boolean) => void;
    startLoading: () => void;
    finishLoading: () => void;
    isMobile: boolean;
    themeColor: THEME_COLOR;
    setThemeColor: SetTheme;
    somethingWentWrong: () => void;
    setDialogBoxAttributesV2: SetDialogBoxAttributesV2;
};

export const AppContext = createContext<AppContextType>(null);

export default function App(props: AppProps) {
    const { Component, pageProps } = props;
    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== "undefined" && !window.navigator.onLine,
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const isLoadingBarRunning = useRef(false);
    const loadingBar = useRef(null);
    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] =
        useState<DialogBoxAttributesV2>();
    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);
    const isMobile = useMediaQuery("(max-width:428px)");
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
        //setup i18n
        setupI18n().finally(() => setIsI18nReady(true));
        // set client package name in headers
        HTTPService.setHeaders({
            "X-Client-Package": CLIENT_PACKAGE_NAMES.get(APPS.AUTH),
        });
        // setup logging
        clearLogsIfLocalStorageLimitExceeded();
        logStartupMessage(APPS.AUTH);
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);

    useEffect(() => {
        router.events.on("routeChangeStart", (url: string) => {
            const newPathname = url.split("?")[0] as PAGES;
            if (window.location.pathname !== newPathname) {
                setLoading(true);
            }
        });

        router.events.on("routeChangeComplete", () => {
            setLoading(false);
        });

        window.addEventListener("online", setUserOnline);
        window.addEventListener("offline", setUserOffline);

        return () => {
            window.removeEventListener("online", setUserOnline);
            window.removeEventListener("offline", setUserOffline);
        };
    }, []);

    useEffect(() => {
        setDialogBoxV2View(true);
    }, [dialogBoxAttributeV2]);

    const showNavBar = (show: boolean) => setShowNavBar(show);

    const startLoading = () => {
        !isLoadingBarRunning.current && loadingBar.current?.continuousStart();
        isLoadingBarRunning.current = true;
    };
    const finishLoading = () => {
        setTimeout(() => {
            isLoadingBarRunning.current && loadingBar.current?.complete();
            isLoadingBarRunning.current = false;
        }, 100);
    };

    const closeDialogBoxV2 = () => setDialogBoxV2View(false);

    const somethingWentWrong = () =>
        setDialogBoxAttributesV2({
            title: t("ERROR"),
            close: { variant: "critical" },
            content: t("UNKNOWN_ERROR"),
        });

    return (
        <>
            <Head>
                <title>
                    {isI18nReady
                        ? t("TITLE", { context: APPS.AUTH })
                        : APP_TITLES.get(APPS.AUTH)}
                </title>
                <meta
                    name="viewport"
                    content="initial-scale=1, width=device-width"
                />
            </Head>

            <ThemeProvider theme={getTheme(themeColor, APPS.AUTH)}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar isMobile={isMobile} />}
                <MessageContainer>
                    {offline && t("OFFLINE_MSG")}
                </MessageContainer>

                <LoadingBar color="#51cd7c" ref={loadingBar} />

                <DialogBoxV2
                    sx={{ zIndex: 1600 }}
                    open={dialogBoxV2View}
                    onClose={closeDialogBoxV2}
                    attributes={dialogBoxAttributeV2}
                />

                <AppContext.Provider
                    value={{
                        showNavBar,
                        startLoading,
                        finishLoading,
                        isMobile,
                        themeColor,
                        setThemeColor,
                        somethingWentWrong,
                        setDialogBoxAttributesV2,
                    }}
                >
                    {(loading || !isI18nReady) && (
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
                    {isI18nReady && (
                        <Component setLoading={setLoading} {...pageProps} />
                    )}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
}
