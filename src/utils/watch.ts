import * as fs from 'promise-fs';
import chokidar from 'chokidar';
import { watchStore } from '../services/store';
import { logError } from './logging';
import { BrowserWindow, ipcRenderer } from 'electron';

export async function deleteFile(filePath: string) {
    try {
        const fileStats = await fs.stat(filePath);
        if (fileStats.isFile()) {
            await fs.unlink(filePath);
        } else {
            throw new Error(`${filePath} is not a file`);
        }
    } catch (e) {
        logError(e, 'error while deleting file');
    }
}

export async function deleteFilesFromDisk(filePaths: string[]) {
    for (const filePath of filePaths) {
        await deleteFile(filePath);
    }
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

export function getWatchMappings() {
    const mappings = watchStore.get('mappings');
    return mappings;
}

export async function updateFilesInWatchMapping(
    collectionName: string,
    files: { path: string; ID: number }[]
) {
    try {
        const mappings = await getWatchMappings();
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
    add: (path: string) => Promise<void>,
    remove: (path: string) => Promise<void>
) {
    ipcRenderer.removeAllListeners('watch-add');
    ipcRenderer.removeAllListeners('watch-change');
    ipcRenderer.removeAllListeners('watch-unlink');
    ipcRenderer.on('watch-add', async (e, path) => {
        await add(path);
    });
    ipcRenderer.on('watch-change', async (e, path) => {
        await remove(path);
        await add(path);
    });
    ipcRenderer.on('watch-unlink', async (e, path) => {
        await remove(path);
    });
}

/*
    - get all available mappings and files
    - get available file paths from dir
    - delete file(s) by file paths from disk
    - update store with list of files
    - init chokidar and attach events (all events first get the latest state of indexedDB)
*/
