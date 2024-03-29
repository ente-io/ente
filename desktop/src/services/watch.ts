import type { FSWatcher } from "chokidar";
import ElectronLog from "electron-log";
import { watchStore } from "../stores/watch.store";
import { WatchMapping, WatchStoreType } from "../types/ipc";
import { isMappingPresent } from "../utils/watch";

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
    files: WatchMapping["syncedFiles"],
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
    files: WatchMapping["ignoredFiles"],
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
