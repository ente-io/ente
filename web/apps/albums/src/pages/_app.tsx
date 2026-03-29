import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import {
    LazyAttributedMiniDialog,
    LazyNotification,
} from "@/public-album/components/lazy-ui";
import { useNotification } from "@/public-album/hooks/useNotification";
import { staticAppTitle } from "ente-base/app";
import { CustomHeadAlbums } from "ente-base/components/Head";
import { LoadingIndicator } from "ente-base/components/loaders";
import { useAttributedMiniDialog } from "ente-base/components/utils/dialog";
import { useSetupI18n } from "ente-base/components/utils/hooks-app";
import { photosTheme } from "ente-base/components/utils/theme";
import { BaseContext, deriveBaseContext } from "ente-base/context";
import { ThemedLoadingBar } from "@/photos/components/ThemedLoadingBar";
import { useLoadingBar } from "@/photos/components/utils/use-loading-bar";
import { PhotosAppContext } from "@/photos/types/context";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useCallback, useMemo, useState } from "react";

import "photoswipe/dist/photoswipe.css";
import "../public-album/styles/global.css";
import "../public-album/styles/photoswipe.css";

type AlbumsAppProps = AppProps<Record<string, unknown>>;

const App: React.FC<AlbumsAppProps> = ({ Component, pageProps }) => {
    const isI18nReady = useSetupI18n();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const { showNotification, notificationProps } = useNotification();
    const { loadingBarRef, showLoadingBar, hideLoadingBar } = useLoadingBar();
    const [watchFolderView, setWatchFolderView] = useState(false);
    const logout = useCallback(() => {
        // Public albums does not maintain a logged-in app session.
    }, []);

    const baseContext = useMemo(
        () => deriveBaseContext({ logout, showMiniDialog }),
        [logout, showMiniDialog],
    );
    const appContext = useMemo(
        () => ({
            showLoadingBar,
            hideLoadingBar,
            showNotification,
            watchFolderView,
            setWatchFolderView,
        }),
        [
            showLoadingBar,
            hideLoadingBar,
            showNotification,
            watchFolderView,
            setWatchFolderView,
        ],
    );
    const title = isI18nReady ? t("title_photos") : staticAppTitle;

    return (
        <ThemeProvider theme={photosTheme}>
            <CustomHeadAlbums {...{ title }} />
            <CssBaseline enableColorScheme />

            <ThemedLoadingBar ref={loadingBarRef} />
            {miniDialogProps.open && (
                <LazyAttributedMiniDialog {...miniDialogProps} />
            )}
            {notificationProps.open && <LazyNotification {...notificationProps} />}

            <BaseContext value={baseContext}>
                <PhotosAppContext value={appContext}>
                    {!isI18nReady ? (
                        <LoadingIndicator />
                    ) : (
                        <Component {...pageProps} />
                    )}
                </PhotosAppContext>
            </BaseContext>
        </ThemeProvider>
    );
};

export default App;
