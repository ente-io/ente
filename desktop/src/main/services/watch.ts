import type { FSWatcher } from "chokidar";
import ElectronLog from "electron-log";
import { FolderWatch, WatchStoreType } from "../../types/ipc";
import { watchStore } from "../stores/watch.store";
import path from "node:path";
import fs from "node:fs/promises";

/**
 * Return the paths of all the files under the given directory (recursive).
 *
 * This function walks the directory tree starting at {@link dirPath}, and
 * returns a list of the absolute paths of all the files that exist therein. It
 * will recursively traverse into nested directories, and return the absolute
 * paths of the files there too.
 *
 * The returned paths are guaranteed to use POSIX separators ('/').
 */
export const findFiles = async (dirPath: string) => {
    const items = await fs.readdir(dirPath, { withFileTypes: true })
    let paths: string[] = [];
    for (const item of items) {
        const itemPath = path.posix.join(dirPath, item.name);
        if (item.isFile()) {
            paths.push(itemPath)
        } else if (item.isDirectory()) {
            paths = [...paths, ...await findFiles(itemPath)]
        }
    }
    return paths
}

export const addWatchMapping = async (
    watcher: FSWatcher,
    rootFolderName: string,
    folderPath: string,
    uploadStrategy: number,
) => {
    ElectronLog.log(`Adding watch mapping: ${folderPath}`);
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

export function getWatchMappings() {
    const mappings = watchStore.get("mappings") ?? [];
    return mappings;
}

function setWatchMappings(watchMappings: WatchStoreType["mappings"]) {
    watchStore.set("mappings", watchMappings);
}
