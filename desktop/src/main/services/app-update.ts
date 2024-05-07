import { compareVersions } from "compare-versions";
import { default as electronLog } from "electron-log";
import { autoUpdater } from "electron-updater";
import { app, BrowserWindow } from "electron/main";
import { allowWindowClose } from "../../main";
import { AppUpdate } from "../../types/ipc";
import log from "../log";
import { userPreferences } from "../stores/user-preferences";
import { isDev } from "../utils/electron";

export const setupAutoUpdater = (mainWindow: BrowserWindow) => {
    autoUpdater.logger = electronLog;
    autoUpdater.autoDownload = false;

    /**
     * [Note: Testing auto updates]
     *
     * By default, we skip checking for updates automatically in dev builds.
     * This is because even if we were to find an update, installing it would
     * fail because (at least on macOS), the auto update process requires signed
     * builds.
     *
     * So an end to end testing for updates requires using a temporary GitHub
     * repository and signed builds therein.
     *
     * Howvere for partial checks of the UI flow, something like tis can be used
     * to do a test of the update process (up until the actual installation
     * itself).
     *
     * Create a `app/dev-app-update.yml` with:
     *
     *     provider: generic
     *     url: http://127.0.0.1:7777/
     *
     * and start a local webserver in some directory:
     *
     *     python3 -m http.server 7777
     *
     * In this directory, put `latest-mac.yml` and the DMG file that this YAML
     * file refers to.
     *
     * Alternatively, `dev-app-update.yml` can contain some arbitrary GitHub
     * repository, e.g.:
     *
     *       provider: github
     *       owner: foo
     *       repo: bar
     *
     * Finally, we can start the app to trigger the auto update. If we're in dev
     * mode, we can use the "Check for updates..." menu option to trigger the
     * update flow.
     */
    autoUpdater.forceDevUpdateConfig = isDev;
    if (isDev) return;

    autoUpdater.setFeedURL({
        provider: "github",
        owner: "mnvr",
        repo: "test-updates",
    });

    const oneDay = 1 * 24 * 60 * 60 * 1000;
    setInterval(() => void checkForUpdatesAndNotify(mainWindow), oneDay);
    void checkForUpdatesAndNotify(mainWindow);
};

/**
 * Check for app update check ignoring any previously saved skips / mutes.
 */
export const forceCheckForAppUpdates = (mainWindow: BrowserWindow) => {
    userPreferences.delete("skipAppVersion");
    userPreferences.delete("muteUpdateNotificationVersion");
    void checkForUpdatesAndNotify(mainWindow);
};

const checkForUpdatesAndNotify = async (mainWindow: BrowserWindow) => {
    const updateCheckResult = await autoUpdater.checkForUpdates();
    if (!updateCheckResult) {
        log.error("Failed to check for updates");
        return;
    }

    const { version } = updateCheckResult.updateInfo;

    log.debug(() => `Update check found version ${version}`);

    if (!version)
        throw new Error("Unexpected empty version obtained from auto-updater");

    if (compareVersions(version, app.getVersion()) <= 0) {
        log.debug(() => "Skipping update, already at latest version");
        return;
    }

    if (version == userPreferences.get("skipAppVersion")) {
        log.info(`User chose to skip version ${version}`);
        return;
    }

    const mutedVersion = userPreferences.get("muteUpdateNotificationVersion");
    if (version == mutedVersion) {
        log.info(`User has muted update notifications for version ${version}`);
        return;
    }

    const showUpdateDialog = (update: AppUpdate) =>
        mainWindow.webContents.send("appUpdateAvailable", update);

    log.debug(() => "Attempting auto update");
    await autoUpdater.downloadUpdate();

    let timeoutId: ReturnType<typeof setTimeout>;
    const fiveMinutes = 5 * 60 * 1000;
    autoUpdater.on("update-downloaded", () => {
        timeoutId = setTimeout(
            () => showUpdateDialog({ autoUpdatable: true, version }),
            fiveMinutes,
        );
    });

    autoUpdater.on("error", (error) => {
        clearTimeout(timeoutId);
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
