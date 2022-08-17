import { app, BrowserWindow } from 'electron';
import { createWindow } from './utils/createWindow';
import setupIpcComs from './utils/ipcComms';
import initSentry from './utils/sentry';
import electronReload from 'electron-reload';
import { PROD_HOST_URL, RENDERER_OUTPUT_DIR } from './config';
import { isDev } from './utils/common';
import { initWatcher } from './services/chokidar';
import serveNextAt from 'next-electron-server';
import { addAllowOriginHeader } from './utils/cors';
import {
    setupTrayItem,
    handleUpdates,
    handleDownloads,
    setupMacWindowOnDockIconClick,
    setupMainMenu,
} from './utils/main';

if (isDev) {
    electronReload(__dirname, {});
}

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

serveNextAt(PROD_HOST_URL, {
    outputDir: RENDERER_OUTPUT_DIR,
});

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
    app.quit();
} else {
    app.commandLine.appendSwitch('enable-features', 'SharedArrayBuffer');
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
    app.on('ready', () => {
        mainWindow = createWindow();
        const tray = setupTrayItem(mainWindow);
        const watcher = initWatcher(mainWindow);
        setupMacWindowOnDockIconClick();
        initSentry();
        setupMainMenu();
        setupIpcComs(tray, mainWindow, watcher);
        handleUpdates(mainWindow, tray);
        handleDownloads(mainWindow);
        addAllowOriginHeader(mainWindow);
    });
}
