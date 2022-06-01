import * as fs from 'promise-fs';
import path from 'path';
import chokidar from 'chokidar';
import { watchStore } from '../services/store';
import { logError } from './logging';
import { BrowserWindow, ipcRenderer } from 'electron';
import { WatchStoreType } from '../types';

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

    watchMappings.splice(watchMappings.indexOf(watchMapping), 1);

    setWatchMappings(watchMappings);
}

export function getWatchMappings() {
    const mappings = watchStore.get('mappings');
    return mappings;
}

export function setWatchMappings(watchMappings: WatchStoreType['mappings']) {
    watchStore.set('mappings', watchMappings);
}

export async function getFilePathsFromDir(dirPath: string) {
    const filesAndFolders = await fs.readdir(dirPath);
    let files = filesAndFolders.filter(
        async (file) =>
            await fs.stat(`${dirPath}/${file}`).then((stat) => stat.isFile())
    );
    files = await Promise.all(files.map(async (file) => `${dirPath}/${file}`));
    return files;
}

export async function updateFilesInWatchMapping(
    collectionName: string,
    files: { path: string; id: number }[]
) {
    try {
        const mappings = getWatchMappings();
        const mapping = mappings.find(
            (m) => m.collectionName === collectionName
        );
        if (mapping) {
            mapping.files = files;
        } else {
            throw new Error(
                `No mapping found for collection ${collectionName}`
            );
        }
        watchStore.set('mappings', mappings);
    } catch (e) {
        logError(e, 'error while updating watch mappings');
    }
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
    obj: any,
    add: (t: any, path: string) => Promise<void>,
    remove: (t: any, path: string) => Promise<void>
) {
    console.log({ t: obj, add, remove });
    ipcRenderer.removeAllListeners('watch-add');
    ipcRenderer.removeAllListeners('watch-change');
    ipcRenderer.removeAllListeners('watch-unlink');
    ipcRenderer.on('watch-add', async (e, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await add(obj, filePath);
    });
    ipcRenderer.on('watch-change', async (e, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await remove(obj, filePath);
        await add(obj, filePath);
    });
    ipcRenderer.on('watch-unlink', async (e, filePath: string) => {
        filePath = filePath.split(path.sep).join(path.posix.sep);
        await remove(obj, filePath);
    });
}
