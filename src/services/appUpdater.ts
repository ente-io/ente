import { app, BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';
import semVerCmp from 'semver-compare';
import { AppUpdateInfo, GetKeyChangeVersionResponse } from '../types';
import { getSkipAppVersion, setSkipAppVersion } from './userPreference';
import fetch from 'node-fetch';
class AppUpdater {
    constructor() {
        autoUpdater.logger = log;
        autoUpdater.autoDownload = false;
    }

    async checkForUpdate(tray: Tray, mainWindow: BrowserWindow) {
        log.debug('checkForUpdate');
        const updateCheckResult = await autoUpdater.checkForUpdates();
        log.debug(updateCheckResult);
        if (
            semVerCmp(updateCheckResult.updateInfo.version, app.getVersion()) >
            0
        ) {
            log.debug('update available');
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
            const versionWithKeyChange = await getVersionWithKeyChange();
            if (
                versionWithKeyChange &&
                semVerCmp(
                    updateCheckResult.updateInfo.version,
                    versionWithKeyChange
                ) > 0
            ) {
                log.debug('auto update not supported');
                showUpdateDialog(mainWindow, {
                    autoUpdatable: false,
                    version: updateCheckResult.updateInfo.version,
                });
            } else {
                log.debug('auto update supported');
                autoUpdater.downloadUpdate();
                autoUpdater.on('update-downloaded', () => {
                    showUpdateDialog(mainWindow, {
                        autoUpdatable: true,
                        version: updateCheckResult.updateInfo.version,
                    });
                });
                autoUpdater.on('error', (error) => {
                    log.error(error);
                    showUpdateDialog(mainWindow, {
                        autoUpdatable: false,
                        version: updateCheckResult.updateInfo.version,
                    });
                });
            }
            setIsUpdateAvailable(true);
            tray.setContextMenu(buildContextMenu(mainWindow));
        }
    }

    updateAndRestart = () => {
        setIsAppQuitting(true);
        autoUpdater.quitAndInstall();
    };
}

export default new AppUpdater();

async function getVersionWithKeyChange() {
    const keyChangeVersion = (
        await fetch('https://ente.io/desktop-key-change-version')
    ).json() as GetKeyChangeVersionResponse;
    return keyChangeVersion.version;
}

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo
) {
    mainWindow.webContents.send('show-update-dialog', updateInfo);
}

export function skipAppVersion(version: string) {
    setSkipAppVersion(version);
}
