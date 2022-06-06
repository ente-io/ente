import path from 'path';
import chokidar from 'chokidar';
import { watchStore } from '../services/store';
import { logError } from './logging';
import { BrowserWindow, ipcRenderer } from 'electron';
import { WatchStoreType } from '../types';
import { getFilesFromDir } from './upload';

export async function addWatchMapping(
    collectionName: string,
    folderPath: string
) {
    let watchMappings = getWatchMappings();
    if (!watchMappings) {
        watchMappings = [];
    }

    const watchMapping = watchMappings?.find(
        (mapping) =>
            mapping.collectionName === collectionName ||
            mapping.folderPath === folderPath
    );

    if (watchMapping) {
        return;
    }

    await ipcRenderer.invoke('add-watcher', {
        dir: folderPath,
    });

    watchMappings.push({
        collectionName,
        folderPath,
        files: [],
    });

    setWatchMappings(watchMappings);
}

export async function removeWatchMapping(collectionName: string) {
    const watchMappings = getWatchMappings();
    const watchMapping = watchMappings.find(
        (mapping) => mapping.collectionName === collectionName
    );

    if (!watchMapping) {
        return;
    }

    await ipcRenderer.invoke('remove-watcher', {
        dir: watchMapping.folderPath,
    });

    watchMappings.splice(watchMappings.indexOf(watchMapping), 1);

    setWatchMappings(watchMappings);
}

export function getWatchMappings() {
    const mappings = watchStore.get('mappings') ?? [];
    return mappings;
}

export function setWatchMappings(watchMappings: WatchStoreType['mappings']) {
    watchStore.set('mappings', watchMappings);
}

export async function getPosixFilePathsFromDir(dirPath: string) {
    let files = await getFilesFromDir(dirPath);
    files = files.map((file) => file.split(path.sep).join(path.posix.sep));
    return files;
}

export function initWatcher(mainWindow: BrowserWindow) {
    const mappings = getWatchMappings();
    const folderPaths = mappings.map((mapping) => {
        return mapping.folderPath;
    });

    const watcher = chokidar.watch(folderPaths, {
        depth: 1,
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
        .on('error', (error) => {
            logError(error, 'error while watching files');
        });

    return watcher;
}

export function registerWatcherFunctions(
    WatchServiceInstance: any,
    add: (WatchServiceInstance: any, path: string) => Promise<void>,
    remove: (WatchServiceInstance: any, path: string) => Promise<void>
) {
    ipcRenderer.removeAllListeners('watch-add');
    ipcRenderer.removeAllListeners('watch-change');
    ipcRenderer.removeAllListeners('watch-unlink');
    ipcRenderer.on('watch-add', async (_, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await add(WatchServiceInstance, filePath);
    });
    ipcRenderer.on('watch-change', async (_, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await remove(WatchServiceInstance, filePath);
        await add(WatchServiceInstance, filePath);
    });
    ipcRenderer.on('watch-unlink', async (_, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await remove(WatchServiceInstance, filePath);
    });
}
