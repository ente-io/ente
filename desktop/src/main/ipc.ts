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
} from "../types/ipc";
import {
    selectDirectory,
    showUploadDirsDialog,
    showUploadFilesDialog,
    showUploadZipDialog,
} from "./dialogs";
import {
    fsExists,
    fsIsDir,
    fsMkdirIfNeeded,
    fsReadTextFile,
    fsRename,
    fsRm,
    fsRmdir,
    fsWriteFile,
} from "./fs";
import { logToDisk } from "./log";
import {
    appVersion,
    skipAppUpdate,
    updateAndRestart,
    updateOnNextRestart,
} from "./services/app-update";
import { ffmpegExec } from "./services/ffmpeg";
import { getDirFiles } from "./services/fs";
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
    getElectronFilesFromGoogleZip,
    pendingUploads,
    setPendingUploadCollection,
    setPendingUploadFiles,
} from "./services/upload";
import {
    watchAdd,
    watchFindFiles,
    watchGet,
    watchRemove,
    watchUpdateIgnoredFiles,
    watchUpdateSyncedFiles,
} from "./services/watch";
import { openDirectory, openLogDirectory } from "./utils-electron";

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

    ipcMain.handle("openDirectory", (_, dirPath) => openDirectory(dirPath));

    ipcMain.handle("openLogDirectory", () => openLogDirectory());

    // See [Note: Catching exception during .send/.on]
    ipcMain.on("logToDisk", (_, message) => logToDisk(message));

    ipcMain.on("clearStores", () => clearStores());

    ipcMain.handle("saveEncryptionKey", (_, encryptionKey) =>
        saveEncryptionKey(encryptionKey),
    );

    ipcMain.handle("encryptionKey", () => encryptionKey());

    // - App update

    ipcMain.on("updateAndRestart", () => updateAndRestart());

    ipcMain.on("updateOnNextRestart", (_, version) =>
        updateOnNextRestart(version),
    );

    ipcMain.on("skipAppUpdate", (_, version) => skipAppUpdate(version));

    // - FS

    ipcMain.handle("fsExists", (_, path) => fsExists(path));

    ipcMain.handle("fsRename", (_, oldPath: string, newPath: string) =>
        fsRename(oldPath, newPath),
    );

    ipcMain.handle("fsMkdirIfNeeded", (_, dirPath) => fsMkdirIfNeeded(dirPath));

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
            dataOrPath: Uint8Array | string,
            maxDimension: number,
            maxSize: number,
        ) => generateImageThumbnail(dataOrPath, maxDimension, maxSize),
    );

    ipcMain.handle(
        "ffmpegExec",
        (
            _,
            command: string[],
            dataOrPath: Uint8Array | string,
            outputFileExtension: string,
            timeoutMS: number,
        ) => ffmpegExec(command, dataOrPath, outputFileExtension, timeoutMS),
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

    // - File selection

    ipcMain.handle("selectDirectory", () => selectDirectory());

    ipcMain.handle("showUploadFilesDialog", () => showUploadFilesDialog());

    ipcMain.handle("showUploadDirsDialog", () => showUploadDirsDialog());

    ipcMain.handle("showUploadZipDialog", () => showUploadZipDialog());

    // - Upload

    ipcMain.handle("pendingUploads", () => pendingUploads());

    ipcMain.handle("setPendingUploadCollection", (_, collectionName: string) =>
        setPendingUploadCollection(collectionName),
    );

    ipcMain.handle(
        "setPendingUploadFiles",
        (_, type: PendingUploads["type"], filePaths: string[]) =>
            setPendingUploadFiles(type, filePaths),
    );

    // -

    ipcMain.handle("getElectronFilesFromGoogleZip", (_, filePath: string) =>
        getElectronFilesFromGoogleZip(filePath),
    );

    ipcMain.handle("getDirFiles", (_, dirPath: string) => getDirFiles(dirPath));
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
};
