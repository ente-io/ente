import { accountLogout } from "@/accounts/services/logout";
import type { AccountsContextT } from "@/accounts/types/context";
import { clientPackageName, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { AppNavbar } from "@/base/components/Navbar";
import { setupI18n } from "@/base/i18n";
import {
    logStartupBanner,
    logUnhandledErrorsAndRejections,
} from "@/base/log-web";
import { ensure } from "@/utils/ensure";
import { Overlay } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { MessageContainer } from "@ente/shared/components/MessageContainer";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    getData,
    migrateKVToken,
} from "@ente/shared/storage/localStorage";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import type { User } from "@ente/shared/user/types";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import React, {
    createContext,
    useContext,
    useEffect,
    useRef,
    useState,
} from "react";
import LoadingBar, { type LoadingBarRef } from "react-top-loading-bar";
import "../../public/css/global.css";

/**
 * Properties available via {@link AppContext} to the Auth app's React tree.
 */
type AppContextT = AccountsContextT & {
    startLoading: () => void;
    finishLoading: () => void;
    themeColor: THEME_COLOR;
    setThemeColor: (themeColor: THEME_COLOR) => void;
    somethingWentWrong: () => void;
};

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/** Utility hook to reduce amount of boilerplate in account related pages. */
export const useAppContext = () => ensure(useContext(AppContext));

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== "undefined" && !window.navigator.onLine,
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const isLoadingBarRunning = useRef<boolean>(false);
    const loadingBar = useRef<LoadingBarRef>(null);
    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] = useState<
        DialogBoxAttributesV2 | undefined
    >();
    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
        const user = getData(LS_KEYS.USER) as User | undefined | null;
        migrateKVToken(user);
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
        logUnhandledErrorsAndRejections(true);
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);

    useEffect(() => {
        router.events.on("routeChangeStart", (url: string) => {
            const newPathname = url.split("?")[0];
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

    const logout = () => {
        void accountLogout().then(() => router.push("/"));
    };

    const appContext = {
        logout,
        showNavBar,
        setDialogBoxAttributesV2,
        startLoading,
        finishLoading,
        themeColor,
        setThemeColor,
        somethingWentWrong,
    };

    const title = isI18nReady ? t("title_auth") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(themeColor, "auth")}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar />}
                <MessageContainer>
                    {isI18nReady && offline && t("OFFLINE_MSG")}
                </MessageContainer>

                <LoadingBar color="#51cd7c" ref={loadingBar} />

                <DialogBoxV2
                    sx={{ zIndex: 1600 }}
                    open={dialogBoxV2View}
                    onClose={closeDialogBoxV2}
                    attributes={dialogBoxAttributeV2}
                />

                <AppContext.Provider value={appContext}>
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
};

export default App;
