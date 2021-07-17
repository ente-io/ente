import { BrowserWindow, dialog, Tray } from "electron"
import { autoUpdater } from "electron-updater"
import log from "electron-log"
import { setIsAppQuitting, setIsUpdateAvailable } from "../main";
import { buildContextMenu } from "./menuUtil";

class AppUpdater {
  constructor() {
    log.transports.file.level = "debug"
    autoUpdater.logger = log;
  }

  async checkForUpdate(tray: Tray, mainWindow: BrowserWindow) {
    await autoUpdater.checkForUpdatesAndNotify()
    autoUpdater.on('update-downloaded', () => {
      setIsUpdateAvailable(true);
      tray.setContextMenu(buildContextMenu(mainWindow));
    })
  }
}

export default new AppUpdater();


export const showUpdateDialog = () => {
  dialog.showMessageBox({
    type: 'info',
    title: 'Install Updates',
    message: 'an update has been downloaded, ente will now restart',
    buttons: ['No', 'Sure']
  }).then((buttonIndex) => {
    if (buttonIndex.response === 1) {
      setIsAppQuitting(true); autoUpdater.quitAndInstall()
    }
  })
}
