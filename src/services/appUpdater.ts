import { app, BrowserWindow } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import semVerCmp from 'semver-compare';
import { AppUpdateInfo, GetFeatureFlagResponse } from '../types';
import {
    getSkipAppVersion,
    setMuteUpdateNotificationVersion,
    setSkipAppVersion,
} from './userPreference';
import fetch from 'node-fetch';
import { logErrorSentry } from './sentry';
import ElectronLog from 'electron-log';
import { isPlatform } from '../utils/main';

const FIVE_MIN_IN_MICROSECOND = 5 * 60 * 1000;
const ONE_DAY_IN_MICROSECOND = 1 * 24 * 60 * 60 * 1000;

export function setupAutoUpdater(mainWindow: BrowserWindow) {
    autoUpdater.logger = log;
    autoUpdater.autoDownload = false;
    checkForUpdateAndNotify(mainWindow);
    setInterval(
        () => checkForUpdateAndNotify(mainWindow),
        ONE_DAY_IN_MICROSECOND
    );
}

async function checkForUpdateAndNotify(mainWindow: BrowserWindow) {
    try {
        log.debug('checkForUpdateAndNotify called');
        const updateCheckResult = await autoUpdater.checkForUpdates();
        log.debug('update version', updateCheckResult.updateInfo.version);
        if (
            semVerCmp(updateCheckResult.updateInfo.version, app.getVersion()) <=
            0
        ) {
            log.debug('already at latest version');
            return;
        }
        const skipAppVersion = getSkipAppVersion();
        if (
            skipAppVersion &&
            updateCheckResult.updateInfo.version === skipAppVersion
        ) {
            log.info(
                'user chose to skip version ',
                updateCheckResult.updateInfo.version
            );
            return;
        }
        const desktopCutoffVersion = await getDesktopCutoffVersion();
        if (
            desktopCutoffVersion &&
            isPlatform('mac') &&
            semVerCmp(
                updateCheckResult.updateInfo.version,
                desktopCutoffVersion
            ) > 0
        ) {
            log.debug('auto update not possible due to key change');
            showUpdateDialog(mainWindow, {
                autoUpdatable: false,
                version: updateCheckResult.updateInfo.version,
            });
        } else {
            let timeout: NodeJS.Timeout;
            log.debug('attempting auto update');
            autoUpdater.downloadUpdate();
            autoUpdater.on('update-downloaded', () => {
                timeout = setTimeout(
                    () =>
                        showUpdateDialog(mainWindow, {
                            autoUpdatable: true,
                            version: updateCheckResult.updateInfo.version,
                        }),
                    FIVE_MIN_IN_MICROSECOND
                );
            });
            autoUpdater.on('error', (error) => {
                clearTimeout(timeout);
                logErrorSentry(error, 'auto update failed');
                showUpdateDialog(mainWindow, {
                    autoUpdatable: false,
                    version: updateCheckResult.updateInfo.version,
                });
            });
        }
        setIsUpdateAvailable(true);
    } catch (e) {
        logErrorSentry(e, 'checkForUpdateAndNotify failed');
    }
}

export function updateAndRestart() {
    ElectronLog.log('user quit the app');
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
            await fetch('https://static.ente.io/feature_flags.json')
        ).json() as GetFeatureFlagResponse;
        return featureFlags.desktopCutoffVersion;
    } catch (e) {
        logErrorSentry(e, 'failed to get feature flags');
        return undefined;
    }
}

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo
) {
    mainWindow.webContents.send('show-update-dialog', updateInfo);
}
