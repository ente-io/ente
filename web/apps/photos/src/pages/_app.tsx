import "@fontsource-variable/inter";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import { CssBaseline, Typography } from "@mui/material";
import { styled, ThemeProvider } from "@mui/material/styles";
import { useNotification } from "components/utils/hooks-app";
import { clientPackageName, isDesktop, staticAppTitle } from "ente-base/app";
import { CenteredRow } from "ente-base/components/containers";
import { CustomHead } from "ente-base/components/Head";
import {
    LoadingIndicator,
    TranslucentLoadingOverlay,
} from "ente-base/components/loaders";
import { AttributedMiniDialog } from "ente-base/components/MiniDialog";
import { useAttributedMiniDialog } from "ente-base/components/utils/dialog";
import {
    useIsRouteChangeInProgress,
    useSetupI18n,
    useSetupLogs,
} from "ente-base/components/utils/hooks-app";
import { photosTheme } from "ente-base/components/utils/theme";
import { BaseContext, deriveBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { logStartupBanner } from "ente-base/log-web";
import { AppUpdate } from "ente-base/types/ipc";
import { Notification } from "ente-new/photos/components/Notification";
import { ThemedLoadingBar } from "ente-new/photos/components/ThemedLoadingBar";
import {
    updateAvailableForDownloadDialogAttributes,
    updateReadyToInstallDialogAttributes,
} from "ente-new/photos/components/utils/download";
import { useLoadingBar } from "ente-new/photos/components/utils/use-loading-bar";
import { runMigrations } from "ente-new/photos/services/migration";
import { initML, isMLSupported } from "ente-new/photos/services/ml";
import { getFamilyPortalRedirectURL } from "ente-new/photos/services/user-details";
import { PhotosAppContext } from "ente-new/photos/types/context";
import HTTPService from "ente-shared/network/HTTPService";
import {
    getData,
    isLocalStorageAndIndexedDBMismatch,
} from "ente-shared/storage/localStorage";
import type { User } from "ente-shared/user/types";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useRouter } from "next/router";
import { useCallback, useEffect, useMemo, useState } from "react";
import { resumeExportsIfNeeded } from "services/export";
import { photosLogout } from "services/logout";

import "photoswipe/dist/photoswipe.css";
import "styles/global.css";
import "styles/photoswipe.css";

const App: React.FC<AppProps> = ({ Component, pageProps }) => {
    useSetupLogs();

    const isI18nReady = useSetupI18n();
    const isChangingRoute = useIsRouteChangeInProgress();
    const router = useRouter();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const { showNotification, notificationProps } = useNotification();
    const { loadingBarRef, showLoadingBar, hideLoadingBar } = useLoadingBar();

    const [watchFolderView, setWatchFolderView] = useState(false);

    const logout = useCallback(() => void photosLogout(), []);

    useEffect(() => {
        const user = getData("user") as User | undefined | null;
        logStartupBanner(user?.id);
        HTTPService.setHeaders({ "X-Client-Package": clientPackageName });
        void isLocalStorageAndIndexedDBMismatch().then((mismatch) => {
            if (mismatch) {
                log.error("Logging out (IndexedDB and local storage mismatch)");
                return logout();
            } else {
                return runMigrations();
            }
        });
    }, [logout]);

    useEffect(() => {
        const electron = globalThis.electron;
        if (!electron) return;

        // Attach various listeners for events sent to us by the Node.js layer.
        // This is for events that we should listen for always, not just when
        // the user is logged in.

        const handleOpenEnteURL = (url: string) => {
            if (url.startsWith("ente://app")) router.push(url);
            else log.info(`Ignoring unhandled open request for URL ${url}`);
        };

        const showUpdateDialog = (update: AppUpdate) => {
            if (update.autoUpdatable) {
                showMiniDialog(updateReadyToInstallDialogAttributes(update));
            } else {
                showNotification({
                    color: "secondary",
                    title: t("update_available"),
                    endIcon: <ArrowForwardIcon />,
                    onClick: () =>
                        showMiniDialog(
                            updateAvailableForDownloadDialogAttributes(update),
                        ),
                });
            }
        };

        if (isMLSupported) initML();

        electron.onOpenEnteURL(handleOpenEnteURL);
        electron.onAppUpdateAvailable(showUpdateDialog);

        return () => {
            electron.onOpenEnteURL(undefined);
            electron.onAppUpdateAvailable(undefined);
        };
    }, []);

    useEffect(() => {
        if (isDesktop) void resumeExportsIfNeeded();
    }, []);

    useEffect(() => {
        const query = new URLSearchParams(window.location.search);
        const needsFamilyRedirect = query.get("redirect") == "families";
        if (needsFamilyRedirect && getData("user")?.token)
            redirectToFamilyPortal();

        router.events.on("routeChangeStart", () => {
            if (needsFamilyRedirect && getData("user")?.token) {
                redirectToFamilyPortal();

                // https://github.com/vercel/next.js/issues/2476#issuecomment-573460710
                // eslint-disable-next-line @typescript-eslint/only-throw-error
                throw "Aborting route change, redirection in process....";
            }
        });
    }, []);

    const baseContext = useMemo(
        () => deriveBaseContext({ logout, showMiniDialog }),
        [logout, showMiniDialog],
    );
    const appContext = useMemo(
        () => ({
            showLoadingBar,
            hideLoadingBar,
            watchFolderView,
            setWatchFolderView,
            showNotification,
        }),
        [
            showLoadingBar,
            hideLoadingBar,
            watchFolderView,
            setWatchFolderView,
            showNotification,
        ],
    );

    const title = isI18nReady ? t("title_photos") : staticAppTitle;

    return (
        <ThemeProvider theme={photosTheme}>
            <CustomHead {...{ title }} />
            <CssBaseline enableColorScheme />

            <ThemedLoadingBar ref={loadingBarRef} />
            <AttributedMiniDialog {...miniDialogProps} />
            <Notification {...notificationProps} />

            {isDesktop && <WindowTitlebar>{title}</WindowTitlebar>}
            <BaseContext value={baseContext}>
                <PhotosAppContext value={appContext}>
                    {!isI18nReady ? (
                        <LoadingIndicator />
                    ) : (
                        <>
                            {isChangingRoute && <TranslucentLoadingOverlay />}
                            <Component {...pageProps} />
                        </>
                    )}
                </PhotosAppContext>
            </BaseContext>
        </ThemeProvider>
    );
};

export default App;

const redirectToFamilyPortal = () =>
    void getFamilyPortalRedirectURL().then((url) => {
        window.location.href = url;
    });

const WindowTitlebar: React.FC<React.PropsWithChildren> = ({ children }) => (
    <WindowTitlebarArea>
        <Typography variant="small" sx={{ mt: "2px", fontWeight: "bold" }}>
            {children}
        </Typography>
    </WindowTitlebarArea>
);

// See: [Note: Customize the desktop title bar]
const WindowTitlebarArea = styled(CenteredRow)`
    width: 100%;
    height: env(titlebar-area-height, 30px /* fallback */);
    /* LoadingIndicator is 100vh, so resist shrinking when shown with it. */
    flex-shrink: 0;
    /* Allow using the titlebar to drag the window. */
    app-region: drag;
`;
