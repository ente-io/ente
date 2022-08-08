import { app, BrowserWindow, Menu, Tray, nativeImage } from 'electron';
import * as path from 'path';
import AppUpdater from './utils/appUpdater';
import { createWindow } from './utils/createWindow';
import setupIpcComs from './utils/ipcComms';
import { buildContextMenu, buildMenuBar } from './utils/menuUtil';
import initSentry from './utils/sentry';
import { isDev } from './utils/common';
import { existsSync } from 'fs';

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

        setupTrayItem();
        setupIpcComs(tray, mainWindow);
        handleUpdates();
        handleDownloads();
    });
}
function handleUpdates() {
    if (!isDev) {
        AppUpdater.checkForUpdate(tray, mainWindow);
    }
}

function setupTrayItem() {
    const trayImgPath = isDev
        ? 'build/taskbar-icon.png'
        : path.join(process.resourcesPath, 'taskbar-icon.png');
    const trayIcon = nativeImage.createFromPath(trayImgPath);
    tray = new Tray(trayIcon);
    tray.setToolTip('ente');
    tray.setContextMenu(buildContextMenu(mainWindow));
}

function handleDownloads() {
    mainWindow.webContents.session.on('will-download', (event, item) => {
        item.setSavePath(
            getUniqueSavePath(item.getFilename(), app.getPath('downloads'))
        );
    });
}

function getUniqueSavePath(filename: string, directory: string): string {
    let uniqueFileSavePath = path.join(directory, filename);
    const { name: filenameWithoutExtension, ext: extension } =
        path.parse(filename);
    let n = 0;
    while (existsSync(uniqueFileSavePath)) {
        n++;
        // filter need to remove undefined extension from the array
        // else [`${fileName}`, undefined].join(".") will lead to `${fileName}.` as joined string
        const fileNameWithNumberedSuffix = [
            `${filenameWithoutExtension}(${n})`,
            extension,
        ]
            .filter((x) => x) // filters out undefined/null values
            .join('.');
        uniqueFileSavePath = path.join(directory, fileNameWithNumberedSuffix);
    }
    return uniqueFileSavePath;
}
