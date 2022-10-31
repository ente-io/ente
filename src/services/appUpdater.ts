import { BrowserWindow, Tray } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { setIsAppQuitting, setIsUpdateAvailable } from '../main';
import { buildContextMenu } from '../utils/menu';

const LATEST_SUPPORTED_AUTO_UPDATE_VERSION = '1.6.12';

class AppUpdater {
    updateDownloaded: boolean;
    constructor() {
        autoUpdater.logger = log;
        autoUpdater.autoDownload = false;
    }

    async checkForUpdate(tray: Tray, mainWindow: BrowserWindow) {
        const updateCheckResult = await autoUpdater.checkForUpdatesAndNotify();
        log.info(updateCheckResult);
        if (
            updateCheckResult.updateInfo.version >
            LATEST_SUPPORTED_AUTO_UPDATE_VERSION
        ) {
            this.updateDownloaded = false;
            this.showUpdateDialog(mainWindow);
        } else {
            autoUpdater.downloadUpdate();
            autoUpdater.on('update-downloaded', () => {
                this.updateDownloaded = true;
                this.showUpdateDialog(mainWindow);
                setIsUpdateAvailable(true);
                tray.setContextMenu(buildContextMenu(mainWindow));
            });
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
