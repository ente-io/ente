import { clientPackageName, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { AppNavbar } from "@/base/components/Navbar";
import {
    genericErrorDialogAttributes,
    useAttributedMiniDialog,
} from "@/base/components/utils/mini-dialog";
import { setupI18n } from "@/base/i18n";
import log from "@/base/log";
import {
    logStartupBanner,
    logUnhandledErrorsAndRejections,
} from "@/base/log-web";
import { AppUpdate } from "@/base/types/ipc";
import {
    updateAvailableForDownloadDialogAttributes,
    updateReadyToInstallDialogAttributes,
} from "@/new/photos/components/utils/download";
import { photosDialogZIndex } from "@/new/photos/components/z-index";
import DownloadManager from "@/new/photos/services/download";
import { runMigrations } from "@/new/photos/services/migrations";
import { initML, isMLSupported } from "@/new/photos/services/ml";
import { AppContext } from "@/new/photos/types/context";
import { Overlay } from "@ente/shared/components/Container";
import DialogBox from "@ente/shared/components/DialogBox";
import { DialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import { MessageContainer } from "@ente/shared/components/MessageContainer";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    getData,
    migrateKVToken,
} from "@ente/shared/storage/localStorage";
import {
    getLocalMapEnabled,
    getToken,
    setLocalMapEnabled,
} from "@ente/shared/storage/localStorage/helpers";
import { getTheme } from "@ente/shared/themes";
import { THEME_COLOR } from "@ente/shared/themes/constants";
import type { User } from "@ente/shared/user/types";
import ArrowForward from "@mui/icons-material/ArrowForward";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import Notification from "components/Notification";
import { t } from "i18next";
import isElectron from "is-electron";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import "photoswipe/dist/photoswipe.css";
import { useCallback, useEffect, useRef, useState } from "react";
import LoadingBar from "react-top-loading-bar";
import { resumeExportsIfNeeded } from "services/export";
import { photosLogout } from "services/logout";
import {
    getFamilyPortalRedirectURL,
    updateMapEnabledStatus,
} from "services/userService";
import "styles/global.css";
import { NotificationAttributes } from "types/Notification";

export default function App({ Component, pageProps }: AppProps) {
    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== "undefined" && !window.navigator.onLine,
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const [mapEnabled, setMapEnabled] = useState(false);
    const isLoadingBarRunning = useRef(false);
    const loadingBar = useRef(null);
    const [dialogMessage, setDialogMessage] = useState<DialogBoxAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
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
        const user = getData(LS_KEYS.USER) as User | undefined | null;
        migrateKVToken(user);
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
        logUnhandledErrorsAndRejections(true);
        void runMigrations();
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
                showMiniDialog(updateReadyToInstallDialogAttributes(update));
            } else {
                setNotificationAttributes({
                    endIcon: <ArrowForward />,
                    variant: "secondary",
                    message: t("update_available"),
                    onClick: () =>
                        showMiniDialog(
                            updateAvailableForDownloadDialogAttributes(update),
                        ),
                });
            }
        };

        if (isMLSupported) initML();

        electron.onOpenURL(handleOpenURL);
        electron.onAppUpdateAvailable(showUpdateDialog);

        return () => {
            electron.onOpenURL(undefined);
            electron.onAppUpdateAvailable(undefined);
        };
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
        const query = new URLSearchParams(window.location.search);
        const needsFamilyRedirect = query.get("redirect") == "families";
        if (needsFamilyRedirect && getData(LS_KEYS.USER)?.token)
            redirectToFamilyPortal();

        router.events.on("routeChangeStart", (url: string) => {
            const newPathname = url.split("?")[0];
            if (window.location.pathname !== newPathname) {
                setLoading(true);
            }

            if (needsFamilyRedirect && getData(LS_KEYS.USER)?.token) {
                redirectToFamilyPortal();

                // https://github.com/vercel/next.js/issues/2476#issuecomment-573460710
                // eslint-disable-next-line no-throw-literal
                throw "Aborting route change, redirection in process....";
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
        setMessageDialogView(true);
    }, [dialogMessage]);

    useEffect(() => {
        setNotificationView(true);
    }, [notificationAttributes]);

    const showNavBar = (show: boolean) => setShowNavBar(show);

    const updateMapEnabled = async (enabled: boolean) => {
        await updateMapEnabledStatus(enabled);
        setLocalMapEnabled(enabled);
        setMapEnabled(enabled);
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

    const closeMessageDialog = useCallback(
        () => setMessageDialogView(false),
        [],
    );

    // Use `onGenericError` instead.
    const somethingWentWrong = useCallback(
        () =>
            setDialogMessage({
                title: t("error"),
                close: { variant: "critical" },
                content: t("generic_error_retry"),
            }),
        [],
    );

    const onGenericError = useCallback((e: unknown) => {
        log.error("Error", e);
        showMiniDialog(genericErrorDialogAttributes());
    }, []);

    const logout = useCallback(() => {
        void photosLogout().then(() => router.push("/"));
    }, [router]);

    const appContext = {
        showNavBar,
        startLoading, // <- changes on each render (TODO Fix)
        finishLoading, // <- changes on each render
        closeMessageDialog,
        setDialogMessage,
        watchFolderView,
        setWatchFolderView,
        watchFolderFiles,
        setWatchFolderFiles,
        setNotificationAttributes,
        themeColor,
        setThemeColor,
        showMiniDialog,
        somethingWentWrong,
        onGenericError,
        mapEnabled,
        updateMapEnabled, // <- changes on each render
        isCFProxyDisabled,
        setIsCFProxyDisabled,
        logout,
    };

    const title = isI18nReady ? t("title_photos") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(themeColor, "photos")}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar />}
                <MessageContainer>
                    {isI18nReady && offline && t("OFFLINE_MSG")}
                </MessageContainer>
                <LoadingBar color="#51cd7c" ref={loadingBar} />

                <DialogBox
                    sx={{ zIndex: photosDialogZIndex }}
                    size="xs"
                    open={messageDialogView}
                    onClose={closeMessageDialog}
                    attributes={dialogMessage}
                />
                <AttributedMiniDialog
                    sx={{ zIndex: photosDialogZIndex }}
                    {...miniDialogProps}
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
                            <ActivityIndicator />
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

const redirectToFamilyPortal = () =>
    void getFamilyPortalRedirectURL().then((url) => {
        window.location.href = url;
    });
