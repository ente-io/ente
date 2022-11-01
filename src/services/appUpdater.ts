import { app, BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';
import semVerCmp from 'semver-compare';

const LATEST_SUPPORTED_AUTO_UPDATE_VERSION = '1.6.12';

class AppUpdater {
    updateDownloaded: boolean;
    constructor() {
        autoUpdater.logger = log;
        autoUpdater.autoDownload = false;
    }

    async checkForUpdate(tray: Tray, mainWindow: BrowserWindow) {
        log.debug('checkForUpdate');
        const updateCheckResult = await autoUpdater.checkForUpdatesAndNotify();
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
                log.debug('update not supported');
                this.updateDownloaded = false;
                this.showUpdateDialog(mainWindow);
            } else {
                log.debug('update supported');
                autoUpdater.downloadUpdate();
                autoUpdater.on('update-downloaded', () => {
                    this.updateDownloaded = true;
                    this.showUpdateDialog(mainWindow);
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

    showUpdateDialog = (mainWindow: BrowserWindow) => {
        mainWindow.webContents.send('show-update-dialog', {
            updateDownloaded: this.updateDownloaded,
        });
    };
}

export default new AppUpdater();
