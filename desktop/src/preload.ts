/* eslint-disable no-unused-vars */
/**
 * @file The preload script
 *
 * The preload script runs in a renderer process before its web contents begin
 * loading. During their execution they have access to a subset of Node.js APIs
 * and imports. Its purpose is to expose the relevant imports and other
 * functions as an object on the DOM, so that the renderer process can invoke
 * functions that live in the main (Node.js) process if needed.
 *
 * Ref: https://www.electronjs.org/docs/latest/tutorial/tutorial-preload
 *
 * Note that this script cannot import other code from `src/` - conceptually it
 * can be thought of as running in a separate, third, process different from
 * both the main or a renderer process (technically, it runs in a BrowserWindow
 * context that runs prior to the renderer process).
 *
 * > Since enabling the sandbox disables Node.js integration in your preload
 * > scripts, you can no longer use require("../my-script"). In other words,
 * > your preload script needs to be a single file.
 * >
 * > https://www.electronjs.org/blog/breach-to-barrier
 *
 * If we really wanted, we could setup a bundler to package this into a single
 * file. However, since this is just boilerplate code providing a bridge between
 * the main and renderer, we avoid introducing another moving part into the mix
 * and just keep the entire preload setup in this single file.
 *
 * [Note: types.ts <-> preload.ts <-> ipc.ts]
 *
 * The following three files are boilerplatish linkage of the same functions,
 * and when changing one of them, remember to see if the other two also need
 * changing:
 *
 * -    [renderer]  web/packages/next/types/electron.ts      contains docs
 * -    [preload]   desktop/src/preload.ts                         ↕︎
 * -    [main]      desktop/src/main/ipc.ts                  contains impl
 */

import { contextBridge, ipcRenderer } from "electron/renderer";

// While we can't import other code, we can import types since they're just
// needed when compiling and will not be needed / looked around for at runtime.
import type {
    AppUpdateInfo,
    ElectronFile,
    FILE_PATH_TYPE,
    WatchMapping,
} from "./types/ipc";

// - General

const appVersion = (): Promise<string> => ipcRenderer.invoke("appVersion");

const logToDisk = (message: string): void =>
    ipcRenderer.send("logToDisk", message);

const openDirectory = (dirPath: string): Promise<void> =>
    ipcRenderer.invoke("openDirectory", dirPath);

const openLogDirectory = (): Promise<void> =>
    ipcRenderer.invoke("openLogDirectory");

const clearStores = () => ipcRenderer.send("clearStores");

const encryptionKey = (): Promise<string | undefined> =>
    ipcRenderer.invoke("encryptionKey");

const saveEncryptionKey = (encryptionKey: string): Promise<void> =>
    ipcRenderer.invoke("saveEncryptionKey", encryptionKey);

const onMainWindowFocus = (cb?: () => void) => {
    ipcRenderer.removeAllListeners("mainWindowFocus");
    if (cb) ipcRenderer.on("mainWindowFocus", cb);
};

// - App update

const onAppUpdateAvailable = (
    cb?: ((updateInfo: AppUpdateInfo) => void) | undefined,
) => {
    ipcRenderer.removeAllListeners("appUpdateAvailable");
    if (cb) {
        ipcRenderer.on("appUpdateAvailable", (_, updateInfo: AppUpdateInfo) =>
            cb(updateInfo),
        );
    }
};

const updateAndRestart = () => ipcRenderer.send("updateAndRestart");

const updateOnNextRestart = (version: string) =>
    ipcRenderer.send("updateOnNextRestart", version);

const skipAppUpdate = (version: string) => {
    ipcRenderer.send("skipAppUpdate", version);
};

const fsExists = (path: string): Promise<boolean> =>
    ipcRenderer.invoke("fsExists", path);

// - AUDIT below this

// - Conversion

const convertToJPEG = (
    fileData: Uint8Array,
    filename: string,
): Promise<Uint8Array> =>
    ipcRenderer.invoke("convertToJPEG", fileData, filename);

const generateImageThumbnail = (
    inputFile: File | ElectronFile,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> =>
    ipcRenderer.invoke(
        "generateImageThumbnail",
        inputFile,
        maxDimension,
        maxSize,
    );

const runFFmpegCmd = (
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFileName: string,
    dontTimeout?: boolean,
): Promise<File> =>
    ipcRenderer.invoke(
        "runFFmpegCmd",
        cmd,
        inputFile,
        outputFileName,
        dontTimeout,
    );

// - ML

const clipImageEmbedding = (jpegImageData: Uint8Array): Promise<Float32Array> =>
    ipcRenderer.invoke("clipImageEmbedding", jpegImageData);

const clipTextEmbedding = (text: string): Promise<Float32Array> =>
    ipcRenderer.invoke("clipTextEmbedding", text);

// - File selection

// TODO: Deprecated - use dialogs on the renderer process itself

const selectDirectory = (): Promise<string> =>
    ipcRenderer.invoke("selectDirectory");

const showUploadFilesDialog = (): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("showUploadFilesDialog");

const showUploadDirsDialog = (): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("showUploadDirsDialog");

const showUploadZipDialog = (): Promise<{
    zipPaths: string[];
    files: ElectronFile[];
}> => ipcRenderer.invoke("showUploadZipDialog");

// - Watch

const registerWatcherFunctions = (
    addFile: (file: ElectronFile) => Promise<void>,
    removeFile: (path: string) => Promise<void>,
    removeFolder: (folderPath: string) => Promise<void>,
) => {
    ipcRenderer.removeAllListeners("watch-add");
    ipcRenderer.removeAllListeners("watch-unlink");
    ipcRenderer.removeAllListeners("watch-unlink-dir");
    ipcRenderer.on("watch-add", (_, file: ElectronFile) => addFile(file));
    ipcRenderer.on("watch-unlink", (_, filePath: string) =>
        removeFile(filePath),
    );
    ipcRenderer.on("watch-unlink-dir", (_, folderPath: string) =>
        removeFolder(folderPath),
    );
};

const addWatchMapping = (
    collectionName: string,
    folderPath: string,
    uploadStrategy: number,
): Promise<void> =>
    ipcRenderer.invoke(
        "addWatchMapping",
        collectionName,
        folderPath,
        uploadStrategy,
    );

const removeWatchMapping = (folderPath: string): Promise<void> =>
    ipcRenderer.invoke("removeWatchMapping", folderPath);

const getWatchMappings = (): Promise<WatchMapping[]> =>
    ipcRenderer.invoke("getWatchMappings");

const updateWatchMappingSyncedFiles = (
    folderPath: string,
    files: WatchMapping["syncedFiles"],
): Promise<void> =>
    ipcRenderer.invoke("updateWatchMappingSyncedFiles", folderPath, files);

const updateWatchMappingIgnoredFiles = (
    folderPath: string,
    files: WatchMapping["ignoredFiles"],
): Promise<void> =>
    ipcRenderer.invoke("updateWatchMappingIgnoredFiles", folderPath, files);

// - FS Legacy

const checkExistsAndCreateDir = (dirPath: string): Promise<void> =>
    ipcRenderer.invoke("checkExistsAndCreateDir", dirPath);

const saveStreamToDisk = (
    path: string,
    fileStream: ReadableStream,
): Promise<void> => ipcRenderer.invoke("saveStreamToDisk", path, fileStream);

const saveFileToDisk = (path: string, contents: string): Promise<void> =>
    ipcRenderer.invoke("saveFileToDisk", path, contents);

const readTextFile = (path: string): Promise<string> =>
    ipcRenderer.invoke("readTextFile", path);

const isFolder = (dirPath: string): Promise<boolean> =>
    ipcRenderer.invoke("isFolder", dirPath);

const moveFile = (oldPath: string, newPath: string): Promise<void> =>
    ipcRenderer.invoke("moveFile", oldPath, newPath);

const deleteFolder = (path: string): Promise<void> =>
    ipcRenderer.invoke("deleteFolder", path);

const deleteFile = (path: string): Promise<void> =>
    ipcRenderer.invoke("deleteFile", path);

const rename = (oldPath: string, newPath: string): Promise<void> =>
    ipcRenderer.invoke("rename", oldPath, newPath);

// - Upload

const getPendingUploads = (): Promise<{
    files: ElectronFile[];
    collectionName: string;
    type: string;
}> => ipcRenderer.invoke("getPendingUploads");

const setToUploadFiles = (
    type: FILE_PATH_TYPE,
    filePaths: string[],
): Promise<void> => ipcRenderer.invoke("setToUploadFiles", type, filePaths);

const getElectronFilesFromGoogleZip = (
    filePath: string,
): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("getElectronFilesFromGoogleZip", filePath);

const setToUploadCollection = (collectionName: string): Promise<void> =>
    ipcRenderer.invoke("setToUploadCollection", collectionName);

const getDirFiles = (dirPath: string): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("getDirFiles", dirPath);

// These objects exposed here will become available to the JS code in our
// renderer (the web/ code) as `window.ElectronAPIs.*`
//
// There are a few related concepts at play here, and it might be worthwhile to
// read their (excellent) documentation to get an understanding;
//`
// - ContextIsolation:
//   https://www.electronjs.org/docs/latest/tutorial/context-isolation
//
// - IPC https://www.electronjs.org/docs/latest/tutorial/ipc
//
// [Note: Transferring large amount of data over IPC]
//
// Electron's IPC implementation uses the HTML standard Structured Clone
// Algorithm to serialize objects passed between processes.
// https://www.electronjs.org/docs/latest/tutorial/ipc#object-serialization
//
// In particular, ArrayBuffer is eligible for structured cloning.
// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
//
// Also, ArrayBuffer is "transferable", which means it is a zero-copy operation
// operation when it happens across threads.
// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects
//
// In our case though, we're not dealing with threads but separate processes. So
// the ArrayBuffer will be copied:
// > "parameters, errors and return values are **copied** when they're sent over
//   the bridge".
//   https://www.electronjs.org/docs/latest/api/context-bridge#methods
//
// The copy itself is relatively fast, but the problem with transfering large
// amounts of data is potentially running out of memory during the copy.
contextBridge.exposeInMainWorld("electron", {
    // - General
    appVersion,
    logToDisk,
    openDirectory,
    openLogDirectory,
    clearStores,
    encryptionKey,
    saveEncryptionKey,
    onMainWindowFocus,

    // - App update
    onAppUpdateAvailable,
    updateAndRestart,
    updateOnNextRestart,
    skipAppUpdate,

    // - Conversion
    convertToJPEG,
    generateImageThumbnail,
    runFFmpegCmd,

    // - ML
    clipImageEmbedding,
    clipTextEmbedding,

    // - File selection
    selectDirectory,
    showUploadFilesDialog,
    showUploadDirsDialog,
    showUploadZipDialog,

    // - Watch
    registerWatcherFunctions,
    addWatchMapping,
    removeWatchMapping,
    getWatchMappings,
    updateWatchMappingSyncedFiles,
    updateWatchMappingIgnoredFiles,

    // - FS
    fs: {
        exists: fsExists,
    },

    // - FS legacy
    // TODO: Move these into fs + document + rename if needed
    checkExistsAndCreateDir,
    saveStreamToDisk,
    saveFileToDisk,
    readTextFile,
    isFolder,
    moveFile,
    deleteFolder,
    deleteFile,
    rename,

    // - Upload

    getPendingUploads,
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
    getDirFiles,
});
