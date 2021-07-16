import {   dialog } from "electron"
import { autoUpdater } from "electron-updater"
import log from "electron-log"

 class AppUpdater {
    constructor() {
        log.transports.file.level = "debug"
        autoUpdater.logger = log;
    }

    async checkForUpdate(){
        await autoUpdater.checkForUpdatesAndNotify()
        autoUpdater.on('update-downloaded', () => {
            dialog.showMessageBox({
              title: 'Install Updates',
              message: 'Updates downloaded, application will be quit for update...'
            }).then(() => {
              setImmediate(() => autoUpdater.quitAndInstall())
            })
          })
    }
}



export default new AppUpdater();