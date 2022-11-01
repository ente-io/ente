import { app, BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';
import semVerCmp from 'semver-compare';
import { AppUpdateInfo } from '../types';
import { getSkipAppVersion, setSkipAppVersion } from './userPreference';

const LATEST_SUPPORTED_AUTO_UPDATE_VERSION = '1.6.12';

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
            if (updateCheckResult.updateInfo.version === getSkipAppVersion()) {
                log.info(
                    'user chose to skip version ',
                    updateCheckResult.updateInfo.version
                );
                return;
            }
            if (
                semVerCmp(
                    updateCheckResult.updateInfo.version,
                    LATEST_SUPPORTED_AUTO_UPDATE_VERSION
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

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo
) {
    mainWindow.webContents.send('show-update-dialog', updateInfo);
}

export function skipAppVersion(version: string) {
    setSkipAppVersion(version);
}
