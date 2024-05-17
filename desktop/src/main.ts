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

import { nativeImage, shell } from "electron/common";
import type { WebContents } from "electron/main";
import { BrowserWindow, Menu, Tray, app, protocol } from "electron/main";
import serveNextAt from "next-electron-server";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
    attachFSWatchIPCHandlers,
    attachIPCHandlers,
    attachLogoutIPCHandler,
} from "./main/ipc";
import log, { initLogging } from "./main/log";
import { createApplicationMenu, createTrayContextMenu } from "./main/menu";
import { setupAutoUpdater } from "./main/services/app-update";
import autoLauncher from "./main/services/auto-launcher";
import { createWatcher } from "./main/services/watch";
import { userPreferences } from "./main/stores/user-preferences";
import { migrateLegacyWatchStoreIfNeeded } from "./main/stores/watch";
import { registerStreamProtocol } from "./main/stream";
import { isDev } from "./main/utils/electron";

/**
 * The URL where the renderer HTML is being served from.
 */
const rendererURL = "ente://app";

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
                supportFetchAPI: true,
            },
        },
    ]);
};

/**
 * Create an return the {@link BrowserWindow} that will form our app's UI.
 *
 * This window will show the HTML served from {@link rendererURL}.
 */
const createMainWindow = () => {
    // Create the main window. This'll show our web content.
    const window = new BrowserWindow({
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            sandbox: true,
        },
        // The color to show in the window until the web content gets loaded.
        // See: https://www.electronjs.org/docs/latest/api/browser-window#setting-the-backgroundcolor-property
        backgroundColor: "black",
        // We'll show it conditionally depending on `wasAutoLaunched` later.
        show: false,
    });

    const wasAutoLaunched = autoLauncher.wasAutoLaunched();
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
        log.error(`render-process-gone: ${details.reason}`);
        window.webContents.reload();
    });

    // "The unresponsive event is fired when Chromium detects that your
    //  webContents is not responding to input messages for > 30 seconds."
    window.webContents.on("unresponsive", () => {
        log.error(
            "MainWindow's webContents are unresponsive, will restart the renderer process",
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
        if (process.platform == "darwin") void app.dock.show();
    });

    // Let ipcRenderer know when mainWindow is in the foreground so that it can
    // in turn inform the renderer process.
    window.on("focus", () => window.webContents.send("mainWindowFocus"));

    return window;
};

/**
 * Automatically set the save path for user initiated downloads to the system's
 * "downloads" directory instead of asking the user to select a save location.
 */
export const setDownloadPath = (webContents: WebContents) => {
    webContents.session.on("will-download", (_, item) => {
        item.setSavePath(
            uniqueSavePath(app.getPath("downloads"), item.getFilename()),
        );
    });
};

const uniqueSavePath = (dirPath: string, fileName: string) => {
    const { name, ext } = path.parse(fileName);

    let savePath = path.join(dirPath, fileName);
    let n = 1;
    while (existsSync(savePath)) {
        const suffixedName = [`${name}(${n})`, ext].filter((x) => x).join(".");
        savePath = path.join(dirPath, suffixedName);
        n++;
    }
    return savePath;
};

/**
 * Allow opening external links, e.g. when the user clicks on the "Feature
 * requests" button in the sidebar (to open our GitHub repository), or when they
 * click the "Support" button to send an email to support.
 *
 * @param webContents The renderer to configure.
 */
export const allowExternalLinks = (webContents: WebContents) =>
    // By default, if the user were open a link, say
    // https://github.com/ente-io/ente/discussions, then it would open a _new_
    // BrowserWindow within our app.
    //
    // This is not the behaviour we want; what we want is to ask the system to
    // handle the link (e.g. open the URL in the default browser, or if it is a
    // mailto: link, then open the user's mail client).
    //
    // Returning `action` "deny" accomplishes this.
    webContents.setWindowOpenHandler(({ url }) => {
        if (!url.startsWith(rendererURL)) {
            // This does not work in Ubuntu currently: mailto links seem to just
            // get ignored, and HTTP links open in the text editor instead of in
            // the browser.
            // https://github.com/electron/electron/issues/31485
            void shell.openExternal(url);
            return { action: "deny" };
        } else {
            return { action: "allow" };
        }
    });

/**
 * Allow uploading to arbitrary S3 buckets.
 *
 * The files in the desktop app are served over the ente:// protocol. During
 * testing or self-hosting, we might be using a S3 bucket that does not allow
 * whitelisting a custom URI scheme. To avoid requiring the bucket to set an
 * "Access-Control-Allow-Origin: *" or do a echo-back of `Origin`, we add a
 * workaround here instead, intercepting the ACAO header and allowing `*`.
 */
export const allowAllCORSOrigins = (webContents: WebContents) =>
    webContents.session.webRequest.onHeadersReceived(
        ({ responseHeaders }, callback) => {
            const headers: NonNullable<typeof responseHeaders> = {};
            for (const [key, value] of Object.entries(responseHeaders ?? {}))
                if (key.toLowerCase() != "access-control-allow-origin")
                    headers[key] = value;
            headers["Access-Control-Allow-Origin"] = ["*"];
            callback({ responseHeaders: headers });
        },
    );

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
 * process. This has been removed in favor of cache on the web layer.
 *
 * Delete the old cache dir if it exists.
 *
 * This will happen in two phases. The cache had three subdirectories:
 *
 * - Two of them, "thumbs" and "files", will be removed now (v1.7.0, May 2024).
 *
 * - The third one, "face-crops" will be removed once we finish the face search
 *   changes. See: [Note: Legacy face crops].
 *
 * This migration code can be removed after some time once most people have
 * upgraded to newer versions.
 */
const deleteLegacyDiskCacheDirIfExists = async () => {
    const removeIfExists = async (dirPath: string) => {
        if (existsSync(dirPath)) {
            log.info(`Removing legacy disk cache from ${dirPath}`);
            await fs.rm(dirPath, { recursive: true });
        }
    };
    // [Note: Getting the cache path]
    //
    // The existing code was passing "cache" as a parameter to getPath.
    //
    // However, "cache" is not a valid parameter to getPath. It works! (for
    // example, on macOS I get `~/Library/Caches`), but it is intentionally not
    // documented as part of the public API:
    //
    // - docs: remove "cache" from app.getPath
    //   https://github.com/electron/electron/pull/33509
    //
    // Irrespective, we replicate the original behaviour so that we get back the
    // same path that the old code was getting.
    //
    // @ts-expect-error "cache" works but is not part of the public API.
    const cacheDir = path.join(app.getPath("cache"), "ente");
    if (existsSync(cacheDir)) {
        await removeIfExists(path.join(cacheDir, "thumbs"));
        await removeIfExists(path.join(cacheDir, "files"));
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
    void app.whenReady().then(() => {
        void (async () => {
            // Create window and prepare for the renderer.
            mainWindow = createMainWindow();

            // Setup IPC and streams.
            const watcher = createWatcher(mainWindow);
            attachIPCHandlers();
            attachFSWatchIPCHandlers(watcher);
            attachLogoutIPCHandler(watcher);
            registerStreamProtocol();

            // Configure the renderer's environment.
            const webContents = mainWindow.webContents;
            setDownloadPath(webContents);
            allowExternalLinks(webContents);
            allowAllCORSOrigins(webContents);

            // Start loading the renderer.
            void mainWindow.loadURL(rendererURL);

            // Continue on with the rest of the startup sequence.
            Menu.setApplicationMenu(await createApplicationMenu(mainWindow));
            setupTrayItem(mainWindow);
            setupAutoUpdater(mainWindow);

            try {
                await deleteLegacyDiskCacheDirIfExists();
                await deleteLegacyKeysStoreIfExists();
            } catch (e) {
                // Log but otherwise ignore errors during non-critical startup
                // actions.
                log.error("Ignoring startup error", e);
            }
        })();
    });

    // This is a macOS only event. Show our window when the user activates the
    // app, e.g. by clicking on its dock icon.
    app.on("activate", () => mainWindow?.show());

    app.on("before-quit", allowWindowClose);
};

main();
