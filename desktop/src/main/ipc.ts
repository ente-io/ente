/**
 * @file Listen for IPC events sent/invoked by the renderer process, and route
 * them to their correct handlers.
 *
 * This file is meant as a sibling to `preload.ts`, but this one runs in the
 * context of the main process, and can import other files from `src/`.
 *
 * See [Note: types.ts <-> preload.ts <-> ipc.ts]
 */

import type { FSWatcher } from "chokidar";
import type { BrowserWindow } from "electron";
import { ipcMain } from "electron/main";
import type {
    CollectionMapping,
    FFmpegCommand,
    FolderWatch,
    PendingUploads,
    UtilityProcessType,
    ZipItem,
} from "../types/ipc";
import { logToDisk } from "./log";
import {
    appVersion,
    skipAppUpdate,
    updateAndRestart,
    updateOnNextRestart,
} from "./services/app-update";
import autoLauncher from "./services/auto-launcher";
import {
    openDirectory,
    openLogDirectory,
    selectDirectory,
} from "./services/dir";
import { ffmpegDetermineVideoDuration, ffmpegExec } from "./services/ffmpeg";
import {
    fsExists,
    fsFindFiles,
    fsIsDir,
    fsMkdirIfNeeded,
    fsReadTextFile,
    fsRename,
    fsRm,
    fsRmdir,
    fsStatMtime,
    fsWriteFile,
    fsWriteFileViaBackup,
} from "./services/fs";
import { convertToJPEG, generateImageThumbnail } from "./services/image";
import { logout } from "./services/logout";
import {
    lastShownChangelogVersion,
    masterKeyFromSafeStorage,
    saveMasterKeyInSafeStorage,
    setLastShownChangelogVersion,
} from "./services/store";
import {
    clearPendingUploads,
    listZipItems,
    markUploadedFile,
    markUploadedZipItem,
    pathOrZipItemSize,
    pendingUploads,
    setPendingUploads,
} from "./services/upload";
import {
    watchAdd,
    watchGet,
    watchRemove,
    watchUpdateIgnoredFiles,
    watchUpdateSyncedFiles,
} from "./services/watch";
import { triggerCreateUtilityProcess } from "./services/workers";

/**
 * Listen for IPC events sent/invoked by the renderer process, and route them to
 * their correct handlers.
 */
export const attachIPCHandlers = () => {
    // Notes:
    //
    // The first parameter of the handler passed to `ipcMain.handle` is the
    // `event`, and is usually ignored. The rest of the parameters are the
    // arguments passed to `ipcRenderer.invoke`.
    //
    // [Note: Catching exception during .send/.on]
    //
    // While we can use ipcRenderer.send/ipcMain.on for one-way communication,
    // that has the disadvantage that any exceptions thrown in the processing of
    // the handler are not sent back to the renderer. So we use the
    // ipcRenderer.invoke/ipcMain.handle 2-way pattern even for things that are
    // conceptually one way. An exception (pun intended) to this is logToDisk,
    // which is a primitive, frequently used, operation and shouldn't throw, so
    // having its signature by synchronous is a bit convenient.

    // - General

    ipcMain.handle("appVersion", () => appVersion());

    ipcMain.handle("openDirectory", (_, dirPath: string) =>
        openDirectory(dirPath),
    );

    ipcMain.handle("openLogDirectory", () => openLogDirectory());

    // See [Note: Catching exception during .send/.on]
    ipcMain.on("logToDisk", (_, message: string) => logToDisk(message));

    ipcMain.handle("selectDirectory", () => selectDirectory());

    ipcMain.handle("masterKeyFromSafeStorage", () =>
        masterKeyFromSafeStorage(),
    );

    ipcMain.handle("saveMasterKeyInSafeStorage", (_, masterKey: string) =>
        saveMasterKeyInSafeStorage(masterKey),
    );

    ipcMain.handle("lastShownChangelogVersion", () =>
        lastShownChangelogVersion(),
    );

    ipcMain.handle("setLastShownChangelogVersion", (_, version: number) =>
        setLastShownChangelogVersion(version),
    );

    ipcMain.handle("isAutoLaunchEnabled", () => autoLauncher.isEnabled());

    ipcMain.handle("toggleAutoLaunch", () => autoLauncher.toggleAutoLaunch());

    // - App update

    ipcMain.on("updateAndRestart", () => updateAndRestart());

    ipcMain.on("updateOnNextRestart", (_, version: string) =>
        updateOnNextRestart(version),
    );

    ipcMain.on("skipAppUpdate", (_, version: string) => skipAppUpdate(version));

    // - FS

    ipcMain.handle("fsExists", (_, path: string) => fsExists(path));

    ipcMain.handle("fsRename", (_, oldPath: string, newPath: string) =>
        fsRename(oldPath, newPath),
    );

    ipcMain.handle("fsMkdirIfNeeded", (_, dirPath: string) =>
        fsMkdirIfNeeded(dirPath),
    );

    ipcMain.handle("fsRmdir", (_, path: string) => fsRmdir(path));

    ipcMain.handle("fsRm", (_, path: string) => fsRm(path));

    ipcMain.handle("fsReadTextFile", (_, path: string) => fsReadTextFile(path));

    ipcMain.handle("fsWriteFile", (_, path: string, contents: string) =>
        fsWriteFile(path, contents),
    );

    ipcMain.handle(
        "fsWriteFileViaBackup",
        (_, path: string, contents: string) =>
            fsWriteFileViaBackup(path, contents),
    );

    ipcMain.handle("fsIsDir", (_, dirPath: string) => fsIsDir(dirPath));

    ipcMain.handle("fsStatMtime", (_, path: string) => fsStatMtime(path));

    ipcMain.handle("fsFindFiles", (_, folderPath: string) =>
        fsFindFiles(folderPath),
    );

    // - Conversion

    ipcMain.handle("convertToJPEG", (_, imageData: Uint8Array) =>
        convertToJPEG(imageData),
    );

    ipcMain.handle(
        "generateImageThumbnail",
        (
            _,
            pathOrZipItem: string | ZipItem,
            maxDimension: number,
            maxSize: number,
        ) => generateImageThumbnail(pathOrZipItem, maxDimension, maxSize),
    );

    ipcMain.handle(
        "ffmpegExec",
        (
            _,
            command: FFmpegCommand,
            pathOrZipItem: string | ZipItem,
            outputFileExtension: string,
        ) => ffmpegExec(command, pathOrZipItem, outputFileExtension),
    );

    ipcMain.handle(
        "ffmpegDetermineVideoDuration",
        (_, pathOrZipItem: string | ZipItem) =>
            ffmpegDetermineVideoDuration(pathOrZipItem),
    );

    // - Upload

    ipcMain.handle("listZipItems", (_, zipPath: string) =>
        listZipItems(zipPath),
    );

    ipcMain.handle("pathOrZipItemSize", (_, pathOrZipItem: string | ZipItem) =>
        pathOrZipItemSize(pathOrZipItem),
    );

    ipcMain.handle("pendingUploads", () => pendingUploads());

    ipcMain.handle("setPendingUploads", (_, pendingUploads: PendingUploads) =>
        setPendingUploads(pendingUploads),
    );

    ipcMain.handle(
        "markUploadedFile",
        (_, path: string, associatedPath: string | undefined) =>
            markUploadedFile(path, associatedPath),
    );

    ipcMain.handle(
        "markUploadedZipItem",
        (_, item: ZipItem, associatedItem: ZipItem | undefined) =>
            markUploadedZipItem(item, associatedItem),
    );

    ipcMain.handle("clearPendingUploads", () => clearPendingUploads());
};

/**
 * A subset of {@link attachIPCHandlers} for functions that need a reference to
 * the main window to do their thing.
 */
export const attachMainWindowIPCHandlers = (mainWindow: BrowserWindow) => {
    // - Utility processes

    ipcMain.on("triggerCreateUtilityProcess", (_, type: UtilityProcessType) =>
        triggerCreateUtilityProcess(type, mainWindow),
    );
};

/**
 * Sibling of {@link attachIPCHandlers} that attaches handlers specific to the
 * watch folder functionality.
 *
 * It gets passed a {@link FSWatcher} instance which it can then forward to the
 * actual handlers if they need access to it to do their thing.
 */
export const attachFSWatchIPCHandlers = (watcher: FSWatcher) => {
    // - Watch

    ipcMain.handle("watchGet", () => watchGet(watcher));

    ipcMain.handle(
        "watchAdd",
        (_, folderPath: string, collectionMapping: CollectionMapping) =>
            watchAdd(watcher, folderPath, collectionMapping),
    );

    ipcMain.handle("watchRemove", (_, folderPath: string) =>
        watchRemove(watcher, folderPath),
    );

    ipcMain.handle(
        "watchUpdateSyncedFiles",
        (_, syncedFiles: FolderWatch["syncedFiles"], folderPath: string) =>
            watchUpdateSyncedFiles(syncedFiles, folderPath),
    );

    ipcMain.handle(
        "watchUpdateIgnoredFiles",
        (_, ignoredFiles: FolderWatch["ignoredFiles"], folderPath: string) =>
            watchUpdateIgnoredFiles(ignoredFiles, folderPath),
    );
};

/**
 * Sibling of {@link attachIPCHandlers} specifically for use with the logout
 * event with needs access to the {@link FSWatcher} instance.
 */
export const attachLogoutIPCHandler = (watcher: FSWatcher) => {
    ipcMain.handle("logout", () => logout(watcher));
};
