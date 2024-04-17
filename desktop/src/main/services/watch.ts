import type { FSWatcher } from "chokidar";
import ElectronLog from "electron-log";
import {
    FolderWatch,
    WatchStoreType,
    type ElectronFile,
} from "../../types/ipc";
import { isFolder } from "../fs";
import { watchStore } from "../stores/watch.store";
import { getDirFiles } from "./fs";

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

export const folderWatchesAndFilesTherein = async (
    watcher: FSWatcher,
): Promise<[watch: FolderWatch, files: ElectronFile[]][]> => {
    const mappings = await getWatchMappings();

    const activeMappings = [];
    for (const mapping of mappings) {
        const mappingExists = await isFolder(mapping.folderPath);
        if (!mappingExists) {
            await removeWatchMapping(watcher, mapping.folderPath);
        } else {
            activeMappings.push(mapping);
        }
    }

    return Promise.all(
        activeMappings.map(async (mapping) => [
            mapping,
            await getDirFiles(mapping.folderPath),
        ]),
    );
};
