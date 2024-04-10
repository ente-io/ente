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
import {
    appVersion,
    skipAppUpdate,
    updateAndRestart,
    updateOnNextRestart,
} from "../services/app-update";
import { clipImageEmbedding, clipTextEmbedding } from "../services/clip";
import { runFFmpegCmd } from "../services/ffmpeg";
import { getDirFiles } from "../services/fs";
import {
    convertToJPEG,
    generateImageThumbnail,
} from "../services/imageProcessor";
import {
    clearStores,
    encryptionKey,
    saveEncryptionKey,
} from "../services/store";
import {
    getElectronFilesFromGoogleZip,
    getPendingUploads,
    setToUploadCollection,
    setToUploadFiles,
} from "../services/upload";
import {
    addWatchMapping,
    getWatchMappings,
    removeWatchMapping,
    updateWatchMappingIgnoredFiles,
    updateWatchMappingSyncedFiles,
} from "../services/watch";
import type { ElectronFile, FILE_PATH_TYPE, WatchMapping } from "../types/ipc";
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

    ipcMain.handle("clipImageEmbedding", (_, jpegImageData: Uint8Array) =>
        clipImageEmbedding(jpegImageData),
    );

    ipcMain.handle("clipTextEmbedding", (_, text: string) =>
        clipTextEmbedding(text),
    );

    // - File selection

    ipcMain.handle("selectDirectory", () => selectDirectory());

    ipcMain.handle("showUploadFilesDialog", () => showUploadFilesDialog());

    ipcMain.handle("showUploadDirsDialog", () => showUploadDirsDialog());

    ipcMain.handle("showUploadZipDialog", () => showUploadZipDialog());

    // - FS

    ipcMain.handle("fsExists", (_, path) => fsExists(path));

    // - FS Legacy

    ipcMain.handle("checkExistsAndCreateDir", (_, dirPath) =>
        checkExistsAndCreateDir(dirPath),
    );

    ipcMain.handle(
        "saveStreamToDisk",
        (_, path: string, fileStream: ReadableStream) =>
            saveStreamToDisk(path, fileStream),
    );

    ipcMain.handle("saveFileToDisk", (_, path: string, contents: string) =>
        saveFileToDisk(path, contents),
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

    ipcMain.handle("getPendingUploads", () => getPendingUploads());

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

    ipcMain.handle("getWatchMappings", () => getWatchMappings());

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
