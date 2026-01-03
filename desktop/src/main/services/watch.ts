import chokidar, { type FSWatcher } from "chokidar";
import { BrowserWindow } from "electron/main";
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
    const send = (eventName: string) => (path: string) => {
        const data = eventData(path);
        if (data) mainWindow.webContents.send(eventName, ...data);
    };

    const folderPaths = storedFolderWatches().map((watch) => watch.folderPath);

    const watcher = chokidar.watch(folderPaths, {
        // Don't emit "add" events for matching paths when instantiating the
        // watch (we do a full disk scan on launch on our own, and also getting
        // the same events from the watcher causes duplicates).
        ignoreInitial: true,
        // Ask the watcher to wait for a the file size to stabilize before
        // telling us about a new file. By default, it waits for 2 seconds.
        awaitWriteFinish: true,
        // On macOS we start getting "EMFILE: too many open files" when watching
        // large folders. This is a known regression in Chokidar v4:
        // https://github.com/paulmillr/chokidar/issues/1385
        //
        // The recommended workaround for now is to enable usePolling. Since it
        // comes at a performance cost, we only do it where needed (macOS).
        ...(process.platform == "darwin" ? { usePolling: true } : {}),
    });

    watcher
        .on("add", send("watchAddFile"))
        .on("unlink", send("watchRemoveFile"))
        .on("unlinkDir", send("watchRemoveDir"))
        .on("error", (error) => log.error("Error while watching files", error));

    return watcher;
};

const eventData = (platformPath: string): [string, FolderWatch] | undefined => {
    const path = posixPath(platformPath);

    const watch = storedFolderWatches().find((watch) =>
        path.startsWith(watch.folderPath + "/"),
    );

    // This can happen if the watch was removed while chokidar was still
    // emitting events for it, or if the path is from an unavailable drive.
    if (!watch) {
        log.info(`Ignoring event for path with no matching watch: ${path}`);
        return undefined;
    }

    return [path, { ...watch, isAvailable: true }];
};

export const watchGet = async (watcher: FSWatcher): Promise<FolderWatch[]> => {
    const watches: FolderWatch[] = [];
    for (const watch of storedFolderWatches()) {
        const isAvailable = await fsIsDir(watch.folderPath);
        watches.push({ ...watch, isAvailable });
        // Update chokidar: watch available paths, unwatch unavailable ones.
        if (isAvailable) {
            watcher.add(watch.folderPath);
        } else {
            watcher.unwatch(watch.folderPath);
        }
    }
    return watches;
};

/** Stored watches don't have the runtime-computed isAvailable field. */
type StoredFolderWatch = Omit<FolderWatch, "isAvailable">;

const storedFolderWatches = (): StoredFolderWatch[] =>
    watchStore.get("mappings") ?? [];

const setFolderWatches = (watches: StoredFolderWatch[]) =>
    watchStore.set("mappings", watches);

export const watchAdd = async (
    watcher: FSWatcher,
    folderPath: string,
    collectionMapping: CollectionMapping,
): Promise<FolderWatch[]> => {
    const watches = storedFolderWatches();

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

    // Return with isAvailable set (newly added watch is always available).
    return watches.map((w) => ({ ...w, isAvailable: true }));
};

export const watchRemove = (
    watcher: FSWatcher,
    folderPath: string,
): FolderWatch[] => {
    const watches = storedFolderWatches();
    const filtered = watches.filter((watch) => watch.folderPath != folderPath);
    if (watches.length == filtered.length)
        throw new Error(
            `Attempting to remove a non-existing folder watch for folder path ${folderPath}`,
        );
    setFolderWatches(filtered);
    watcher.unwatch(folderPath);
    // Return with isAvailable set. We don't know the actual state, but since
    // the user just removed one, assume remaining ones are available.
    return filtered.map((w) => ({ ...w, isAvailable: true }));
};

export const watchUpdateSyncedFiles = (
    syncedFiles: FolderWatch["syncedFiles"],
    folderPath: string,
) => {
    setFolderWatches(
        storedFolderWatches().map((watch) =>
            watch.folderPath == folderPath ? { ...watch, syncedFiles } : watch,
        ),
    );
};

export const watchUpdateIgnoredFiles = (
    ignoredFiles: FolderWatch["ignoredFiles"],
    folderPath: string,
) => {
    setFolderWatches(
        storedFolderWatches().map((watch) =>
            watch.folderPath == folderPath ? { ...watch, ignoredFiles } : watch,
        ),
    );
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
    watcher.unwatch(storedFolderWatches().map((watch) => watch.folderPath));
};
