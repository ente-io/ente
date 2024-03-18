import { compareVersions } from "compare-versions";
import { app, BrowserWindow } from "electron";
import { default as ElectronLog, default as log } from "electron-log";
import { autoUpdater } from "electron-updater";
import fetch from "node-fetch";
import { setIsAppQuitting, setIsUpdateAvailable } from "../main";
import { AppUpdateInfo, GetFeatureFlagResponse } from "../types";
import { isPlatform } from "../utils/common/platform";
import { logErrorSentry } from "./sentry";
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
    autoUpdater.logger = log;
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
        logErrorSentry(e, "forceCheckForUpdateAndNotify failed");
    }
}

async function checkForUpdateAndNotify(mainWindow: BrowserWindow) {
    try {
        log.debug("checkForUpdateAndNotify called");
        const updateCheckResult = await autoUpdater.checkForUpdates();
        log.debug("update version", updateCheckResult.updateInfo.version);
        if (
            compareVersions(
                updateCheckResult.updateInfo.version,
                app.getVersion(),
            ) <= 0
        ) {
            log.debug("already at latest version");
            return;
        }
        const skipAppVersion = getSkipAppVersion();
        if (
            skipAppVersion &&
            updateCheckResult.updateInfo.version === skipAppVersion
        ) {
            log.info(
                "user chose to skip version ",
                updateCheckResult.updateInfo.version,
            );
            return;
        }
        const desktopCutoffVersion = await getDesktopCutoffVersion();
        if (
            desktopCutoffVersion &&
            isPlatform("mac") &&
            compareVersions(
                updateCheckResult.updateInfo.version,
                desktopCutoffVersion,
            ) > 0
        ) {
            log.debug("auto update not possible due to key change");
            showUpdateDialog(mainWindow, {
                autoUpdatable: false,
                version: updateCheckResult.updateInfo.version,
            });
        } else {
            let timeout: NodeJS.Timeout;
            log.debug("attempting auto update");
            autoUpdater.downloadUpdate();
            const muteUpdateNotificationVersion =
                getMuteUpdateNotificationVersion();
            if (
                muteUpdateNotificationVersion &&
                updateCheckResult.updateInfo.version ===
                    muteUpdateNotificationVersion
            ) {
                log.info(
                    "user chose to mute update notification for version ",
                    updateCheckResult.updateInfo.version,
                );
                return;
            }
            autoUpdater.on("update-downloaded", () => {
                timeout = setTimeout(
                    () =>
                        showUpdateDialog(mainWindow, {
                            autoUpdatable: true,
                            version: updateCheckResult.updateInfo.version,
                        }),
                    FIVE_MIN_IN_MICROSECOND,
                );
            });
            autoUpdater.on("error", (error) => {
                clearTimeout(timeout);
                logErrorSentry(error, "auto update failed");
                showUpdateDialog(mainWindow, {
                    autoUpdatable: false,
                    version: updateCheckResult.updateInfo.version,
                });
            });
        }
        setIsUpdateAvailable(true);
    } catch (e) {
        logErrorSentry(e, "checkForUpdateAndNotify failed");
    }
}

export function updateAndRestart() {
    ElectronLog.log("user quit the app");
    setIsAppQuitting(true);
    autoUpdater.quitAndInstall();
}

export function getAppVersion() {
    return `v${app.getVersion()}`;
}

export function skipAppUpdate(version: string) {
    setSkipAppVersion(version);
}

export function muteUpdateNotification(version: string) {
    setMuteUpdateNotificationVersion(version);
}

async function getDesktopCutoffVersion() {
    try {
        const featureFlags = (
            await fetch("https://static.ente.io/feature_flags.json")
        ).json() as GetFeatureFlagResponse;
        return featureFlags.desktopCutoffVersion;
    } catch (e) {
        logErrorSentry(e, "failed to get feature flags");
        return undefined;
    }
}

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo,
) {
    mainWindow.webContents.send("show-update-dialog", updateInfo);
}
