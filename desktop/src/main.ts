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
import { nativeImage } from "electron";
import { app, BrowserWindow, Menu, protocol, Tray } from "electron/main";
import serveNextAt from "next-electron-server";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
    addAllowOriginHeader,
    handleDownloads,
    handleExternalLinks,
} from "./main/init";
import { attachFSWatchIPCHandlers, attachIPCHandlers } from "./main/ipc";
import log, { initLogging } from "./main/log";
import { createApplicationMenu, createTrayContextMenu } from "./main/menu";
import { setupAutoUpdater } from "./main/services/app-update";
import autoLauncher from "./main/services/auto-launcher";
import { createWatcher } from "./main/services/watch";
import { userPreferences } from "./main/stores/user-preferences";
import { migrateLegacyWatchStoreIfNeeded } from "./main/stores/watch";
import { registerStreamProtocol } from "./main/stream";
import { isDev } from "./main/utils-electron";

/**
 * The URL where the renderer HTML is being served from.
 */
export const rendererURL = "ente://app";

/**
 * We want to hide our window instead of closing it when the user presses the
 * cross button on the window.
 *
 * > This is because there is 1. a perceptible initial window creation time for
 * > our app, and 2. because the long running processes like export and watch
 * > folders are tied to the lifetime of the window and otherwise won't run in
 * > the background.
 *
 * Intercepting the window close event and using that to instead hide it is
 * easy, however that prevents the actual app quit to stop working (since the
 * window never gets closed).
 *
 * So to achieve our original goal (hide window instead of closing) without
 * disabling expected app quits, we keep a flag, and we turn it on when we're
 * part of the quit sequence. When this flag is on, we bypass the code that
 * prevents the window from being closed.
 */
let shouldAllowWindowClose = false;

export const allowWindowClose = (): void => {
    shouldAllowWindowClose = true;
};

/**
 * Log a standard startup banner.
 *
 * This helps us identify app starts and other environment details in the logs.
 */
const logStartupBanner = () => {
    const version = isDev ? "dev" : app.getVersion();
    log.info(`Starting ente-photos-desktop ${version}`);

    const platform = process.platform;
    const osRelease = os.release();
    const systemVersion = process.getSystemVersion();
    log.info("Running on", { platform, osRelease, systemVersion });
};

/**
 * next-electron-server allows up to directly use the output of `next build` in
 * production mode and `next dev` in development mode, whilst keeping the rest
 * of our code the same.
 *
 * It uses protocol handlers to serve files from the "ente://" protocol.
 *
 * - In development this is proxied to http://localhost:3000
 * - In production it serves files from the `/out` directory
 *
 * For more details, see this comparison:
 * https://github.com/HaNdTriX/next-electron-server/issues/5
 */
const setupRendererServer = () => serveNextAt(rendererURL);

/**
 * Register privileged schemes.
 *
 * We have two privileged schemes:
 *
 * 1. "ente", used for serving our web app (@see {@link setupRendererServer}).
 *
 * 2. "stream", used for streaming IPC (@see {@link registerStreamProtocol}).
 *
 * Both of these need some privileges, however, the documentation for Electron's
 * [registerSchemesAsPrivileged](https://www.electronjs.org/docs/latest/api/protocol)
 * says:
 *
 * > This method ... can be called only once.
 *
 * The library we use for the "ente" scheme, next-electron-server, already calls
 * it once when we invoke {@link setupRendererServer}.
 *
 * In practice calling it multiple times just causes the values to be
 * overwritten, and the last call wins. So we don't need to modify
 * next-electron-server to prevent it from calling registerSchemesAsPrivileged.
 * Instead, we (a) repeat what next-electron-server had done here, and (b)
 * ensure that we're called after {@link setupRendererServer}.
 */
const registerPrivilegedSchemes = () => {
    protocol.registerSchemesAsPrivileged([
        {
            // Taken verbatim from next-electron-server's code (index.js)
            scheme: "ente",
            privileges: {
                standard: true,
                secure: true,
                allowServiceWorkers: true,
                supportFetchAPI: true,
                corsEnabled: true,
            },
        },
        {
            scheme: "stream",
            privileges: {
                // TODO(MR): Remove the commented bits if we don't end up
                // needing them by the time the IPC refactoring is done.

                // Prevent the insecure origin issues when fetching this
                // secure: true,
                // Allow the web fetch API in the renderer to use this scheme.
                supportFetchAPI: true,
                // Allow it to be used with video tags.
                // stream: true,
            },
        },
    ]);
};

/**
 * [Note: Increased disk cache for the desktop app]
 *
 * Set the "disk-cache-size" command line flag to ask the Chromium process to
 * use a larger size for the caches that it keeps on disk. This allows us to use
 * the web based caching mechanisms on both the web and the desktop app, just
 * ask the embedded Chromium to be a bit more generous in disk usage when
 * running as the desktop app.
 *
 * The size we provide is in bytes.
 * https://www.electronjs.org/docs/latest/api/command-line-switches#--disk-cache-sizesize
 *
 * Note that increasing the disk cache size does not guarantee that Chromium
 * will respect in verbatim, it uses its own heuristics atop this hint.
 * https://superuser.com/questions/378991/what-is-chrome-default-cache-size-limit/1577693#1577693
 *
 * See also: [Note: Caching files].
 */
const increaseDiskCache = () =>
    app.commandLine.appendSwitch(
        "disk-cache-size",
        `${5 * 1024 * 1024 * 1024}`, // 5 GB
    );

/**
 * Create an return the {@link BrowserWindow} that will form our app's UI.
 *
 * This window will show the HTML served from {@link rendererURL}.
 */
const createMainWindow = async () => {
    // Create the main window. This'll show our web content.
    const window = new BrowserWindow({
        webPreferences: {
            preload: path.join(app.getAppPath(), "preload.js"),
            sandbox: true,
        },
        // The color to show in the window until the web content gets loaded.
        // See: https://www.electronjs.org/docs/latest/api/browser-window#setting-the-backgroundcolor-property
        backgroundColor: "black",
        // We'll show it conditionally depending on `wasAutoLaunched` later.
        show: false,
    });

    const wasAutoLaunched = await autoLauncher.wasAutoLaunched();
    if (wasAutoLaunched) {
        // Don't automatically show the app's window if we were auto-launched.
        // On macOS, also hide the dock icon on macOS.
        if (process.platform == "darwin") app.dock.hide();
    } else {
        // Show our window (maximizing it) otherwise.
        window.maximize();
    }

    // Open the DevTools automatically when running in dev mode
    if (isDev) window.webContents.openDevTools();

    window.webContents.on("render-process-gone", (_, details) => {
        log.error(`render-process-gone: ${details}`);
        window.webContents.reload();
    });

    // "The unresponsive event is fired when Chromium detects that your
    //  webContents is not responding to input messages for > 30 seconds."
    window.webContents.on("unresponsive", () => {
        log.error(
            "Main window's webContents are unresponsive, will restart the renderer process",
        );
        window.webContents.forcefullyCrashRenderer();
    });

    window.on("close", (event) => {
        if (!shouldAllowWindowClose) {
            event.preventDefault();
            window.hide();
        }
        return false;
    });

    window.on("hide", () => {
        // On macOS, when hiding the window also hide the app's icon in the dock
        // if the user has selected the Settings > Hide dock icon checkbox.
        if (process.platform == "darwin" && userPreferences.get("hideDockIcon"))
            app.dock.hide();
    });

    window.on("show", () => {
        if (process.platform == "darwin") app.dock.show();
    });

    // Let ipcRenderer know when mainWindow is in the foreground so that it can
    // in turn inform the renderer process.
    window.on("focus", () => window.webContents.send("mainWindowFocus"));

    return window;
};

/**
 * Add an icon for our app in the system tray.
 *
 * For example, these are the small icons that appear on the top right of the
 * screen in the main menu bar on macOS.
 */
const setupTrayItem = (mainWindow: BrowserWindow) => {
    // There are a total of 6 files corresponding to this tray icon.
    //
    // On macOS, use template images (filename needs to end with "Template.ext")
    // https://www.electronjs.org/docs/latest/api/native-image#template-image-macos
    //
    // And for each (template or otherwise), there are 3 "retina" variants
    // https://www.electronjs.org/docs/latest/api/native-image#high-resolution-image
    const iconName =
        process.platform == "darwin"
            ? "taskbar-icon-Template.png"
            : "taskbar-icon.png";
    const trayImgPath = path.join(
        isDev ? "build" : process.resourcesPath,
        iconName,
    );
    const trayIcon = nativeImage.createFromPath(trayImgPath);
    const tray = new Tray(trayIcon);
    tray.setToolTip("Ente Photos");
    tray.setContextMenu(createTrayContextMenu(mainWindow));
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

/**
 * Older versions of our app used to keep a keys.json. It is not needed anymore,
 * remove it if it exists.
 *
 * This code was added March 2024, and can be removed after some time once most
 * people have upgraded to newer versions.
 */
const deleteLegacyKeysStoreIfExists = async () => {
    const keysStore = path.join(app.getPath("userData"), "keys.json");
    if (existsSync(keysStore)) {
        log.info(`Removing legacy keys store at ${keysStore}`);
        await fs.rm(keysStore);
    }
};

const main = () => {
    const gotTheLock = app.requestSingleInstanceLock();
    if (!gotTheLock) {
        app.quit();
        return;
    }

    let mainWindow: BrowserWindow | undefined;

    initLogging();
    logStartupBanner();
    // The order of the next two calls is important
    setupRendererServer();
    registerPrivilegedSchemes();
    increaseDiskCache();
    migrateLegacyWatchStoreIfNeeded();

    app.on("second-instance", () => {
        // Someone tried to run a second instance, we should focus our window.
        if (mainWindow) {
            mainWindow.show();
            if (mainWindow.isMinimized()) mainWindow.restore();
            mainWindow.focus();
        }
    });

    // Emitted once, when Electron has finished initializing.
    //
    // Note that some Electron APIs can only be used after this event occurs.
    app.on("ready", async () => {
        // Create window and prepare for renderer
        mainWindow = await createMainWindow();
        attachIPCHandlers();
        attachFSWatchIPCHandlers(createWatcher(mainWindow));
        registerStreamProtocol();
        handleDownloads(mainWindow);
        handleExternalLinks(mainWindow);
        addAllowOriginHeader(mainWindow);

        // Start loading the renderer
        mainWindow.loadURL(rendererURL);

        // Continue on with the rest of the startup sequence
        Menu.setApplicationMenu(await createApplicationMenu(mainWindow));
        setupTrayItem(mainWindow);
        if (!isDev) setupAutoUpdater(mainWindow);

        try {
            deleteLegacyDiskCacheDirIfExists();
            deleteLegacyKeysStoreIfExists();
        } catch (e) {
            // Log but otherwise ignore errors during non-critical startup
            // actions.
            log.error("Ignoring startup error", e);
        }
    });

    // This is a macOS only event. Show our window when the user activates the
    // app, e.g. by clicking on its dock icon.
    app.on("activate", () => mainWindow?.show());

    app.on("before-quit", allowWindowClose);
};

main();
