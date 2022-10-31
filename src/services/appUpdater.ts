import { BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';
import { showUpdateDialog } from '../utils/appUpdate';

const LATEST_SUPPORTED_AUTO_UPDATE_VERSION = '1.6.12';

class AppUpdater {
    updateDownloaded: boolean;
    constructor() {
        autoUpdater.logger = log;
        autoUpdater.autoDownload = false;
    }

    getUpdateDownloaded() {
        return this.updateDownloaded;
    }

    async checkForUpdate(tray: Tray, mainWindow: BrowserWindow) {
        const updateCheckResult = await autoUpdater.checkForUpdatesAndNotify();
        log.info(updateCheckResult);
        if (
            updateCheckResult.updateInfo.version >
            LATEST_SUPPORTED_AUTO_UPDATE_VERSION
        ) {
            this.updateDownloaded = false;
            showUpdateDialog(mainWindow);
        } else {
            autoUpdater.downloadUpdate();
            autoUpdater.on('update-downloaded', () => {
                this.updateDownloaded = true;
                showUpdateDialog(mainWindow);
                setIsUpdateAvailable(true);
                tray.setContextMenu(buildContextMenu(mainWindow));
            });
        }
    }

    updateAndRestart = () => {
        setIsAppQuitting(true);
        autoUpdater.quitAndInstall();
    };
}

export default new AppUpdater();
