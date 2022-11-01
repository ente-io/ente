import { app, BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';
import semVerCmp from 'semver-compare';
import { AppUpdateInfo } from '../types';

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
            if (
                semVerCmp(
                    updateCheckResult.updateInfo.version,
                    LATEST_SUPPORTED_AUTO_UPDATE_VERSION
                ) > 0
            ) {
                log.debug('auto update not supported');
                showUpdateDialog(mainWindow, { autoUpdatable: false });
            } else {
                log.debug('auto update supported');
                autoUpdater.downloadUpdate();
                autoUpdater.on('update-downloaded', () => {
                    showUpdateDialog(mainWindow, { autoUpdatable: true });
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

function showUpdateDialog(
    mainWindow: BrowserWindow,
    updateInfo: AppUpdateInfo
) {
    mainWindow.webContents.send('show-update-dialog', updateInfo);
}

export default new AppUpdater();
