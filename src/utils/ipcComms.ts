import { BrowserWindow, dialog, ipcMain, Tray, Notification } from 'electron';
import { createWindow } from './createWindow';
import { buildContextMenu } from './menuUtil';
import { logErrorSentry } from './sentry';
import chokidar from 'chokidar';
import path from 'path';
import { getFilesFromDir } from '../services/fs';

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow,
    watcher: chokidar.FSWatcher
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

    ipcMain.handle('add-watcher', async (_, args: { dir: string }) => {
        watcher.add(args.dir);
    });

    ipcMain.handle('remove-watcher', async (_, args: { dir: string }) => {
        watcher.unwatch(args.dir);
    });

    ipcMain.handle('log-error', (_, err, msg, info?) => {
        logErrorSentry(err, msg, info);
    });
}
