import { app, BrowserWindow } from 'electron';
import { createWindow } from './utils/createWindow';
import setupIpcComs from './utils/ipcComms';
import { initWatcher } from './services/chokidar';
import { addAllowOriginHeader } from './utils/cors';
import {
    setupTrayItem,
    handleDownloads,
    setupMacWindowOnDockIconClick,
    setupMainMenu,
    setupMainHotReload,
    setupNextElectronServe,
    enableSharedArrayBufferSupport,
    handleDockIconHideOnAutoLaunch,
    handleUpdates,
} from './utils/main';
import { initSentry } from './services/sentry';
import { setupLogging } from './utils/logging';

let mainWindow: BrowserWindow;

let appIsQuitting = false;

let updateIsAvailable = false;

export const isAppQuitting = (): boolean => {
    return appIsQuitting;
};

export const setIsAppQuitting = (value: boolean): void => {
    appIsQuitting = value;
};

export const isUpdateAvailable = (): boolean => {
    return updateIsAvailable;
};
export const setIsUpdateAvailable = (value: boolean): void => {
    updateIsAvailable = value;
};

setupMainHotReload();

setupNextElectronServe();

setupLogging();

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
    app.quit();
} else {
    handleDockIconHideOnAutoLaunch();
    enableSharedArrayBufferSupport();
    app.on('second-instance', () => {
        // Someone tried to run a second instance, we should focus our window.
        if (mainWindow) {
            mainWindow.show();
            if (mainWindow.isMinimized()) {
                mainWindow.restore();
            }
            mainWindow.focus();
        }
    });

    // This method will be called when Electron has finished
    // initialization and is ready to create browser windows.
    // Some APIs can only be used after this event occurs.
    app.on('ready', async () => {
        mainWindow = await createWindow();
        const tray = setupTrayItem(mainWindow);
        const watcher = initWatcher(mainWindow);
        setupMacWindowOnDockIconClick();
        initSentry();
        setupMainMenu();
        setupIpcComs(tray, mainWindow, watcher);
        handleUpdates(mainWindow);
        handleDownloads(mainWindow);
        addAllowOriginHeader(mainWindow);
    });

    app.on('before-quit', () => setIsAppQuitting(true));
}
