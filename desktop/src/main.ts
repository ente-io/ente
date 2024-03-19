import { app, BrowserWindow } from "electron";
import electronReload from "electron-reload";
import serveNextAt from "next-electron-server";
import { initWatcher } from "./services/chokidar";
import { isDev } from "./utils/common";
import { addAllowOriginHeader } from "./utils/cors";
import { createWindow } from "./utils/createWindow";
import { setupAppEventEmitter } from "./utils/events";
import setupIpcComs from "./utils/ipcComms";
import { setupLogging } from "./utils/logging";
import {
    enableSharedArrayBufferSupport,
    handleDockIconHideOnAutoLaunch,
    handleDownloads,
    handleExternalLinks,
    handleUpdates,
    logSystemInfo,
    setupMacWindowOnDockIconClick,
    setupMainMenu,
    setupTrayItem,
} from "./utils/main";

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

/**
 * Hot reload the main process if anything changes in the source directory that
 * we're running from.
 *
 * In particular, this gets triggered when the `tsc -w` rebuilds JS files in the
 * `app/` directory when we change the TS files in the `src/` directory.
 */
const setupMainHotReload = () => {
    if (isDev) {
        electronReload(__dirname, {});
    }
};

/**
 * The URL where the renderer HTML is being served from.
 */
export const rendererURL = "next://app";

/**
 * next-electron-server allows up to directly use the output of `next build` in
 * production mode and `next dev` in development mode, whilst keeping the rest
 * of our code the same.
 *
 * It uses protocol handlers to serve files from the "next://app" protocol
 *
 * - In development this is proxied to http://localhost:3000
 * - In production it serves files from the `/out` directory
 *
 * For more details, see this comparison:
 * https://github.com/HaNdTriX/next-electron-server/issues/5
 */
const setupRendererServer = () => {
    serveNextAt(rendererURL);
};

setupMainHotReload();
setupRendererServer();
setupLogging(isDev);

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
    app.quit();
} else {
    handleDockIconHideOnAutoLaunch();
    enableSharedArrayBufferSupport();
    app.on("second-instance", () => {
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
    app.on("ready", async () => {
        logSystemInfo();
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

    app.on("before-quit", () => setIsAppQuitting(true));
}
