import { clientPackageName, isDesktop, staticAppTitle } from "@/base/app";
import { CustomHead } from "@/base/components/Head";
import { LoadingOverlay } from "@/base/components/LoadingOverlay";
import { AttributedMiniDialog } from "@/base/components/MiniDialog";
import { AppNavbar } from "@/base/components/Navbar";
import {
    genericErrorDialogAttributes,
    useAttributedMiniDialog,
} from "@/base/components/utils/dialog";
import { useSetupI18n } from "@/base/components/utils/hooks-i18n";
import { THEME_COLOR, getTheme } from "@/base/components/utils/theme";
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
import { useIsOffline } from "@/new/photos/components/utils/use-is-offline";
import { useLoadingBar } from "@/new/photos/components/utils/use-loading-bar";
import { photosDialogZIndex } from "@/new/photos/components/utils/z-index";
import { runMigrations } from "@/new/photos/services/migration";
import { initML, isMLSupported } from "@/new/photos/services/ml";
import { getFamilyPortalRedirectURL } from "@/new/photos/services/user-details";
import { AppContext } from "@/new/photos/types/context";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    getData,
    migrateKVToken,
} from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import "@fontsource-variable/inter";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import { CssBaseline, styled } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import Notification from "components/Notification";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import "photoswipe/dist/photoswipe.css";
import { useCallback, useEffect, useMemo, useState } from "react";
import LoadingBar from "react-top-loading-bar";
import { resumeExportsIfNeeded } from "services/export";
import { photosLogout } from "services/logout";
import { NotificationAttributes } from "types/Notification";

import "styles/global.css";

export default function App({ Component, pageProps }: AppProps) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [showNavbar, setShowNavBar] = useState(false);
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    const isOffline = useIsOffline();
    const isI18nReady = useSetupI18n();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const { loadingBarRef, showLoadingBar, hideLoadingBar } = useLoadingBar();
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK,
    );

    useEffect(() => {
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
                    endIcon: <ArrowForwardIcon />,
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

    useEffect(() => {
        const query = new URLSearchParams(window.location.search);
        const needsFamilyRedirect = query.get("redirect") == "families";
        if (needsFamilyRedirect && getData(LS_KEYS.USER)?.token)
            redirectToFamilyPortal();

        // TODO: Remove me after instrumenting for a bit.
        let t = Date.now();
        router.events.on("routeChangeStart", (url: string) => {
            t = Date.now();
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
            log.debug(() => `Route change took ${Date.now() - t} ms`);
            setLoading(false);
        });
    }, []);

    useEffect(() => {
        setNotificationView(true);
    }, [notificationAttributes]);

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

    const appContext = useMemo(
        () => ({
            showNavBar: (show: boolean) => setShowNavBar(show),
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
        }),
        [
            showLoadingBar,
            hideLoadingBar,
            watchFolderView,
            watchFolderFiles,
            themeColor,
            showMiniDialog,
            onGenericError,
            logout,
        ],
    );

    const title = isI18nReady ? t("title_photos") : staticAppTitle;

    return (
        <>
            <CustomHead {...{ title }} />

            <ThemeProvider theme={getTheme(themeColor, "photos")}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar />}
                <OfflineMessageContainer>
                    {isI18nReady && isOffline && t("offline_message")}
                </OfflineMessageContainer>
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
                    {(loading || !isI18nReady) && <LoadingOverlay />}
                    {isI18nReady && <Component {...pageProps} />}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
}

const OfflineMessageContainer = styled("div")`
    background-color: #111;
    padding: 0;
    font-size: 14px;
    text-align: center;
    line-height: 32px;
`;

const redirectToFamilyPortal = () =>
    void getFamilyPortalRedirectURL().then((url) => {
        window.location.href = url;
    });
