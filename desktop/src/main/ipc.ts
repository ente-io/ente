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
import { ipcMain } from "electron/main";
import type {
    CollectionMapping,
    FolderWatch,
    PendingUploads,
    ZipItem,
} from "../types/ipc";
import { logToDisk } from "./log";
import {
    appVersion,
    skipAppUpdate,
    updateAndRestart,
    updateOnNextRestart,
} from "./services/app-update";
import {
    legacyFaceCrop,
    openDirectory,
    openLogDirectory,
    selectDirectory,
} from "./services/dir";
import { ffmpegExec } from "./services/ffmpeg";
import {
    fsExists,
    fsIsDir,
    fsMkdirIfNeeded,
    fsReadTextFile,
    fsRename,
    fsRm,
    fsRmdir,
    fsWriteFile,
} from "./services/fs";
import { convertToJPEG, generateImageThumbnail } from "./services/image";
import {
    clipImageEmbedding,
    clipTextEmbeddingIfAvailable,
} from "./services/ml-clip";
import { detectFaces, faceEmbedding } from "./services/ml-face";
import {
    clearStores,
    encryptionKey,
    saveEncryptionKey,
} from "./services/store";
import {
    clearPendingUploads,
    listZipItems,
    markUploadedFiles,
    markUploadedZipItems,
    pathOrZipItemSize,
    pendingUploads,
    setPendingUploads,
} from "./services/upload";
import {
    watchAdd,
    watchFindFiles,
    watchGet,
    watchRemove,
    watchReset,
    watchUpdateIgnoredFiles,
    watchUpdateSyncedFiles,
} from "./services/watch";
import { clearConvertToMP4Results } from "./stream";

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

    ipcMain.on("clearStores", () => clearStores());

    ipcMain.on("clearConvertToMP4Results", () => clearConvertToMP4Results());

    ipcMain.handle("saveEncryptionKey", (_, encryptionKey: string) =>
        saveEncryptionKey(encryptionKey),
    );

    ipcMain.handle("encryptionKey", () => encryptionKey());

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

    ipcMain.handle("fsIsDir", (_, dirPath: string) => fsIsDir(dirPath));

    // - Conversion

    ipcMain.handle("convertToJPEG", (_, imageData: Uint8Array) =>
        convertToJPEG(imageData),
    );

    ipcMain.handle(
        "generateImageThumbnail",
        (
            _,
            dataOrPathOrZipItem: Uint8Array | string | ZipItem,
            maxDimension: number,
            maxSize: number,
        ) => generateImageThumbnail(dataOrPathOrZipItem, maxDimension, maxSize),
    );

    ipcMain.handle(
        "ffmpegExec",
        (
            _,
            command: string[],
            dataOrPathOrZipItem: Uint8Array | string | ZipItem,
            outputFileExtension: string,
        ) => ffmpegExec(command, dataOrPathOrZipItem, outputFileExtension),
    );

    // - ML

    ipcMain.handle("clipImageEmbedding", (_, jpegImageData: Uint8Array) =>
        clipImageEmbedding(jpegImageData),
    );

    ipcMain.handle("clipTextEmbeddingIfAvailable", (_, text: string) =>
        clipTextEmbeddingIfAvailable(text),
    );

    ipcMain.handle("detectFaces", (_, input: Float32Array) =>
        detectFaces(input),
    );

    ipcMain.handle("faceEmbedding", (_, input: Float32Array) =>
        faceEmbedding(input),
    );

    ipcMain.handle("legacyFaceCrop", (_, faceID: string) =>
        legacyFaceCrop(faceID),
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
        "markUploadedFiles",
        (_, paths: PendingUploads["filePaths"]) => markUploadedFiles(paths),
    );

    ipcMain.handle(
        "markUploadedZipItems",
        (_, items: PendingUploads["zipItems"]) => markUploadedZipItems(items),
    );

    ipcMain.handle("clearPendingUploads", () => clearPendingUploads());
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

    ipcMain.handle("watchFindFiles", (_, folderPath: string) =>
        watchFindFiles(folderPath),
    );

    ipcMain.handle("watchReset", () => watchReset(watcher));
};
