import { app, BrowserWindow, nativeImage } from "electron";
import ElectronLog from "electron-log";
import * as path from "path";
import { isAppQuitting, rendererURL } from "../main";
import autoLauncher from "../services/autoLauncher";
import { logErrorSentry } from "../services/sentry";
import { getHideDockIconPreference } from "../services/userPreference";
import { isDev } from "./common";
import { isPlatform } from "./common/platform";

/**
 * Create an return the {@link BrowserWindow} that will form our app's UI.
 *
 * This window will show the HTML served from {@link rendererURL}.
 */
export const createWindow = async () => {
    const appImgPath = isDev
        ? "resources/window-icon.png"
        : path.join(process.resourcesPath, "window-icon.png");
    const appIcon = nativeImage.createFromPath(appImgPath);
    // Create the browser window.
    const mainWindow = new BrowserWindow({
        webPreferences: {
            preload: path.join(__dirname, "../preload.js"),
        },
        icon: appIcon,
        show: false, // don't show the main window on load,
    });
    const wasAutoLaunched = await autoLauncher.wasAutoLaunched();
    ElectronLog.log("wasAutoLaunched", wasAutoLaunched);

    const splash = new BrowserWindow({
        transparent: true,
        show: false,
    });
    if (isPlatform("mac") && wasAutoLaunched) {
        app.dock.hide();
    }
    if (!wasAutoLaunched) {
        splash.maximize();
        splash.show();
    }

    if (isDev) {
        splash.loadFile(`../resources/splash.html`);
        mainWindow.loadURL(rendererURL);
        // Open the DevTools.
        mainWindow.webContents.openDevTools();
    } else {
        splash.loadURL(
            `file://${path.join(process.resourcesPath, "splash.html")}`,
        );
        mainWindow.loadURL(rendererURL);
    }
    mainWindow.once("ready-to-show", async () => {
        try {
            splash.destroy();
            if (!wasAutoLaunched) {
                mainWindow.maximize();
                mainWindow.show();
            }
        } catch (e) {
            // ignore
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
            splash.destroy();
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
        const shouldHideDockIcon = getHideDockIconPreference();
        if (isPlatform("mac") && shouldHideDockIcon) {
            app.dock.hide();
        }
    });
    mainWindow.on("show", () => {
        if (isPlatform("mac")) {
            app.dock.show();
        }
    });
    return mainWindow;
};
