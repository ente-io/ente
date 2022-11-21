import {
    BrowserWindow,
    dialog,
    ipcMain,
    Tray,
    Notification,
    safeStorage,
    app,
    shell,
} from 'electron';
import { createWindow } from './createWindow';
import { buildContextMenu } from './menu';
import { getSentryUserID, logErrorSentry } from '../services/sentry';
import chokidar from 'chokidar';
import path from 'path';
import { getDirFilePaths } from '../services/fs';
import { convertHEIC } from '../services/heicConvertor';
import {
    getAppVersion,
    skipAppVersion,
    updateAndRestart,
} from '../services/appUpdater';
import {
    deleteTempFile,
    runFFmpegCmd,
    writeTempFile,
} from '../services/ffmpeg';

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow,
    watcher: chokidar.FSWatcher
): void {
    ipcMain.handle('select-dir', async () => {
        const result = await dialog.showOpenDialog({
            properties: ['openDirectory'],
        });
        if (result.filePaths && result.filePaths.length > 0) {
            return result.filePaths[0]?.split(path.sep)?.join(path.posix.sep);
        }
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
    ipcMain.on('reload-window', async () => {
        const secondWindow = await createWindow();
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
            files = [...files, ...(await getDirFilePaths(dirPath))];
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

    ipcMain.handle('safeStorage-encrypt', (_, message) => {
        return safeStorage.encryptString(message);
    });

    ipcMain.handle('safeStorage-decrypt', (_, message) => {
        return safeStorage.decryptString(message);
    });

    ipcMain.handle('get-path', (_, message) => {
        return app.getPath(message);
    });

    ipcMain.handle('convert-heic', (_, fileData) => {
        return convertHEIC(fileData);
    });

    ipcMain.handle('open-log-dir', () => {
        shell.openPath(app.getPath('logs'));
    });

    ipcMain.on('update-and-restart', () => {
        updateAndRestart();
    });
    ipcMain.on('skip-app-version', (_, version) => {
        skipAppVersion(version);
    });
    ipcMain.handle('get-sentry-id', () => {
        return getSentryUserID();
    });

    ipcMain.handle('get-app-version', () => {
        return getAppVersion();
    });

    ipcMain.handle(
        'run-ffmpeg-cmd',
        (_, cmd, inputFilePath, outputFileName) => {
            return runFFmpegCmd(cmd, inputFilePath, outputFileName);
        }
    );
    ipcMain.handle(
        'write-temp-file',
        (_, fileStream: Uint8Array, fileName: string) => {
            return writeTempFile(fileStream, fileName);
        }
    );
    ipcMain.handle('remove-temp-file', (_, tempFilePath: string) => {
        return deleteTempFile(tempFilePath);
    });
}
