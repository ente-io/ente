import { CustomHead } from "@/next/components/Head";
import { setAppNameForAuthenticatedRequests } from "@/next/http";
import { setupI18n } from "@/next/i18n";
import log from "@/next/log";
import {
    logStartupBanner,
    logUnhandledErrorsAndRejections,
} from "@/next/log-web";
import {
    appTitle,
    clientPackageName,
    type AppName,
    type BaseAppContextT,
} from "@/next/types/app";
import { AppUpdate } from "@/next/types/ipc";
import { ensure } from "@/utils/ensure";
import { Overlay } from "@ente/shared/components/Container";
import DialogBox from "@ente/shared/components/DialogBox";
import {
    DialogBoxAttributes,
    SetDialogBoxAttributes,
} from "@ente/shared/components/DialogBox/types";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import type { DialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { MessageContainer } from "@ente/shared/components/MessageContainer";
import { AppNavbar } from "@ente/shared/components/Navbar/app";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import {
    getLocalMapEnabled,
    getToken,
    setLocalMapEnabled,
} from "@ente/shared/storage/localStorage/helpers";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import type { User } from "@ente/shared/user/types";
import ArrowForward from "@mui/icons-material/ArrowForward";
import { CssBaseline, useMediaQuery } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import Notification from "components/Notification";
import { REDIRECTS } from "constants/redirects";
import { t } from "i18next";
import isElectron from "is-electron";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import "photoswipe/dist/photoswipe.css";
import { createContext, useContext, useEffect, useRef, useState } from "react";
import LoadingBar from "react-top-loading-bar";
import DownloadManager from "services/download";
import { resumeExportsIfNeeded } from "services/export";
import {
    isFaceIndexingEnabled,
    setIsFaceIndexingEnabled,
} from "services/face/indexer";
import mlWorkManager from "services/face/mlWorkManager";
import { photosLogout } from "services/logout";
import {
    getFamilyPortalRedirectURL,
    getRoadmapRedirectURL,
    updateMapEnabledStatus,
} from "services/userService";
import "styles/global.css";
import {
    NotificationAttributes,
    SetNotificationAttributes,
} from "types/Notification";
import {
    getUpdateAvailableForDownloadMessage,
    getUpdateReadyToInstallMessage,
} from "utils/ui";

const redirectMap = new Map([
    [REDIRECTS.ROADMAP, getRoadmapRedirectURL],
    [REDIRECTS.FAMILIES, getFamilyPortalRedirectURL],
]);

/**
 * Properties available via the {@link AppContext} to the Photos app's React
 * tree.
 */
type AppContextT = BaseAppContextT & {
    mlSearchEnabled: boolean;
    mapEnabled: boolean;
    updateMlSearchEnabled: (enabled: boolean) => Promise<void>;
    updateMapEnabled: (enabled: boolean) => Promise<void>;
    startLoading: () => void;
    finishLoading: () => void;
    closeMessageDialog: () => void;
    setDialogMessage: SetDialogBoxAttributes;
    setNotificationAttributes: SetNotificationAttributes;
    watchFolderView: boolean;
    setWatchFolderView: (isOpen: boolean) => void;
    watchFolderFiles: FileList;
    setWatchFolderFiles: (files: FileList) => void;
    themeColor: THEME_COLOR;
    setThemeColor: (themeColor: THEME_COLOR) => void;
    somethingWentWrong: () => void;
    isCFProxyDisabled: boolean;
    setIsCFProxyDisabled: (disabled: boolean) => void;
};

/** The React {@link Context} available to all pages. */
export const AppContext = createContext<AppContextT | undefined>(undefined);

/** Utility hook to reduce amount of boilerplate in account related pages. */
export const useAppContext = () => ensure(useContext(AppContext));

export default function App({ Component, pageProps }: AppProps) {
    const appName: AppName = "photos";

    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== "undefined" && !window.navigator.onLine,
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const [redirectName, setRedirectName] = useState<string>(null);
    const [mlSearchEnabled, setMlSearchEnabled] = useState(false);
    const [mapEnabled, setMapEnabled] = useState(false);
    const isLoadingBarRunning = useRef(false);
    const loadingBar = useRef(null);
    const [dialogMessage, setDialogMessage] = useState<DialogBoxAttributes>();
    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] = useState<
        DialogBoxAttributesV2 | undefined
    >();
    useState<DialogBoxAttributes>(null);
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const isMobile = useMediaQuery("(max-width: 428px)");
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );
    const [isCFProxyDisabled, setIsCFProxyDisabled] = useLocalState(
        LS_KEYS.CF_PROXY_DISABLED,
        false,
    );

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
        const userId = (getData(LS_KEYS.USER) as User)?.id;
        logStartupBanner(appName, userId);
        logUnhandledErrorsAndRejections(true);
        setAppNameForAuthenticatedRequests(appName);
        HTTPService.setHeaders({
            "X-Client-Package": clientPackageName(appName),
        });
        return () => logUnhandledErrorsAndRejections(false);
    }, []);

    useEffect(() => {
        const electron = globalThis.electron;
        if (!electron) return;

        // Attach various listeners for events sent to us by the Node.js layer.
        // This is for events that we should listen for always, not just when
        // the user is logged in.

        const handleOpenURL = (url: string) => {
            if (url.startsWith("ente://app")) router.push(url);
            else log.info(`Ignoring unhandled open request for URL ${url}`);
        };

        const showUpdateDialog = (update: AppUpdate) => {
            if (update.autoUpdatable) {
                setDialogMessage(getUpdateReadyToInstallMessage(update));
            } else {
                setNotificationAttributes({
                    endIcon: <ArrowForward />,
                    variant: "secondary",
                    message: t("UPDATE_AVAILABLE"),
                    onClick: () =>
                        setDialogMessage(
                            getUpdateAvailableForDownloadMessage(update),
                        ),
                });
            }
        };

        electron.onOpenURL(handleOpenURL);
        electron.onAppUpdateAvailable(showUpdateDialog);

        return () => {
            electron.onOpenURL(undefined);
            electron.onAppUpdateAvailable(undefined);
        };
    }, []);

    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        const loadMlSearchState = async () => {
            try {
                const enabled = await isFaceIndexingEnabled();
                setMlSearchEnabled(enabled);
                mlWorkManager.setMlSearchEnabled(enabled);
            } catch (e) {
                log.error("Error while loading mlSearchEnabled", e);
            }
        };
        loadMlSearchState();
    }, []);

    useEffect(() => {
        setMapEnabled(getLocalMapEnabled());
    }, []);

    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        const initExport = async () => {
            const token = getToken();
            if (!token) return;
            await DownloadManager.init(token);
            await resumeExportsIfNeeded();
        };
        initExport();
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);

    useEffect(() => {
        const redirectTo = async (redirect) => {
            if (
                redirectMap.has(redirect) &&
                typeof redirectMap.get(redirect) === "function"
            ) {
                const redirectAction = redirectMap.get(redirect);
                window.location.href = await redirectAction();
            } else {
                log.error(`invalid redirection ${redirect}`);
            }
        };

        const query = new URLSearchParams(window.location.search);
        const redirectName = query.get("redirect");
        if (redirectName) {
            const user = getData(LS_KEYS.USER);
            if (user?.token) {
                redirectTo(redirectName);
            } else {
                setRedirectName(redirectName);
            }
        }

        router.events.on("routeChangeStart", (url: string) => {
            const newPathname = url.split("?")[0] as PAGES;
            if (window.location.pathname !== newPathname) {
                setLoading(true);
            }

            if (redirectName) {
                const user = getData(LS_KEYS.USER);
                if (user?.token) {
                    redirectTo(redirectName);

                    // https://github.com/vercel/next.js/issues/2476#issuecomment-573460710
                    // eslint-disable-next-line no-throw-literal
                    throw "Aborting route change, redirection in process....";
                }
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
    }, [redirectName]);

    useEffect(() => {
        setMessageDialogView(true);
    }, [dialogMessage]);

    useEffect(() => {
        setDialogBoxV2View(true);
    }, [dialogBoxAttributeV2]);

    useEffect(() => {
        setNotificationView(true);
    }, [notificationAttributes]);

    const showNavBar = (show: boolean) => setShowNavBar(show);
    const updateMlSearchEnabled = async (enabled: boolean) => {
        try {
            await setIsFaceIndexingEnabled(enabled);
            setMlSearchEnabled(enabled);
            mlWorkManager.setMlSearchEnabled(enabled);
        } catch (e) {
            log.error("Error while updating mlSearchEnabled", e);
        }
    };

    const updateMapEnabled = async (enabled: boolean) => {
        try {
            await updateMapEnabledStatus(enabled);
            setLocalMapEnabled(enabled);
            setMapEnabled(enabled);
        } catch (e) {
            log.error("Error while updating mapEnabled", e);
        }
    };

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

    const closeMessageDialog = () => setMessageDialogView(false);
    const closeDialogBoxV2 = () => setDialogBoxV2View(false);

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t("ERROR"),
            close: { variant: "critical" },
            content: t("UNKNOWN_ERROR"),
        });

    const logout = () => {
        setMlSearchEnabled(false);
        void photosLogout().then(() => router.push(PAGES.ROOT));
    };

    const appContext = {
        appName,
        showNavBar,
        mlSearchEnabled,
        updateMlSearchEnabled,
        startLoading,
        finishLoading,
        closeMessageDialog,
        setDialogMessage,
        watchFolderView,
        setWatchFolderView,
        watchFolderFiles,
        setWatchFolderFiles,
        isMobile,
        setNotificationAttributes,
        themeColor,
        setThemeColor,
        somethingWentWrong,
        setDialogBoxAttributesV2,
        mapEnabled,
        updateMapEnabled,
        isCFProxyDisabled,
        setIsCFProxyDisabled,
        logout,
    };

    const title = isI18nReady
        ? t("title", { context: "photos" })
        : appTitle[appName];

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(themeColor, "photos")}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar isMobile={isMobile} />}
                <MessageContainer>
                    {isI18nReady && offline && t("OFFLINE_MSG")}
                </MessageContainer>
                <LoadingBar color="#51cd7c" ref={loadingBar} />

                <DialogBox
                    sx={{ zIndex: 1600 }}
                    size="xs"
                    open={messageDialogView}
                    onClose={closeMessageDialog}
                    attributes={dialogMessage}
                />
                <DialogBoxV2
                    sx={{ zIndex: 1600 }}
                    open={dialogBoxV2View}
                    onClose={closeDialogBoxV2}
                    attributes={dialogBoxAttributeV2}
                />

                <Notification
                    open={notificationView}
                    onClose={closeNotification}
                    attributes={notificationAttributes}
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
}
