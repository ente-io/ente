import { app, BrowserWindow, Menu, nativeImage, Tray } from "electron";
import ElectronLog from "electron-log";
import os from "os";
import path from "path";
import { existsSync } from "promise-fs";
import util from "util";
import { rendererURL } from "../main";
import { setupAutoUpdater } from "../services/appUpdater";
import autoLauncher from "../services/autoLauncher";
import { getHideDockIconPreference } from "../services/userPreference";
import { isDev } from "./common";
import { isPlatform } from "./common/platform";
import { buildContextMenu, buildMenuBar } from "./menu";
const execAsync = util.promisify(require("child_process").exec);

export async function handleUpdates(mainWindow: BrowserWindow) {
    const isInstalledViaBrew = await checkIfInstalledViaBrew();
    if (!isDev && !isInstalledViaBrew) {
        setupAutoUpdater(mainWindow);
    }
}
export function setupTrayItem(mainWindow: BrowserWindow) {
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
    return tray;
}

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

export function enableSharedArrayBufferSupport() {
    app.commandLine.appendSwitch("enable-features", "SharedArrayBuffer");
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
