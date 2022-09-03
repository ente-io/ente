import { app, BrowserWindow, nativeImage } from 'electron';
import * as path from 'path';
import { isDev } from './common';
import { isAppQuitting } from '../main';
import { PROD_HOST_URL } from '../config';
import { isPlatformMac } from './main';
import { getHideDockIconPreference } from '../services/userPreference';

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
            contextIsolation: false,
        },
        icon: appIcon,
        show: false, // don't show the main window on load
    });
    mainWindow.maximize();
    const splash = new BrowserWindow({
        height: 600,
        width: 800,
        transparent: true,
    });
    splash.maximize();

    if (isDev) {
        splash.loadFile(`../build/splash.html`);
        mainWindow.loadURL(PROD_HOST_URL);
        // Open the DevTools.
        mainWindow.webContents.openDevTools();
    } else {
        splash.loadURL(
            `file://${path.join(process.resourcesPath, 'splash.html')}`
        );
        mainWindow.loadURL(PROD_HOST_URL);
    }
    mainWindow.webContents.on('did-fail-load', () => {
        splash.close();
        mainWindow.show();
        isDev
            ? mainWindow.loadFile(`../../build/error.html`)
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
        }
        return false;
    });
    mainWindow.on('hide', () => {
        const shouldHideDockIcon = getHideDockIconPreference();
        if (isPlatformMac() && shouldHideDockIcon) {
            app.dock.hide();
        }
    });
    mainWindow.on('show', () => {
        if (isPlatformMac()) {
            app.dock.show();
        }
    });
    return mainWindow;
}
