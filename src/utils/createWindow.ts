import { app, BrowserWindow, nativeImage } from 'electron';
import * as isDev from 'electron-is-dev';
import * as path from 'path';
import { isAppQuitting } from '../main';

export function createWindow(): BrowserWindow {
    const appImgPath = isDev
        ? 'build/window-icon.png'
        : path.join(process.resourcesPath, 'window-icon.png');
    const appIcon = nativeImage.createFromPath(appImgPath);
    // Create the browser window.
    const mainWindow = new BrowserWindow({
        height: 600,
        width: 800,
        backgroundColor: '#111111',
        webPreferences: {
            preload: path.join(__dirname, '../preload.js'),
        },
        icon: appIcon,
        show: false, // don't show the main window
    });
    mainWindow.maximize();
    const splash = new BrowserWindow({
        alwaysOnTop: true,
        height: 600,
        width: 800,
        transparent: true,
    });
    splash.maximize();

    if (isDev) {
        splash.loadFile(`../build/splash.html`);
        mainWindow.loadURL('http://localhost:3000');
        // Open the DevTools.
        mainWindow.webContents.openDevTools();
    } else {
        splash.loadURL(
            `file://${path.join(process.resourcesPath, 'splash.html')}`
        );
        mainWindow.loadURL('http://web.ente.io');
    }
    mainWindow.webContents.on('did-fail-load', () => {
        splash.close();
        mainWindow.show();
        isDev
            ? mainWindow.loadFile(`../build/error.html`)
            : splash.loadURL(
                `file://${path.join(process.resourcesPath, 'error.html')}`
            );
    });
    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
        splash.destroy();
    });
    mainWindow.on('close', function (event) {
        if (!isAppQuitting()) {
            event.preventDefault();
            mainWindow.hide();
            const isMac = process.platform === 'darwin'
            isMac && app.dock.hide();
        }
        return false;
    });
    return mainWindow;
}


