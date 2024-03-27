/**
 * @file Entry point for the main (Node.js) process of our Electron app.
 *
 * The code in this file is invoked by Electron when our app starts -
 * Conceptually (after all the transpilation etc has happened) this can be
 * thought of `electron main.ts`. We're running in the context of the so called
 * "main" process which runs in a Node.js environment.
 *
 * https://www.electronjs.org/docs/latest/tutorial/process-model#the-main-process
 */
import { app, BrowserWindow, Menu } from "electron/main";
import serveNextAt from "next-electron-server";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import {
    addAllowOriginHeader,
    createWindow,
    handleDockIconHideOnAutoLaunch,
    handleDownloads,
    handleExternalLinks,
    logStartupBanner,
    setupMacWindowOnDockIconClick,
    setupTrayItem,
} from "./main/init";
import { attachFSWatchIPCHandlers, attachIPCHandlers } from "./main/ipc";
import log, { initLogging } from "./main/log";
import { createApplicationMenu } from "./main/menu";
import { isDev } from "./main/util";
import { setupAutoUpdater } from "./services/appUpdater";
import { initWatcher } from "./services/chokidar";

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

function enableSharedArrayBufferSupport() {
    app.commandLine.appendSwitch("enable-features", "SharedArrayBuffer");
}

/**
 * [Note: Increased disk cache for the desktop app]
 *
 * Set the "disk-cache-size" command line flag to ask the Chromium process to
 * use a larger size for the caches that it keeps on disk. This allows us to use
 * the same web-native caching mechanism on both the web and the desktop app,
 * just ask the embedded Chromium to be a bit more generous in disk usage when
 * running as the desktop app.
 *
 * The size we provide is in bytes. We set it to a large value, 5 GB (5 * 1024 *
 * 1024 * 1024 = 5368709120)
 * https://www.electronjs.org/docs/latest/api/command-line-switches#--disk-cache-sizesize
 *
 * Note that increasing the disk cache size does not guarantee that Chromium
 * will respect in verbatim, it uses its own heuristics atop this hint.
 * https://superuser.com/questions/378991/what-is-chrome-default-cache-size-limit/1577693#1577693
 */
const increaseDiskCache = () => {
    app.commandLine.appendSwitch("disk-cache-size", "5368709120");
};

/**
 * Older versions of our app used to maintain a cache dir using the main
 * process. This has been deprecated in favor of using a normal web cache.
 *
 * See [Note: Increased disk cache for the desktop app]
 *
 * Delete the old cache dir if it exists. This code was added March 2024, and
 * can be removed after some time once most people have upgraded to newer
 * versions.
 */
const deleteLegacyDiskCacheDirIfExists = async () => {
    // The existing code was passing "cache" as a parameter to getPath. This is
    // incorrect if we go by the types - "cache" is not a valid value for the
    // parameter to `app.getPath`.
    //
    // It might be an issue in the types, since at runtime it seems to work. For
    // example, on macOS I get `~/Library/Caches`.
    //
    // Irrespective, we replicate the original behaviour so that we get back the
    // same path that the old got was getting.
    //
    // @ts-expect-error
    const cacheDir = path.join(app.getPath("cache"), "ente");
    if (existsSync(cacheDir)) {
        log.info(`Removing legacy disk cache from ${cacheDir}`);
        await fs.rm(cacheDir, { recursive: true });
    }
};

function setupAppEventEmitter(mainWindow: BrowserWindow) {
    // fire event when mainWindow is in foreground
    mainWindow.on("focus", () => {
        mainWindow.webContents.send("app-in-foreground");
    });
}

const main = () => {
    const gotTheLock = app.requestSingleInstanceLock();
    if (!gotTheLock) {
        app.quit();
        return;
    }

    let mainWindow: BrowserWindow;

    initLogging();
    setupRendererServer();
    handleDockIconHideOnAutoLaunch();
    increaseDiskCache();
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

    // Emitted once, when Electron has finished initializing.
    //
    // Note that some Electron APIs can only be used after this event occurs.
    app.on("ready", async () => {
        logStartupBanner();
        mainWindow = await createWindow();
        const watcher = initWatcher(mainWindow);
        setupTrayItem(mainWindow);
        setupMacWindowOnDockIconClick();
        Menu.setApplicationMenu(await createApplicationMenu(mainWindow));
        attachIPCHandlers();
        attachFSWatchIPCHandlers(watcher);
        if (!isDev) setupAutoUpdater(mainWindow);
        handleDownloads(mainWindow);
        handleExternalLinks(mainWindow);
        addAllowOriginHeader(mainWindow);
        setupAppEventEmitter(mainWindow);

        try {
            deleteLegacyDiskCacheDirIfExists();
        } catch (e) {
            // Log but otherwise ignore errors during non-critical startup
            // actions
            log.error("Ignoring startup error", e);
        }
    });

    app.on("before-quit", () => setIsAppQuitting(true));
};

main();
