import chokidar from 'chokidar';
import { BrowserWindow } from 'electron';
import { logError } from '../utils/logging';
import { getWatchMappings } from '../api/watch';

export function initWatcher(mainWindow: BrowserWindow) {
    const mappings = getWatchMappings();
    const folderPaths = mappings.map((mapping) => {
        return mapping.folderPath;
    });

    const watcher = chokidar.watch(folderPaths, {
        awaitWriteFinish: true,
    });
    watcher
        .on('add', (path) => {
            mainWindow.webContents.send('watch-add', path);
        })
        .on('change', (path) => {
            mainWindow.webContents.send('watch-change', path);
        })
        .on('unlink', (path) => {
            mainWindow.webContents.send('watch-unlink', path);
        })
        .on('unlinkDir', (path) => {
            mainWindow.webContents.send('watch-unlink', path, true);
        })
        .on('error', (error) => {
            logError(error, 'error while watching files');
        });

    return watcher;
}
