import { app, BrowserWindow, Menu, nativeImage, Tray } from "electron";
import ElectronLog from "electron-log";
import { existsSync } from "node:fs";
import os from "os";
import path from "path";
import util from "util";
import { isAppQuitting, rendererURL } from "../main";
import { setupAutoUpdater } from "../services/appUpdater";
import autoLauncher from "../services/autoLauncher";
import { getHideDockIconPreference } from "../services/userPreference";
import { isPlatform } from "../utils/common/platform";
import { buildContextMenu, buildMenuBar } from "../utils/menu";
import { isDev } from "./general";
import { logErrorSentry } from "./log";
const execAsync = util.promisify(require("child_process").exec);

/**
 * Create an return the {@link BrowserWindow} that will form our app's UI.
 *
 * This window will show the HTML served from {@link rendererURL}.
 */
export const createWindow = async () => {
    const appImgPath = isDev
        ? "../build/window-icon.png"
        : path.join(process.resourcesPath, "window-icon.png");
    const appIcon = nativeImage.createFromPath(appImgPath);

    // Create the main window. This'll show our web content.
    const mainWindow = new BrowserWindow({
        webPreferences: {
            preload: path.join(app.getAppPath(), "preload.js"),
        },
        icon: appIcon,
        // Don't show the main window on load, we'll show the `splashWindow`
        // instead until it gets ready-to-show.
        show: false,
    });

    const wasAutoLaunched = await autoLauncher.wasAutoLaunched();
    ElectronLog.log("wasAutoLaunched", wasAutoLaunched);

    // Create a splash window to show until the web content loads.
    const splashWindow = new BrowserWindow({
        transparent: true,
        show: false,
    });

    if (process.platform == "darwin" && wasAutoLaunched) {
        app.dock.hide();
    }

    if (!wasAutoLaunched) {
        splashWindow.maximize();
        splashWindow.show();
    }

    if (isDev) {
        splashWindow.loadFile("../build/splash.html");
    } else {
        const splashHTMLPath = path.join(process.resourcesPath, "splash.html");
        splashWindow.loadURL(`file://${splashHTMLPath}`);
    }

    mainWindow.loadURL(rendererURL);

    // Open the DevTools automatically when running in dev mode
    if (isDev) mainWindow.webContents.openDevTools();

    mainWindow.once("ready-to-show", async () => {
        splashWindow.destroy();
        if (!wasAutoLaunched) {
            mainWindow.maximize();
            mainWindow.show();
        }
    });

    mainWindow.webContents.on("render-process-gone", (event, details) => {
        mainWindow.webContents.reload();
        logErrorSentry(
            Error("render-process-gone"),
            "webContents event render-process-gone",
            { details },
        );
        ElectronLog.log("webContents event render-process-gone", details);
    });

    mainWindow.webContents.on("unresponsive", () => {
        mainWindow.webContents.forcefullyCrashRenderer();
        ElectronLog.log("webContents event unresponsive");
    });

    setTimeout(() => {
        try {
            splashWindow.destroy();
            if (!wasAutoLaunched) {
                mainWindow.maximize();
                mainWindow.show();
            }
        } catch (e) {
            // ignore
        }
    }, 2000);

    mainWindow.on("close", function (event) {
        if (!isAppQuitting()) {
            event.preventDefault();
            mainWindow.hide();
        }
        return false;
    });

    mainWindow.on("hide", () => {
        // On macOS, also hide the app's icon in the dock if the user has
        // selected the Settings > Hide dock icon checkbox.
        const shouldHideDockIcon = getHideDockIconPreference();
        if (process.platform == "darwin" && shouldHideDockIcon) {
            app.dock.hide();
        }
    });

    mainWindow.on("show", () => {
        if (process.platform == "darwin") app.dock.show();
    });

    return mainWindow;
};

/**
 * Return the source root for the desktop code, i.e. the "desktop" directory in
 * our repository which contains the package.json.
 *
 * This is useful to
 */
const srcRoot = () => {
    // __dirname will be the directory which contains this file. However, this
    // file is not the one which is running - it'll get transpiled into JS, so
    // the actual running file will be `app/main/init.js`. To get to the source
    // root (the "desktop" folder), we need to go up two levels.
};
export async function handleUpdates(mainWindow: BrowserWindow) {
    const isInstalledViaBrew = await checkIfInstalledViaBrew();
    if (!isDev && !isInstalledViaBrew) {
        setupAutoUpdater(mainWindow);
    }
}

export const setupTrayItem = (mainWindow: BrowserWindow) => {
    const iconName = isPlatform("mac")
        ? "taskbar-icon-Template.png"
        : "taskbar-icon.png";
    const trayImgPath = path.join(
        isDev ? "build" : process.resourcesPath,
        iconName,
    );
    const trayIcon = nativeImage.createFromPath(trayImgPath);
    const tray = new Tray(trayIcon);
    tray.setToolTip("ente");
    tray.setContextMenu(buildContextMenu(mainWindow));
};

export function handleDownloads(mainWindow: BrowserWindow) {
    mainWindow.webContents.session.on("will-download", (_, item) => {
        item.setSavePath(
            getUniqueSavePath(item.getFilename(), app.getPath("downloads")),
        );
    });
}

export function handleExternalLinks(mainWindow: BrowserWindow) {
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        if (!url.startsWith(rendererURL)) {
            require("electron").shell.openExternal(url);
            return { action: "deny" };
        } else {
            return { action: "allow" };
        }
    });
}

export function getUniqueSavePath(filename: string, directory: string): string {
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
            .join("");
        uniqueFileSavePath = path.join(directory, fileNameWithNumberedSuffix);
    }
    return uniqueFileSavePath;
}

export function setupMacWindowOnDockIconClick() {
    app.on("activate", function () {
        const windows = BrowserWindow.getAllWindows();
        // we allow only one window
        windows[0].show();
    });
}

export async function setupMainMenu(mainWindow: BrowserWindow) {
    Menu.setApplicationMenu(await buildMenuBar(mainWindow));
}

export async function handleDockIconHideOnAutoLaunch() {
    const shouldHideDockIcon = getHideDockIconPreference();
    const wasAutoLaunched = await autoLauncher.wasAutoLaunched();

    if (isPlatform("mac") && shouldHideDockIcon && wasAutoLaunched) {
        app.dock.hide();
    }
}

export function logSystemInfo() {
    const systemVersion = process.getSystemVersion();
    const osName = process.platform;
    const osRelease = os.release();
    ElectronLog.info({ osName, osRelease, systemVersion });
    const appVersion = app.getVersion();
    ElectronLog.info({ appVersion });
}

export async function checkIfInstalledViaBrew() {
    if (!isPlatform("mac")) {
        return false;
    }
    try {
        await execAsync("brew list --cask ente");
        ElectronLog.info("ente installed via brew");
        return true;
    } catch (e) {
        ElectronLog.info("ente not installed via brew");
        return false;
    }
}

function lowerCaseHeaders(responseHeaders: Record<string, string[]>) {
    const headers: Record<string, string[]> = {};
    for (const key of Object.keys(responseHeaders)) {
        headers[key.toLowerCase()] = responseHeaders[key];
    }
    return headers;
}

export function addAllowOriginHeader(mainWindow: BrowserWindow) {
    mainWindow.webContents.session.webRequest.onHeadersReceived(
        (details, callback) => {
            details.responseHeaders = lowerCaseHeaders(details.responseHeaders);
            details.responseHeaders["access-control-allow-origin"] = ["*"];
            callback({
                responseHeaders: details.responseHeaders,
            });
        },
    );
}
