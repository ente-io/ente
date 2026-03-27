import "@fontsource-variable/inter";
import { CssBaseline } from "@mui/material";
import { ThemeProvider } from "@mui/material/styles";
import { useNotification } from "components/utils/hooks-app";
import { staticAppTitle } from "ente-base/app";
import { CustomHeadAlbums } from "ente-base/components/Head";
import { LoadingIndicator } from "ente-base/components/loaders";
import { AttributedMiniDialog } from "ente-base/components/MiniDialog";
import { useAttributedMiniDialog } from "ente-base/components/utils/dialog";
import { useSetupI18n } from "ente-base/components/utils/hooks-app";
import { photosTheme } from "ente-base/components/utils/theme";
import { BaseContext, deriveBaseContext } from "ente-base/context";
import { Notification } from "ente-new/photos/components/Notification";
import { ThemedLoadingBar } from "ente-new/photos/components/ThemedLoadingBar";
import { useLoadingBar } from "ente-new/photos/components/utils/use-loading-bar";
import { PhotosAppContext } from "ente-new/photos/types/context";
import { t } from "i18next";
import type { AppProps } from "next/app";
import { useCallback, useMemo } from "react";

import "photoswipe/dist/photoswipe.css";
import "styles/global.css";
import "styles/photoswipe.css";

type AlbumsAppProps = AppProps<Record<string, unknown>>;

const App: React.FC<AlbumsAppProps> = ({ Component, pageProps }) => {
    const isI18nReady = useSetupI18n();
    const { showMiniDialog, miniDialogProps } = useAttributedMiniDialog();
    const { showNotification, notificationProps } = useNotification();
    const { loadingBarRef, showLoadingBar, hideLoadingBar } = useLoadingBar();
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
        }),
        [showLoadingBar, hideLoadingBar, showNotification],
    );
    const title = isI18nReady ? t("title_photos") : staticAppTitle;

    return (
        <ThemeProvider theme={photosTheme}>
            <CustomHeadAlbums {...{ title }} />
            <CssBaseline enableColorScheme />

            <ThemedLoadingBar ref={loadingBarRef} />
            <AttributedMiniDialog {...miniDialogProps} />
            <Notification {...notificationProps} />

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
