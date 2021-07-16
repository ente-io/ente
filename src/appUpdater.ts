import {  BrowserWindow, dialog } from "electron"
import { autoUpdater } from "electron-updater"
import log from "electron-log"
import { createDefaultWindow, setUpVersionInfoWindow } from "./util";

 class AppUpdater {
    win:BrowserWindow;
    constructor() {
        log.transports.file.level = "debug"
        autoUpdater.logger = log;
    }

    initUpdater(){
        this.initWin();
        setUpVersionInfoWindow(this.win);
    }

    initWin(){
        this.win=createDefaultWindow();
        this.win.on('closed', () => {
            this.win=null;
        });
    }

    destroyUpdateWindow(){
      this.win=null;
    }

    async checkForUpdate(){
        if(!this.win){
            this.initUpdater();
        }
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