import { BrowserWindow, dialog, ipcMain, Tray, Notification } from "electron";
import { createWindow } from "./createWindow";
import { buildContextMenu } from "./menuUtil";

export default function setupIpcComs(tray: Tray, mainWindow: BrowserWindow): void {
    ipcMain.on('select-dir', async (event) => {
        const dialogWindow = new BrowserWindow({
            width: 800,
            height: 600,
            webPreferences: {
                nodeIntegration: false,
                enableRemoteModule: false,
                contextIsolation: true,
                sandbox: true,
            },
        });
        const result = await dialog.showOpenDialog(dialogWindow, {
            properties: ['openDirectory'],
        });
        const dir =
            result.filePaths && result.filePaths.length > 0 && result.filePaths[0];
        dialogWindow.close();
        event.returnValue = dir;
    });

    ipcMain.on('update-tray', (event, args) => {
        tray.setContextMenu(buildContextMenu(mainWindow, args));
    });

    ipcMain.on('send-notification', (event, args) => {
        const notification = {
            title: 'ente',
            body: args,
        };
        new Notification(notification).show();
    });
    ipcMain.on('reload-window', (event, args) => {
        const secondWindow = createWindow();
        mainWindow.destroy();
        mainWindow = secondWindow;
    });
}
