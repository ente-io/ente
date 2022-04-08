import { BrowserWindow, dialog, ipcMain, Tray, Notification } from 'electron';
import { createWindow } from './createWindow';
import { buildContextMenu } from './menuUtil';
import { getFilesFromDir } from './upload';

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow
): void {
    ipcMain.handle('select-dir', async () => {
        const dialogWindow = new BrowserWindow({
            width: 800,
            height: 600,
            webPreferences: {
                nodeIntegration: false,
                contextIsolation: true,
                sandbox: true,
            },
        });
        const result = await dialog.showOpenDialog(dialogWindow, {
            properties: ['openDirectory'],
        });
        const dir =
            result.filePaths &&
            result.filePaths.length > 0 &&
            result.filePaths[0];
        dialogWindow.close();
        return dir;
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

    ipcMain.handle('show-upload-files-dialog', async () => {
        const files = await dialog.showOpenDialog({
            properties: ['openFile', 'multiSelections'],
        });
        return files.filePaths;
    });

    ipcMain.handle('show-upload-dirs-dialog', async () => {
        const dir = await dialog.showOpenDialog({
            properties: ['openDirectory', 'multiSelections'],
        });

        let files: string[] = [];
        for (const dirPath of dir.filePaths) {
            files = files.concat(await getFilesFromDir(dirPath));
        }

        return files;
    });
}
