import {
    app,
    BrowserWindow,
    Menu,
    Tray,
    dialog,
    nativeImage,
} from 'electron';
import * as path from 'path';
import * as isDev from 'electron-is-dev';
import AppUpdater from './utils/appUpdater';
import { createWindow } from './utils/createWindow';
import setupIpcComs from './utils/ipcComms';
import { buildContextMenu, buildMenuBar } from './utils/menuUtil';

let tray: Tray;
let mainWindow: BrowserWindow;

let appIsQuitting = false;

export const isAppQuitting = (): boolean => {
    return appIsQuitting;
}
export const setIsAppQuitting = (value: boolean): void => {
    appIsQuitting = value;
}

// Disable error dialogs by overriding
dialog.showErrorBox = function (title, content) {
    console.log(`${title}\n${content}`);
};


const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
    app.quit();
}
else {

    app.on('second-instance', () => {
        // Someone tried to run a second instance, we should focus our window.
        if (mainWindow) {
            mainWindow.show();
            if (mainWindow.isMinimized()) {
                mainWindow.restore()
            }
            mainWindow.focus()
        }
    })

    // This method will be called when Electron has finished
    // initialization and is ready to create browser windows.
    // Some APIs can only be used after this event occurs.
    app.on('ready', () => {

        if (!isDev) {
            AppUpdater.checkForUpdate();
        }
        Menu.setApplicationMenu(buildMenuBar(mainWindow))
        mainWindow = createWindow();

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
        setupIpcComs(tray, mainWindow);
    });

}



