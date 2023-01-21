import { app, BrowserWindow, nativeImage } from 'electron';
import * as path from 'path';
import { isDev } from './common';
import { isAppQuitting } from '../main';
import { PROD_HOST_URL } from '../config';
import { isPlatform } from './main';
import { getHideDockIconPreference } from '../services/userPreference';
import autoLauncher from '../services/autoLauncher';
import ElectronLog from 'electron-log';

export async function createWindow(): Promise<BrowserWindow> {
    const appImgPath = isDev
        ? 'build/window-icon.png'
        : path.join(process.resourcesPath, 'window-icon.png');
    const appIcon = nativeImage.createFromPath(appImgPath);
    // Create the browser window.
    const mainWindow = new BrowserWindow({
        height: 600,
        width: 800,
        webPreferences: {
            sandbox: false,
            preload: path.join(__dirname, '../preload.js'),
            contextIsolation: false,
        },
        icon: appIcon,
        show: false, // don't show the main window on load,
    });
    mainWindow.maximize();
    const wasAutoLaunched = await autoLauncher.wasAutoLaunched();

    const splash = new BrowserWindow({
        height: 600,
        width: 800,
        transparent: true,
        show: !wasAutoLaunched,
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
        isDev
            ? mainWindow.loadFile(`../../build/error.html`)
            : splash.loadURL(
                  `file://${path.join(process.resourcesPath, 'error.html')}`
              );
    });
    mainWindow.once('ready-to-show', async () => {
        try {
            splash.destroy();
            if (!wasAutoLaunched) {
                mainWindow.show();
            }
        } catch (e) {
            // ignore
        }
    });
    mainWindow.webContents.on('render-process-gone', (event, details) => {
        ElectronLog.log('webContents event render-process-gone', details);
    });
    mainWindow.webContents.on('destroyed', () => {
        ElectronLog.log('webContents event destroyed');
    });
    mainWindow.webContents.on('unresponsive', () => {
        ElectronLog.log('webContents event unresponsive');
    });

    setTimeout(() => {
        try {
            splash.destroy();
            if (!wasAutoLaunched) {
                mainWindow.show();
            }
        } catch (e) {
            // ignore
        }
    }, 2000);
    mainWindow.on('close', function (event) {
        if (!isAppQuitting()) {
            event.preventDefault();
            mainWindow.hide();
        }
        return false;
    });
    mainWindow.on('hide', () => {
        const shouldHideDockIcon = getHideDockIconPreference();
        if (isPlatform('mac') && shouldHideDockIcon) {
            app.dock.hide();
        }
    });
    mainWindow.on('show', () => {
        if (isPlatform('mac')) {
            app.dock.show();
        }
    });
    return mainWindow;
}
