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
    logSystemInfo,
    handleExternalLinks,
} from './utils/main';
import { initSentry } from './services/sentry';
import { setupLogging } from './utils/logging';
import { isDev } from './utils/common';
import { setupMainProcessStatsLogger } from './utils/processStats';
import { setupAppEventEmitter } from './utils/events';
import { getOptOutOfCrashReports } from './services/userPreference';

let mainWindow: BrowserWindow;

let appIsQuitting = false;

let updateIsAvailable = false;

let optedOutOfCrashReports = false;

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

export const hasOptedOutOfCrashReports = (): boolean => {
    return optedOutOfCrashReports;
};

export const updateOptOutOfCrashReports = (value: boolean): void => {
    optedOutOfCrashReports = value;
};

setupMainHotReload();

setupNextElectronServe();

setupLogging(isDev);

const localHasOptedOutOfCrashReports = getOptOutOfCrashReports();
updateOptOutOfCrashReports(localHasOptedOutOfCrashReports);
if (!localHasOptedOutOfCrashReports) {
    initSentry();
}

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
        logSystemInfo();
        setupMainProcessStatsLogger();
        mainWindow = await createWindow();
        const tray = setupTrayItem(mainWindow);
        const watcher = initWatcher(mainWindow);
        setupMacWindowOnDockIconClick();
        setupMainMenu(mainWindow);
        setupIpcComs(tray, mainWindow, watcher);
        await handleUpdates(mainWindow);
        handleDownloads(mainWindow);
        handleExternalLinks(mainWindow);
        addAllowOriginHeader(mainWindow);
        setupAppEventEmitter(mainWindow);
    });

    app.on('before-quit', () => setIsAppQuitting(true));
}
