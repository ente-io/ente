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
import { clearElectronStore } from "../api/electronStore";
import { getEncryptionKey, setEncryptionKey } from "../api/safeStorage";
import {
    getElectronFilesFromGoogleZip,
    getPendingUploads,
    setToUploadCollection,
    setToUploadFiles,
} from "../api/upload";
import {
    appVersion,
    muteUpdateNotification,
    skipAppUpdate,
    updateAndRestart,
} from "../services/appUpdater";
import {
    computeImageEmbedding,
    computeTextEmbedding,
} from "../services/clipService";
import { runFFmpegCmd } from "../services/ffmpeg";
import { getDirFiles } from "../services/fs";
import {
    convertToJPEG,
    generateImageThumbnail,
} from "../services/imageProcessor";
import {
    addWatchMapping,
    getWatchMappings,
    removeWatchMapping,
    updateWatchMappingIgnoredFiles,
    updateWatchMappingSyncedFiles,
} from "../services/watch";
import type {
    ElectronFile,
    FILE_PATH_TYPE,
    Model,
    WatchMapping,
} from "../types/ipc";
import {
    selectDirectory,
    showUploadDirsDialog,
    showUploadFilesDialog,
    showUploadZipDialog,
} from "./dialogs";
import {
    checkExistsAndCreateDir,
    deleteFile,
    deleteFolder,
    fsExists,
    isFolder,
    moveFile,
    readTextFile,
    rename,
    saveFileToDisk,
    saveStreamToDisk,
} from "./fs";
import { logToDisk } from "./log";
import { openDirectory, openLogDirectory } from "./util";

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

    ipcMain.handle("appVersion", (_) => appVersion());

    ipcMain.handle("openDirectory", (_, dirPath) => openDirectory(dirPath));

    ipcMain.handle("openLogDirectory", (_) => openLogDirectory());

    // See [Note: Catching exception during .send/.on]
    ipcMain.on("logToDisk", (_, message) => logToDisk(message));

    ipcMain.on("clear-electron-store", (_) => {
        clearElectronStore();
    });

    ipcMain.handle("setEncryptionKey", (_, encryptionKey) =>
        setEncryptionKey(encryptionKey),
    );

    ipcMain.handle("getEncryptionKey", (_) => getEncryptionKey());

    // - App update

    ipcMain.on("update-and-restart", (_) => updateAndRestart());

    ipcMain.on("skip-app-update", (_, version) => skipAppUpdate(version));

    ipcMain.on("mute-update-notification", (_, version) =>
        muteUpdateNotification(version),
    );

    // - Conversion

    ipcMain.handle("convertToJPEG", (_, fileData, filename) =>
        convertToJPEG(fileData, filename),
    );

    ipcMain.handle(
        "generateImageThumbnail",
        (_, inputFile, maxDimension, maxSize) =>
            generateImageThumbnail(inputFile, maxDimension, maxSize),
    );

    ipcMain.handle(
        "runFFmpegCmd",
        (
            _,
            cmd: string[],
            inputFile: File | ElectronFile,
            outputFileName: string,
            dontTimeout?: boolean,
        ) => runFFmpegCmd(cmd, inputFile, outputFileName, dontTimeout),
    );

    // - ML

    ipcMain.handle(
        "computeImageEmbedding",
        (_, model: Model, imageData: Uint8Array) =>
            computeImageEmbedding(model, imageData),
    );

    ipcMain.handle("computeTextEmbedding", (_, model: Model, text: string) =>
        computeTextEmbedding(model, text),
    );

    // - File selection

    ipcMain.handle("selectDirectory", (_) => selectDirectory());

    ipcMain.handle("showUploadFilesDialog", (_) => showUploadFilesDialog());

    ipcMain.handle("showUploadDirsDialog", (_) => showUploadDirsDialog());

    ipcMain.handle("showUploadZipDialog", (_) => showUploadZipDialog());

    // - FS

    ipcMain.handle("fsExists", (_, path) => fsExists(path));

    // - FS Legacy

    ipcMain.handle("checkExistsAndCreateDir", (_, dirPath) =>
        checkExistsAndCreateDir(dirPath),
    );

    ipcMain.handle(
        "saveStreamToDisk",
        (_, path: string, fileStream: ReadableStream<any>) =>
            saveStreamToDisk(path, fileStream),
    );

    ipcMain.handle("saveFileToDisk", (_, path: string, file: any) =>
        saveFileToDisk(path, file),
    );

    ipcMain.handle("readTextFile", (_, path: string) => readTextFile(path));

    ipcMain.handle("isFolder", (_, dirPath: string) => isFolder(dirPath));

    ipcMain.handle("moveFile", (_, oldPath: string, newPath: string) =>
        moveFile(oldPath, newPath),
    );

    ipcMain.handle("deleteFolder", (_, path: string) => deleteFolder(path));

    ipcMain.handle("deleteFile", (_, path: string) => deleteFile(path));

    ipcMain.handle("rename", (_, oldPath: string, newPath: string) =>
        rename(oldPath, newPath),
    );

    // - Upload

    ipcMain.handle("getPendingUploads", (_) => getPendingUploads());

    ipcMain.handle(
        "setToUploadFiles",
        (_, type: FILE_PATH_TYPE, filePaths: string[]) =>
            setToUploadFiles(type, filePaths),
    );

    ipcMain.handle("getElectronFilesFromGoogleZip", (_, filePath: string) =>
        getElectronFilesFromGoogleZip(filePath),
    );

    ipcMain.handle("setToUploadCollection", (_, collectionName: string) =>
        setToUploadCollection(collectionName),
    );

    ipcMain.handle("getDirFiles", (_, dirPath: string) => getDirFiles(dirPath));
};

/**
 * Sibling of {@link attachIPCHandlers} that attaches handlers specific to the
 * watch folder functionality.
 *
 * It gets passed a {@link FSWatcher} instance which it can then forward to the
 * actual handlers.
 */
export const attachFSWatchIPCHandlers = (watcher: FSWatcher) => {
    // - Watch

    ipcMain.handle(
        "addWatchMapping",
        (
            _,
            collectionName: string,
            folderPath: string,
            uploadStrategy: number,
        ) =>
            addWatchMapping(
                watcher,
                collectionName,
                folderPath,
                uploadStrategy,
            ),
    );

    ipcMain.handle("removeWatchMapping", (_, folderPath: string) =>
        removeWatchMapping(watcher, folderPath),
    );

    ipcMain.handle("getWatchMappings", (_) => getWatchMappings());

    ipcMain.handle(
        "updateWatchMappingSyncedFiles",
        (_, folderPath: string, files: WatchMapping["syncedFiles"]) =>
            updateWatchMappingSyncedFiles(folderPath, files),
    );

    ipcMain.handle(
        "updateWatchMappingIgnoredFiles",
        (_, folderPath: string, files: WatchMapping["ignoredFiles"]) =>
            updateWatchMappingIgnoredFiles(folderPath, files),
    );
};
