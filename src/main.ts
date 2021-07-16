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
import AppUpdater from './appUpdater';
import { createWindow } from './util';
import { buildContextMenu, buildMenuBar } from './menuUtil';
import setupIpcComs from './ipcComms';

let tray: Tray;
let mainWindow: BrowserWindow;



// Disable error dialogs by overriding
dialog.showErrorBox = function (title, content) {
    console.log(`${title}\n${content}`);
};


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




