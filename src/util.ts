import { app, BrowserWindow } from "electron";
import log  from "electron-log";
import { autoUpdater } from "electron-updater";
import * as isDev from 'electron-is-dev';
import * as path from 'path';


export function sendStatusToWindow(win:BrowserWindow, text:string) {
    log.info(text);
    win.webContents.send('message', text);
  }

export function createDefaultWindow() {
    const win = new BrowserWindow({webPreferences:{nodeIntegration:true}});
    win.webContents.openDevTools();
    if (isDev) {
        win.loadFile(`../build/version.html`);
    } else {
        win.loadURL(
            `file://${path.join(process.resourcesPath, 'version.html')}#v${app.getVersion()}}`
        );
    }
    return win;
}

export function setUpVersionInfoWindow(win:BrowserWindow){  

      
    autoUpdater.on('checking-for-update', () => {
      sendStatusToWindow(win,'Checking for update...');
    })
    autoUpdater.on('update-available', (info) => {
      sendStatusToWindow(win,'Update available.');
    })
    autoUpdater.on('update-not-available', (info) => {
        sendStatusToWindow(win,'Update not available.');
    })
    autoUpdater.on('error', (err) => {
        sendStatusToWindow(win,'Error in auto-updater. ' + err);
    })
    autoUpdater.on('download-progress', (progressObj) => {
      let log_message = "Download speed: " + progressObj.bytesPerSecond;
      log_message = log_message + ' - Downloaded ' + progressObj.percent + '%';
      log_message = log_message + ' (' + progressObj.transferred + "/" + progressObj.total + ')';
      sendStatusToWindow(win,log_message);
    })
    autoUpdater.on('update-downloaded', (info) => {
        sendStatusToWindow(win,'Update downloaded');
    });
}