import { app, BrowserWindow, Menu, Tray, nativeImage } from 'electron';
import * as path from 'path';
import AppUpdater from './utils/appUpdater';
import { createWindow } from './utils/createWindow';
import setupIpcComs from './utils/ipcComms';
import { buildContextMenu, buildMenuBar } from './utils/menuUtil';
import initSentry from './utils/sentry';
import { isDev } from './utils/common';
import { initWatcher } from './services/chokidar';

if (isDev) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const electronReload = require('electron-reload');
    electronReload(__dirname, {});
}

let tray: Tray;
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

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
    app.quit();
} else {
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
        initSentry();
        setIsUpdateAvailable(false);
        mainWindow = createWindow();
        Menu.setApplicationMenu(buildMenuBar());

        app.on('activate', function () {
            // On macOS it's common to re-create a window in the app when the
            // dock icon is clicked and there are no other windows open.
            if (BrowserWindow.getAllWindows().length === 0) createWindow();
        });

        const trayImgPath = isDev
            ? 'build/taskbar-icon.png'
            : path.join(process.resourcesPath, 'taskbar-icon.png');
        const trayIcon = nativeImage.createFromPath(trayImgPath);
        tray = new Tray(trayIcon);
        tray.setToolTip('ente');
        tray.setContextMenu(buildContextMenu(mainWindow));

        const watcher = initWatcher(mainWindow);
        setupIpcComs(tray, mainWindow, watcher);
        if (!isDev) {
            AppUpdater.checkForUpdate(tray, mainWindow);
        }
    });
}
