import { clientPackageName, isDesktop, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Overlay } from "@/base/components/mui/Container";
import { AppNavbar } from "@/base/components/Navbar";
import {
    genericErrorDialogAttributes,
    useAttributedMiniDialog,
} from "@/base/components/utils/dialog";
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
import { useLoadingBar } from "@/new/photos/components/utils/use-loading-bar";
import { photosDialogZIndex } from "@/new/photos/components/utils/z-index";
import { runMigrations } from "@/new/photos/services/migrations";
import { initML, isMLSupported } from "@/new/photos/services/ml";
import { getFamilyPortalRedirectURL } from "@/new/photos/services/user-details";
import { AppContext } from "@/new/photos/types/context";
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
import ArrowForward from "@mui/icons-material/ArrowForward";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import Notification from "components/Notification";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import "photoswipe/dist/photoswipe.css";
import { useCallback, useEffect, useState } from "react";
import LoadingBar from "react-top-loading-bar";
import { resumeExportsIfNeeded } from "services/export";
import { photosLogout } from "services/logout";
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
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const { loadingBarRef, showLoadingBar, hideLoadingBar } = useLoadingBar();
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
        void setupI18n().finally(() => setIsI18nReady(true));
        const user = getData(LS_KEYS.USER) as User | undefined | null;
        void migrateKVToken(user);
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
        if (isDesktop) void resumeExportsIfNeeded();
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
                // eslint-disable-next-line @typescript-eslint/only-throw-error
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
        setNotificationView(true);
    }, [notificationAttributes]);

    const showNavBar = (show: boolean) => setShowNavBar(show);

    const onGenericError = useCallback((e: unknown) => {
        log.error(e);
        // The generic error handler is sometimes called in the context of
        // actions that were initiated by a confirmation dialog action handler
        // themselves, then we need to let the current one close.
        //
        // See: [Note: Chained MiniDialogs]
        setTimeout(() => {
            showMiniDialog(genericErrorDialogAttributes());
        }, 0);
    }, []);

    const logout = useCallback(() => void photosLogout(), []);

    const appContext = {
        showNavBar,
        showLoadingBar,
        hideLoadingBar,
        watchFolderView,
        setWatchFolderView,
        watchFolderFiles,
        setWatchFolderFiles,
        setNotificationAttributes,
        themeColor,
        setThemeColor,
        showMiniDialog,
        onGenericError,
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
                <LoadingBar color="#51cd7c" ref={loadingBarRef} />

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
