import { compareVersions } from "compare-versions";
import { app, BrowserWindow } from "electron";
import { default as electronLog } from "electron-log";
import { autoUpdater } from "electron-updater";
import { setIsAppQuitting, setIsUpdateAvailable } from "../main";
import log from "../main/log";
import { AppUpdateInfo } from "../types/ipc";
import {
    clearMuteUpdateNotificationVersion,
    clearSkipAppVersion,
    getMuteUpdateNotificationVersion,
    getSkipAppVersion,
    setMuteUpdateNotificationVersion,
    setSkipAppVersion,
} from "./userPreference";

const FIVE_MIN_IN_MICROSECOND = 5 * 60 * 1000;
const ONE_DAY_IN_MICROSECOND = 1 * 24 * 60 * 60 * 1000;

export function setupAutoUpdater(mainWindow: BrowserWindow) {
    autoUpdater.logger = electronLog;
    autoUpdater.autoDownload = false;
    checkForUpdateAndNotify(mainWindow);
    setInterval(
        () => checkForUpdateAndNotify(mainWindow),
        ONE_DAY_IN_MICROSECOND,
    );
}

export function forceCheckForUpdateAndNotify(mainWindow: BrowserWindow) {
    try {
        clearSkipAppVersion();
        clearMuteUpdateNotificationVersion();
        checkForUpdateAndNotify(mainWindow);
    } catch (e) {
        log.error("forceCheckForUpdateAndNotify failed", e);
    }
}

async function checkForUpdateAndNotify(mainWindow: BrowserWindow) {
    try {
        log.debug(() => "checkForUpdateAndNotify");
        const { updateInfo } = await autoUpdater.checkForUpdates();
        log.debug(() => `Update version ${updateInfo.version}`);
        if (compareVersions(updateInfo.version, app.getVersion()) <= 0) {
            log.debug(() => "Skipping update, already at latest version");
            return;
        }
        const skipAppVersion = getSkipAppVersion();
        if (skipAppVersion && updateInfo.version === skipAppVersion) {
            log.info(`User chose to skip version ${updateInfo.version}`);
            return;
        }

        let timeout: NodeJS.Timeout;
        log.debug(() => "Attempting auto update");
        autoUpdater.downloadUpdate();
        const muteUpdateNotificationVersion =
            getMuteUpdateNotificationVersion();
        if (
            muteUpdateNotificationVersion &&
            updateInfo.version === muteUpdateNotificationVersion
        ) {
            log.info(
                `User has muted update notifications for version ${updateInfo.version}`,
            );
            return;
        }
        autoUpdater.on("update-downloaded", () => {
            timeout = setTimeout(
                () =>
                    showUpdateDialog(mainWindow, {
                        autoUpdatable: true,
                        version: updateInfo.version,
                    }),
                FIVE_MIN_IN_MICROSECOND,
            );
        });
        autoUpdater.on("error", (error) => {
            clearTimeout(timeout);
            log.error("Auto update failed", error);
            showUpdateDialog(mainWindow, {
                autoUpdatable: false,
                version: updateInfo.version,
            });
        });

        setIsUpdateAvailable(true);
    } catch (e) {
        log.error("checkForUpdateAndNotify failed", e);
    }
}

export function updateAndRestart() {
    log.info("user quit the app");
    setIsAppQuitting(true);
    autoUpdater.quitAndInstall();
}

/**
 * Return the version of the desktop app
 *
 * The return value is of the form `v1.2.3`.
 */
export const appVersion = () => `v${app.getVersion()}`;

export function skipAppUpdate(version: string) {
    setSkipAppVersion(version);
}

export function muteUpdateNotification(version: string) {
    setMuteUpdateNotificationVersion(version);
}

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo,
) {
    mainWindow.webContents.send("show-update-dialog", updateInfo);
}
