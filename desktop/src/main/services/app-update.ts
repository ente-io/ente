import { compareVersions } from "compare-versions";
import { app, BrowserWindow } from "electron";
import { default as electronLog } from "electron-log";
import { autoUpdater } from "electron-updater";
import { allowWindowClose } from "../../main";
import { AppUpdateInfo } from "../../types/ipc";
import log from "../log";
import { userPreferences } from "../stores/user-preferences";

export const setupAutoUpdater = (mainWindow: BrowserWindow) => {
    autoUpdater.logger = electronLog;
    autoUpdater.autoDownload = false;

    const oneDay = 1 * 24 * 60 * 60 * 1000;
    setInterval(() => checkForUpdatesAndNotify(mainWindow), oneDay);
    checkForUpdatesAndNotify(mainWindow);
};

/**
 * Check for app update check ignoring any previously saved skips / mutes.
 */
export const forceCheckForAppUpdates = (mainWindow: BrowserWindow) => {
    userPreferences.delete("skipAppVersion");
    userPreferences.delete("muteUpdateNotificationVersion");
    checkForUpdatesAndNotify(mainWindow);
};

const checkForUpdatesAndNotify = async (mainWindow: BrowserWindow) => {
    const updateCheckResult = await autoUpdater.checkForUpdates();
    if (!updateCheckResult) {
        log.error("Failed to check for updates");
        return;
    }

    const { version } = updateCheckResult.updateInfo;

    log.debug(() => `Update check found version ${version}`);

    if (compareVersions(version, app.getVersion()) <= 0) {
        log.debug(() => "Skipping update, already at latest version");
        return;
    }

    if (version === userPreferences.get("skipAppVersion")) {
        log.info(`User chose to skip version ${version}`);
        return;
    }

    const mutedVersion = userPreferences.get("muteUpdateNotificationVersion");
    if (version === mutedVersion) {
        log.info(`User has muted update notifications for version ${version}`);
        return;
    }

    const showUpdateDialog = (updateInfo: AppUpdateInfo) =>
        mainWindow.webContents.send("appUpdateAvailable", updateInfo);

    log.debug(() => "Attempting auto update");
    autoUpdater.downloadUpdate();

    let timeout: NodeJS.Timeout;
    const fiveMinutes = 5 * 60 * 1000;
    autoUpdater.on("update-downloaded", () => {
        timeout = setTimeout(
            () => showUpdateDialog({ autoUpdatable: true, version }),
            fiveMinutes,
        );
    });

    autoUpdater.on("error", (error) => {
        clearTimeout(timeout);
        log.error("Auto update failed", error);
        showUpdateDialog({ autoUpdatable: false, version });
    });
};

/**
 * Return the version of the desktop app
 *
 * The return value is of the form `v1.2.3`.
 */
export const appVersion = () => `v${app.getVersion()}`;

export const updateAndRestart = () => {
    log.info("Restarting the app to apply update");
    allowWindowClose();
    autoUpdater.quitAndInstall();
};

export const updateOnNextRestart = (version: string) =>
    userPreferences.set("muteUpdateNotificationVersion", version);

export const skipAppUpdate = (version: string) =>
    userPreferences.set("skipAppVersion", version);
