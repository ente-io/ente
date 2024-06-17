import chokidar, { type FSWatcher } from "chokidar";
import { BrowserWindow } from "electron/main";
import fs from "node:fs/promises";
import path from "node:path";
import { FolderWatch, type CollectionMapping } from "../../types/ipc";
import log from "../log";
import { watchStore } from "../stores/watch";
import { posixPath } from "../utils/electron";
import { fsIsDir } from "./fs";

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
        // Don't emit "add" events for matching paths when instantiating the
        // watch (we do a full disk scan on launch on our own, and also getting
        // the same events from the watcher causes duplicates).
        ignoreInitial: true,
        // Ask the watcher to wait for a the file size to stabilize before
        // telling us about a new file. By default, it waits for 2 seconds.
        awaitWriteFinish: true,
    });

    watcher
        .on("add", send("watchAddFile"))
        .on("unlink", send("watchRemoveFile"))
        .on("unlinkDir", send("watchRemoveDir"))
        .on("error", (error) => log.error("Error while watching files", error));

    return watcher;
};

const eventData = (platformPath: string): [string, FolderWatch] => {
    const path = posixPath(platformPath);

    const watch = folderWatches().find((watch) =>
        path.startsWith(watch.folderPath + "/"),
    );

    if (!watch) throw new Error(`No folder watch was found for path ${path}`);

    return [path, watch];
};

export const watchGet = async (watcher: FSWatcher): Promise<FolderWatch[]> => {
    const valid: FolderWatch[] = [];
    const deletedPaths: string[] = [];
    for (const watch of folderWatches()) {
        if (await fsIsDir(watch.folderPath)) valid.push(watch);
        else deletedPaths.push(watch.folderPath);
    }
    if (deletedPaths.length) {
        await Promise.all(deletedPaths.map((p) => watchRemove(watcher, p)));
        setFolderWatches(valid);
    }
    return valid;
};

const folderWatches = (): FolderWatch[] => watchStore.get("mappings") ?? [];

const setFolderWatches = (watches: FolderWatch[]) =>
    watchStore.set("mappings", watches);

export const watchAdd = async (
    watcher: FSWatcher,
    folderPath: string,
    collectionMapping: CollectionMapping,
) => {
    const watches = folderWatches();

    if (!(await fsIsDir(folderPath)))
        throw new Error(
            `Attempting to add a folder watch for a folder path ${folderPath} that is not an existing directory`,
        );

    if (watches.find((watch) => watch.folderPath == folderPath))
        throw new Error(
            `A folder watch with the given folder path ${folderPath} already exists`,
        );

    watches.push({
        folderPath,
        collectionMapping,
        syncedFiles: [],
        ignoredFiles: [],
    });

    setFolderWatches(watches);

    watcher.add(folderPath);

    return watches;
};

export const watchRemove = (watcher: FSWatcher, folderPath: string) => {
    const watches = folderWatches();
    const filtered = watches.filter((watch) => watch.folderPath != folderPath);
    if (watches.length == filtered.length)
        throw new Error(
            `Attempting to remove a non-existing folder watch for folder path ${folderPath}`,
        );
    setFolderWatches(filtered);
    watcher.unwatch(folderPath);
    return filtered;
};

export const watchUpdateSyncedFiles = (
    syncedFiles: FolderWatch["syncedFiles"],
    folderPath: string,
) => {
    setFolderWatches(
        folderWatches().map((watch) => {
            if (watch.folderPath == folderPath) {
                watch.syncedFiles = syncedFiles;
            }
            return watch;
        }),
    );
};

export const watchUpdateIgnoredFiles = (
    ignoredFiles: FolderWatch["ignoredFiles"],
    folderPath: string,
) => {
    setFolderWatches(
        folderWatches().map((watch) => {
            if (watch.folderPath == folderPath) {
                watch.ignoredFiles = ignoredFiles;
            }
            return watch;
        }),
    );
};

export const watchFindFiles = async (dirPath: string) => {
    const items = await fs.readdir(dirPath, { withFileTypes: true });
    let paths: string[] = [];
    for (const item of items) {
        const itemPath = path.posix.join(dirPath, item.name);
        if (item.isFile()) {
            paths.push(itemPath);
        } else if (item.isDirectory()) {
            paths = [...paths, ...(await watchFindFiles(itemPath))];
        }
    }
    return paths;
};

/**
 * Stop watching all existing folder watches and remove any callbacks.
 *
 * This function is meant to be called when the user logs out. It stops
 * all existing folder watches and forgets about any "on*" callback
 * functions that have been registered.
 *
 * The persisted state itself gets cleared via {@link clearStores}.
 */
export const watchReset = (watcher: FSWatcher) => {
    watcher.unwatch(folderWatches().map((watch) => watch.folderPath));
};
