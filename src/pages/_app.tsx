import React, { createContext, useEffect, useRef, useState } from 'react';
import AppNavbar from 'components/Navbar/app';
import constants from 'utils/strings/constants';
import { useRouter } from 'next/router';
import VerticallyCentered from 'components/Container';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'photoswipe/dist/photoswipe.css';
import 'styles/global.css';
import EnteSpinner from 'components/EnteSpinner';
import { logError } from '../utils/sentry';
// import { Workbox } from 'workbox-window';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import HTTPService from 'services/HTTPService';
import FlashMessageBar from 'components/FlashMessageBar';
import Head from 'next/head';
import LoadingBar from 'react-top-loading-bar';
import DialogBox from 'components/DialogBox';
import { styled, ThemeProvider } from '@mui/material/styles';
import darkThemeOptions from 'themes/darkThemeOptions';
import { CssBaseline, useMediaQuery } from '@mui/material';
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as types from 'styled-components/cssprop'; // need to css prop on styled component
import { SetDialogBoxAttributes, DialogBoxAttributes } from 'types/dialogBox';
import {
    getFamilyPortalRedirectURL,
    getRoadmapRedirectURL,
} from 'services/userService';
import { CustomError } from 'utils/error';
import { clearLogsIfLocalStorageLimitExceeded } from 'utils/logging';
import isElectron from 'is-electron';
import ElectronUpdateService from 'services/electron/update';
import {
    getUpdateAvailableForDownloadMessage,
    getUpdateReadyToInstallMessage,
} from 'utils/ui';
import Notification from 'components/Notification';
import {
    NotificationAttributes,
    SetNotificationAttributes,
} from 'types/Notification';

export const MessageContainer = styled('div')`
    background-color: #111;
    padding: 0;
    font-size: 14px;
    text-align: center;
    line-height: 32px;
`;

export interface BannerMessage {
    message: string;
    variant: string;
}

type AppContextType = {
    showNavBar: (show: boolean) => void;
    sharedFiles: File[];
    resetSharedFiles: () => void;
    setDisappearingFlashMessage: (message: FlashMessage) => void;
    redirectURL: string;
    setRedirectURL: (url: string) => void;
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
};

export enum FLASH_MESSAGE_TYPE {
    DANGER = 'danger',
    INFO = 'info',
    SUCCESS = 'success',
    WARNING = 'warning',
}
export interface FlashMessage {
    message: string;
    type: FLASH_MESSAGE_TYPE;
}
export const AppContext = createContext<AppContextType>(null);

const redirectMap = new Map([
    ['roadmap', getRoadmapRedirectURL],
    ['families', getFamilyPortalRedirectURL],
]);

export default function App({ Component, err }) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [offline, setOffline] = useState(
        typeof window !== 'undefined' && !window.navigator.onLine
    );
    const [showNavbar, setShowNavBar] = useState(false);
    const [sharedFiles, setSharedFiles] = useState<File[]>(null);
    const [redirectName, setRedirectName] = useState<string>(null);
    const [flashMessage, setFlashMessage] = useState<FlashMessage>(null);
    const [redirectURL, setRedirectURL] = useState(null);
    const isLoadingBarRunning = useRef(false);
    const loadingBar = useRef(null);
    const [dialogMessage, setDialogMessage] = useState<DialogBoxAttributes>();
    const [messageDialogView, setMessageDialogView] = useState(false);
    const [isFolderSyncRunning, setIsFolderSyncRunning] = useState(false);
    const [watchFolderView, setWatchFolderView] = useState(false);
    const [watchFolderFiles, setWatchFolderFiles] = useState<FileList>(null);
    const isMobile = useMediaQuery('(max-width:428px)');
    const [notificationView, setNotificationView] = useState(false);
    const closeNotification = () => setNotificationView(false);
    const [notificationAttributes, setNotificationAttributes] =
        useState<NotificationAttributes>(null);

    useEffect(() => {
        if (
            !('serviceWorker' in navigator) ||
            process.env.NODE_ENV !== 'production'
        ) {
            console.warn('Progressive Web App support is disabled');
            return;
        }
        // const wb = new Workbox('sw.js', { scope: '/' });
        // wb.register();

        if ('serviceWorker' in navigator && !isElectron()) {
            navigator.serviceWorker.onmessage = (event) => {
                if (event.data.action === 'upload-files') {
                    const files = event.data.files;
                    setSharedFiles(files);
                }
            };
            navigator.serviceWorker
                .getRegistrations()
                .then(function (registrations) {
                    for (const registration of registrations) {
                        registration.unregister();
                    }
                });
        }
    }, []);

    useEffect(() => {
        HTTPService.getInterceptors().response.use(
            (resp) => resp,
            (error) => {
                logError(error, 'HTTP Service Error');
                return Promise.reject(error);
            }
        );
        clearLogsIfLocalStorageLimitExceeded();
    }, []);

    useEffect(() => {
        if (isElectron()) {
            const showUpdateDialog = (updateInfo: {
                updateDownloaded: boolean;
            }) => {
                if (updateInfo.updateDownloaded) {
                    setDialogMessage(getUpdateReadyToInstallMessage());
                } else {
                    setDialogMessage(getUpdateAvailableForDownloadMessage());
                }
            };
            ElectronUpdateService.registerUpdateEventListener(showUpdateDialog);
        }
    }, []);

    const setUserOnline = () => setOffline(false);
    const setUserOffline = () => setOffline(true);
    const resetSharedFiles = () => setSharedFiles(null);

    useEffect(() => {
        if (process.env.NODE_ENV === 'production') {
            console.log(
                `%c${constants.CONSOLE_WARNING_STOP}`,
                'color: red; font-size: 52px;'
            );
            console.log(
                `%c${constants.CONSOLE_WARNING_DESC}`,
                'font-size: 20px;'
            );
        }

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
            if (window.location.pathname !== url.split('?')[0]) {
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

    useEffect(() => setMessageDialogView(true), [dialogMessage]);

    useEffect(() => setNotificationView(true), [notificationAttributes]);

    const showNavBar = (show: boolean) => setShowNavBar(show);
    const setDisappearingFlashMessage = (flashMessages: FlashMessage) => {
        setFlashMessage(flashMessages);
        setTimeout(() => setFlashMessage(null), 5000);
    };

    const startLoading = () => {
        !isLoadingBarRunning.current && loadingBar.current?.continuousStart();
        isLoadingBarRunning.current = true;
    };
    const finishLoading = () => {
        isLoadingBarRunning.current && loadingBar.current?.complete();
        isLoadingBarRunning.current = false;
    };

    const closeMessageDialog = () => setMessageDialogView(false);

    return (
        <>
            <Head>
                <title>{constants.TITLE}</title>
                <meta
                    name="viewport"
                    content="initial-scale=1, width=device-width"
                />
            </Head>

            <ThemeProvider theme={darkThemeOptions}>
                <CssBaseline enableColorScheme />
                {showNavbar && <AppNavbar />}
                <MessageContainer>
                    {offline && constants.OFFLINE_MSG}
                </MessageContainer>
                {sharedFiles &&
                    (router.pathname === '/gallery' ? (
                        <MessageContainer>
                            {constants.FILES_TO_BE_UPLOADED(sharedFiles.length)}
                        </MessageContainer>
                    ) : (
                        <MessageContainer>
                            {constants.LOGIN_TO_UPLOAD_FILES(
                                sharedFiles.length
                            )}
                        </MessageContainer>
                    ))}
                {flashMessage && (
                    <FlashMessageBar
                        flashMessage={flashMessage}
                        onClose={() => setFlashMessage(null)}
                    />
                )}
                <LoadingBar color="#51cd7c" ref={loadingBar} />

                <DialogBox
                    sx={{ zIndex: 1600 }}
                    size="xs"
                    open={messageDialogView}
                    onClose={closeMessageDialog}
                    attributes={dialogMessage}
                />
                <Notification
                    open={notificationView}
                    onClose={closeNotification}
                    attributes={notificationAttributes}
                />

                <AppContext.Provider
                    value={{
                        showNavBar,
                        sharedFiles,
                        resetSharedFiles,
                        setDisappearingFlashMessage,
                        redirectURL,
                        setRedirectURL,
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
                    }}>
                    {loading ? (
                        <VerticallyCentered>
                            <EnteSpinner>
                                <span className="sr-only">Loading...</span>
                            </EnteSpinner>
                        </VerticallyCentered>
                    ) : (
                        <Component err={err} setLoading={setLoading} />
                    )}
                </AppContext.Provider>
            </ThemeProvider>
        </>
    );
}
