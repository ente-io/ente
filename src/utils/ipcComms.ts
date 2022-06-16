import {
    BrowserWindow,
    dialog,
    ipcMain,
    Tray,
    Notification,
    safeStorage,
    app,
} from 'electron';
import { createWindow } from './createWindow';
import { buildContextMenu } from './menu';
import { logErrorSentry } from './sentry';
import path from 'path';
import { getFilesFromDir } from '../services/fs';

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow
): void {
    ipcMain.handle('select-dir', async () => {
        const result = await dialog.showOpenDialog({
            properties: ['openDirectory'],
        });
        let dir =
            result.filePaths &&
            result.filePaths.length > 0 &&
            result.filePaths[0];
        dir = dir?.split(path.sep)?.join(path.posix.sep);
        return dir;
    });

    ipcMain.on('update-tray', (_, args) => {
        tray.setContextMenu(buildContextMenu(mainWindow, args));
    });

    ipcMain.on('send-notification', (_, args) => {
        const notification = {
            title: 'ente',
            body: args,
        };
        new Notification(notification).show();
    });

    ipcMain.on('reload-window', () => {
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

    ipcMain.handle('show-upload-zip-dialog', async () => {
        const files = await dialog.showOpenDialog({
            properties: ['openFile', 'multiSelections'],
            filters: [{ name: 'Zip File', extensions: ['zip'] }],
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

    ipcMain.handle('log-error', (_, err, msg, info?) => {
        logErrorSentry(err, msg, info);
    });

    ipcMain.handle('safeStorage-encrypt', (_, message) => {
        return safeStorage.encryptString(message);
    });

    ipcMain.handle('safeStorage-decrypt', (_, message) => {
        return safeStorage.decryptString(message);
    });

    ipcMain.handle('get-path', (_, message) => {
        return app.getPath(message);
    });
}
