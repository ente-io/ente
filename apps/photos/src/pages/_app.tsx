import React, { createContext, useEffect, useRef, useState } from 'react';
import AppNavbar from '@ente/shared/components/Navbar/app';
import { t } from 'i18next';

import { useRouter } from 'next/router';
import { Overlay } from '@ente/shared/components/Container';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'photoswipe/dist/photoswipe.css';
import 'styles/global.css';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { logError } from '@ente/shared/sentry';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import HTTPService from '@ente/shared/network/HTTPService';
import Head from 'next/head';
import { eventBus, Events } from '@ente/shared/events';
import mlWorkManager from 'services/machineLearning/mlWorkManager';
import {
    getMLSearchConfig,
    updateMLSearchConfig,
} from 'utils/machineLearning/config';
import LoadingBar from 'react-top-loading-bar';
import DialogBox from '@ente/shared/components/DialogBox';
import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import { ThemeProvider } from '@mui/material/styles';
import { MessageContainer } from '@ente/shared/components/MessageContainer';
import { CssBaseline, useMediaQuery } from '@mui/material';
import {
    SetDialogBoxAttributes,
    DialogBoxAttributes,
} from '@ente/shared/components/DialogBox/types';
import {
    DialogBoxAttributesV2,
    SetDialogBoxAttributesV2,
} from '@ente/shared/components/DialogBoxV2/types';
import {
    getFamilyPortalRedirectURL,
    getRoadmapRedirectURL,
    updateMapEnabledStatus,
} from 'services/userService';
import { CustomError } from '@ente/shared/error';
import { addLogLine } from '@ente/shared/logging';
import { clearLogsIfLocalStorageLimitExceeded } from '@ente/shared/logging/web';
import isElectron from 'is-electron';
import ElectronAPIs from '@ente/shared/electron';
import {
    getUpdateAvailableForDownloadMessage,
    getUpdateReadyToInstallMessage,
} from 'utils/ui';
import Notification from 'components/Notification';
import {
    NotificationAttributes,
    SetNotificationAttributes,
} from 'types/Notification';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { CacheProvider } from '@emotion/react';
import {
    APP_TITLES,
    APPS,
    CLIENT_PACKAGE_NAMES,
} from '@ente/shared/apps/constants';
import exportService from 'services/export';
import { REDIRECTS } from 'constants/redirects';
import {
    getLocalMapEnabled,
    getToken,
    setLocalMapEnabled,
} from '@ente/shared/storage/localStorage/helpers';
import { isExportInProgress } from 'utils/export';
import { EnteAppProps } from '@ente/shared/apps/types';
import createEmotionCache from '@ente/shared/themes/createEmotionCache';
import { THEME_COLOR } from '@ente/shared/themes/constants';
import { SetTheme } from '@ente/shared/themes/types';
import { setupI18n } from '@ente/shared/i18n';
import { getSentryUserID } from '@ente/shared/sentry/utils';
import { User } from '@ente/shared/user/types';
import { useLocalState } from '@ente/shared/hooks/useLocalState';
import { PHOTOS_PAGES as PAGES } from '@ente/shared/constants/pages';
import { getTheme } from '@ente/shared/themes';
import { AppUpdateInfo } from '@ente/shared/electron/types';
import DownloadManager from 'services/download';

const redirectMap = new Map([
    [REDIRECTS.ROADMAP, getRoadmapRedirectURL],
    [REDIRECTS.FAMILIES, getFamilyPortalRedirectURL],
]);

type AppContextType = {
    showNavBar: (show: boolean) => void;
    sharedFiles: File[];
    resetSharedFiles: () => void;
    mlSearchEnabled: boolean;
    mapEnabled: boolean;
    updateMlSearchEnabled: (enabled: boolean) => Promise<void>;
    updateMapEnabled: (enabled: boolean) => Promise<void>;
    startLoading: () => void;
    finishLoading: () => void;
    closeMessageDialog: () => void;
    setDialogMessage: SetDialogBoxAttributes;
    setNotificationAttributes: SetNotificationAttributes;
    isFolderSyncRunning: boolean;
    setIsFolderSyncRunning: (isRunning: boolean) => void;
    watchFolderView: boolean;
    setWatchFolderView: (isOpen: boolean) => void;
    watchFolderFiles: FileList;
    setWatchFolderFiles: (files: FileList) => void;
    isMobile: boolean;
    themeColor: THEME_COLOR;
    setThemeColor: SetTheme;
    somethingWentWrong: () => void;
    setDialogBoxAttributesV2: SetDialogBoxAttributesV2;
    isCFProxyDisabled: boolean;
    setIsCFProxyDisabled: (disabled: boolean) => void;
};

export const AppContext = createContext<AppContextType>(null);

// Client-side cache, shared for the whole session of the user in the browser.
const clientSideEmotionCache = createEmotionCache();

export default function App(props: EnteAppProps) {
    const {
        Component,
        emotionCache = clientSideEmotionCache,
        pageProps,
    } = props;
    const router = useRouter();
    const [isI18nReady, setIsI18nReady] = useState<boolean>(false);
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== 'undefined' && !window.navigator.onLine
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const [sharedFiles, setSharedFiles] = useState<File[]>(null);
    const [redirectName, setRedirectName] = useState<string>(null);
    const [mlSearchEnabled, setMlSearchEnabled] = useState(false);
    const [mapEnabled, setMapEnabled] = useState(false);
    const isLoadingBarRunning = useRef(false);
    const loadingBar = useRef(null);
    const [dialogMessage, setDialogMessage] = useState<DialogBoxAttributes>();
    const [dialogBoxAttributeV2, setDialogBoxAttributesV2] =
        useState<DialogBoxAttributesV2>();
    useState<DialogBoxAttributes>(null);
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [dialogBoxV2View, setDialogBoxV2View] = useState(false);
    const [isFolderSyncRunning, setIsFolderSyncRunning] = useState(false);
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const isMobile = useMediaQuery('(max-width:428px)');
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);
    const [themeColor, setThemeColor] = useLocalState(
        LS_KEYS.THEME,
        THEME_COLOR.DARK
    );
    const [isCFProxyDisabled, setIsCFProxyDisabled] = useLocalState(
        LS_KEYS.CF_PROXY_DISABLED,
        false
    );

    useEffect(() => {
        //setup i18n
        setupI18n().finally(() => setIsI18nReady(true));
        // set client package name in headers
        HTTPService.setHeaders({
            'X-Client-Package': CLIENT_PACKAGE_NAMES.get(APPS.PHOTOS),
        });
        // setup logging
        clearLogsIfLocalStorageLimitExceeded();
        const main = async () => {
            addLogLine(`userID: ${(getData(LS_KEYS.USER) as User)?.id}`);
            addLogLine(`sentryID: ${await getSentryUserID()}`);
            addLogLine(`sentry release ID: ${process.env.SENTRY_RELEASE}`);
        };
        main();
    }, []);

    useEffect(() => {
        if (isElectron()) {
            const showUpdateDialog = (updateInfo: AppUpdateInfo) => {
                if (updateInfo.autoUpdatable) {
                    setDialogMessage(
                        getUpdateReadyToInstallMessage(updateInfo)
                    );
                } else {
                    setNotificationAttributes({
                        endIcon: <ArrowForward />,
                        variant: 'secondary',
                        message: t('UPDATE_AVAILABLE'),
                        onClick: () =>
                            setDialogMessage(
                                getUpdateAvailableForDownloadMessage(updateInfo)
                            ),
                    });
                }
            };
            ElectronAPIs.registerUpdateEventListener(showUpdateDialog);
        }
    }, []);

    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        const loadMlSearchState = async () => {
            try {
                const mlSearchConfig = await getMLSearchConfig();
                setMlSearchEnabled(mlSearchConfig.enabled);
                mlWorkManager.setMlSearchEnabled(mlSearchConfig.enabled);
            } catch (e) {
                logError(e, 'Error while loading mlSearchEnabled');
            }
        };
        loadMlSearchState();
        try {
            eventBus.on(Events.LOGOUT, () => {
                setMlSearchEnabled(false);
                mlWorkManager.setMlSearchEnabled(false);
            });
        } catch (e) {
            logError(e, 'Error while subscribing to logout event');
        }
    }, []);

    useEffect(() => {
        setMapEnabled(getLocalMapEnabled());
    }, []);

    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        const initExport = async () => {
            try {
                addLogLine('init export');
                const token = getToken();
                if (!token) {
                    addLogLine(
                        'User not logged in, not starting export continuous sync job'
                    );
                    return;
                }
                await DownloadManager.init(APPS.PHOTOS, { token });
                const exportSettings = exportService.getExportSettings();
                if (!exportService.exportFolderExists(exportSettings?.folder)) {
                    return;
                }
                const exportRecord = await exportService.getExportRecord(
                    exportSettings.folder
                );
                if (exportSettings.continuousExport) {
                    exportService.enableContinuousExport();
                }
                if (isExportInProgress(exportRecord.stage)) {
                    addLogLine('export was in progress, resuming');
                    exportService.scheduleExport();
                }
            } catch (e) {
                logError(e, 'init export failed');
            }
        };
        initExport();
        try {
            eventBus.on(Events.LOGOUT, () => {
                exportService.disableContinuousExport();
            });
        } catch (e) {
            logError(e, 'Error while subscribing to logout event');
        }
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);
    const resetSharedFiles = () => setSharedFiles(null);

    useEffect(() => {
        if (isI18nReady) {
            console.log(
                `%c${t('CONSOLE_WARNING_STOP')}`,
                'color: red; font-size: 52px;'
            );
            console.log(`%c${t('CONSOLE_WARNING_DESC')}`, 'font-size: 20px;');
        }
    }, [isI18nReady]);

    useEffect(() => {
        const redirectTo = async (redirect) => {
            if (
                redirectMap.has(redirect) &&
                typeof redirectMap.get(redirect) === 'function'
            ) {
                const redirectAction = redirectMap.get(redirect);
                window.location.href = await redirectAction();
            } else {
                logError(CustomError.BAD_REQUEST, 'invalid redirection', {
                    redirect,
                });
            }
        };

        const query = new URLSearchParams(window.location.search);
        const redirectName = query.get('redirect');
        if (redirectName) {
            const user = getData(LS_KEYS.USER);
            if (user?.token) {
                redirectTo(redirectName);
            } else {
                setRedirectName(redirectName);
            }
        }

        router.events.on('routeChangeStart', (url: string) => {
            const newPathname = url.split('?')[0] as PAGES;
            if (window.location.pathname !== newPathname) {
                setLoading(true);
            }

            if (redirectName) {
                const user = getData(LS_KEYS.USER);
                if (user?.token) {
                    redirectTo(redirectName);

                    // https://github.com/vercel/next.js/issues/2476#issuecomment-573460710
                    // eslint-disable-next-line no-throw-literal
                    throw 'Aborting route change, redirection in process....';
                }
            }
        });

        router.events.on('routeChangeComplete', () => {
            setLoading(false);
        });

        window.addEventListener('online', setUserOnline);
        window.addEventListener('offline', setUserOffline);

        return () => {
            window.removeEventListener('online', setUserOnline);
            window.removeEventListener('offline', setUserOffline);
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
            const mlSearchConfig = await getMLSearchConfig();
            mlSearchConfig.enabled = enabled;
            await updateMLSearchConfig(mlSearchConfig);
            setMlSearchEnabled(enabled);
            mlWorkManager.setMlSearchEnabled(enabled);
        } catch (e) {
            logError(e, 'Error while updating mlSearchEnabled');
        }
    };

    const updateMapEnabled = async (enabled: boolean) => {
        try {
            await updateMapEnabledStatus(enabled);
            setLocalMapEnabled(enabled);
            setMapEnabled(enabled);
        } catch (e) {
            logError(e, 'Error while updating mapEnabled');
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
            title: t('ERROR'),
            close: { variant: 'critical' },
            content: t('UNKNOWN_ERROR'),
        });

    return (
        <CacheProvider value={emotionCache}>
            <Head>
                <title>
                    {isI18nReady
                        ? t('TITLE', { context: APPS.PHOTOS })
                        : APP_TITLES.get(APPS.PHOTOS)}
                </title>
                <meta
                    name="viewport"
                    content="initial-scale=1, width=device-width"
                />
            </Head>

            <ThemeProvider theme={getTheme(themeColor, APPS.PHOTOS)}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar isMobile={isMobile} />}
                <MessageContainer>
                    {offline && t('OFFLINE_MSG')}
                </MessageContainer>
                {sharedFiles &&
                    (router.pathname === '/gallery' ? (
                        <MessageContainer>
                            {t('files_to_be_uploaded', {
                                count: sharedFiles.length,
                            })}
                        </MessageContainer>
                    ) : (
                        <MessageContainer>
                            {t('login_to_upload_files', {
                                count: sharedFiles.length,
                            })}
                        </MessageContainer>
                    ))}
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

                <AppContext.Provider
                    value={{
                        showNavBar,
                        mlSearchEnabled,
                        updateMlSearchEnabled,
                        sharedFiles,
                        resetSharedFiles,
                        startLoading,
                        finishLoading,
                        closeMessageDialog,
                        setDialogMessage,
                        isFolderSyncRunning,
                        setIsFolderSyncRunning,
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
                    }}>
                    {(loading || !isI18nReady) && (
                        <Overlay
                            sx={(theme) => ({
                                display: 'flex',
                                justifyContent: 'center',
                                alignItems: 'center',
                                zIndex: 2000,
                                backgroundColor: theme.colors.background.base,
                            })}>
                            <EnteSpinner />
                        </Overlay>
                    )}
                    <Component setLoading={setLoading} {...pageProps} />
                </AppContext.Provider>
            </ThemeProvider>
        </CacheProvider>
    );
}
