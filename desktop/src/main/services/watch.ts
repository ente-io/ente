import chokidar, { type FSWatcher } from "chokidar";
import { BrowserWindow } from "electron/main";
import fs from "node:fs/promises";
import path from "node:path";
import { FolderWatch } from "../../types/ipc";
import log from "../log";
import { watchStore } from "../stores/watch";

/**
 * Create and return a new file system watcher.
 *
 * Internally this uses the watcher from the chokidar package.
 *
 * @param mainWindow The window handle is used to notify the renderer process of
 * pertinent file system events.
 */
export const createWatcher = (mainWindow: BrowserWindow) => {
    const send = (eventName: string) => (path: string) =>
        mainWindow.webContents.send(eventName, ...eventData(path));

    const folderPaths = folderWatches().map((watch) => watch.folderPath);

    const watcher = chokidar.watch(folderPaths, {
        awaitWriteFinish: true,
    });

    watcher
        .on("add", send("addFile"))
        .on("unlink", send("removeFile"))
        .on("unlinkDir", send("removeDir"))
        .on("error", (error) => log.error("Error while watching files", error));

    return watcher;
};

const eventData = (path: string): [string, FolderWatch] => {
    path = posixPath(path);

    const watch = folderWatches().find((watch) =>
        path.startsWith(watch.folderPath + "/"),
    );

    if (!watch) throw new Error(`No folder watch was found for path ${path}`);

    return [path, watch];
};

/**
 * Convert a file system {@link filePath} that uses the local system specific
 * path separators into a path that uses POSIX file separators.
 */
const posixPath = (filePath: string) =>
    filePath.split(path.sep).join(path.posix.sep);

export const findFiles = async (dirPath: string) => {
    const items = await fs.readdir(dirPath, { withFileTypes: true });
    let paths: string[] = [];
    for (const item of items) {
        const itemPath = path.posix.join(dirPath, item.name);
        if (item.isFile()) {
            paths.push(itemPath);
        } else if (item.isDirectory()) {
            paths = [...paths, ...(await findFiles(itemPath))];
        }
    }
    return paths;
};

export const addWatchMapping = async (
    watcher: FSWatcher,
    rootFolderName: string,
    folderPath: string,
    uploadStrategy: number,
) => {
    log.info(`Adding watch mapping: ${folderPath}`);
    const watchMappings = getWatchMappings();
    if (isMappingPresent(watchMappings, folderPath)) {
        throw new Error(`Watch mapping already exists`);
    }

    watcher.add(folderPath);

    watchMappings.push({
        rootFolderName,
        uploadStrategy,
        folderPath,
        syncedFiles: [],
        ignoredFiles: [],
    });

    setWatchMappings(watchMappings);
};

function isMappingPresent(watchMappings: FolderWatch[], folderPath: string) {
    const watchMapping = watchMappings?.find(
        (mapping) => mapping.folderPath === folderPath,
    );
    return !!watchMapping;
}

export const removeWatchMapping = async (
    watcher: FSWatcher,
    folderPath: string,
) => {
    let watchMappings = getWatchMappings();
    const watchMapping = watchMappings.find(
        (mapping) => mapping.folderPath === folderPath,
    );

    if (!watchMapping) {
        throw new Error(`Watch mapping does not exist`);
    }

    watcher.unwatch(watchMapping.folderPath);

    watchMappings = watchMappings.filter(
        (mapping) => mapping.folderPath !== watchMapping.folderPath,
    );

    setWatchMappings(watchMappings);
};

export function updateWatchMappingSyncedFiles(
    folderPath: string,
    files: FolderWatch["syncedFiles"],
): void {
    const watchMappings = getWatchMappings();
    const watchMapping = watchMappings.find(
        (mapping) => mapping.folderPath === folderPath,
    );

    if (!watchMapping) {
        throw Error(`Watch mapping not found`);
    }

    watchMapping.syncedFiles = files;
    setWatchMappings(watchMappings);
}

export function updateWatchMappingIgnoredFiles(
    folderPath: string,
    files: FolderWatch["ignoredFiles"],
): void {
    const watchMappings = getWatchMappings();
    const watchMapping = watchMappings.find(
        (mapping) => mapping.folderPath === folderPath,
    );

    if (!watchMapping) {
        throw Error(`Watch mapping not found`);
    }

    watchMapping.ignoredFiles = files;
    setWatchMappings(watchMappings);
}

export const folderWatches = () => {
    const mappings = watchStore.get("mappings") ?? [];
    return mappings;
};

function setWatchMappings(watchMappings: WatchStoreType["mappings"]) {
    watchStore.set("mappings", watchMappings);
}
