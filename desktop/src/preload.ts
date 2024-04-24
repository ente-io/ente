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
// needed when compiling and will not be needed or looked around for at runtime.
import type {
    AppUpdate,
    CollectionMapping,
    ElectronFile,
    FolderWatch,
    PendingUploads,
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
    cb?: ((update: AppUpdate) => void) | undefined,
) => {
    ipcRenderer.removeAllListeners("appUpdateAvailable");
    if (cb) {
        ipcRenderer.on("appUpdateAvailable", (_, update: AppUpdate) =>
            cb(update),
        );
    }
};

const updateAndRestart = () => ipcRenderer.send("updateAndRestart");

const updateOnNextRestart = (version: string) =>
    ipcRenderer.send("updateOnNextRestart", version);

const skipAppUpdate = (version: string) => {
    ipcRenderer.send("skipAppUpdate", version);
};

// - FS

const fsExists = (path: string): Promise<boolean> =>
    ipcRenderer.invoke("fsExists", path);

const fsMkdirIfNeeded = (dirPath: string): Promise<void> =>
    ipcRenderer.invoke("fsMkdirIfNeeded", dirPath);

const fsRename = (oldPath: string, newPath: string): Promise<void> =>
    ipcRenderer.invoke("fsRename", oldPath, newPath);

const fsRmdir = (path: string): Promise<void> =>
    ipcRenderer.invoke("fsRmdir", path);

const fsRm = (path: string): Promise<void> => ipcRenderer.invoke("fsRm", path);

const fsReadTextFile = (path: string): Promise<string> =>
    ipcRenderer.invoke("fsReadTextFile", path);

const fsWriteFile = (path: string, contents: string): Promise<void> =>
    ipcRenderer.invoke("fsWriteFile", path, contents);

const fsIsDir = (dirPath: string): Promise<boolean> =>
    ipcRenderer.invoke("fsIsDir", dirPath);

// - Conversion

const convertToJPEG = (imageData: Uint8Array): Promise<Uint8Array> =>
    ipcRenderer.invoke("convertToJPEG", imageData);

const generateImageThumbnail = (
    dataOrPath: Uint8Array | string,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> =>
    ipcRenderer.invoke(
        "generateImageThumbnail",
        dataOrPath,
        maxDimension,
        maxSize,
    );

const ffmpegExec = (
    command: string[],
    dataOrPath: Uint8Array | string,
    outputFileExtension: string,
    timeoutMS: number,
): Promise<Uint8Array> =>
    ipcRenderer.invoke(
        "ffmpegExec",
        command,
        dataOrPath,
        outputFileExtension,
        timeoutMS,
    );

// - ML

const clipImageEmbedding = (jpegImageData: Uint8Array): Promise<Float32Array> =>
    ipcRenderer.invoke("clipImageEmbedding", jpegImageData);

const clipTextEmbeddingIfAvailable = (
    text: string,
): Promise<Float32Array | undefined> =>
    ipcRenderer.invoke("clipTextEmbeddingIfAvailable", text);

const detectFaces = (input: Float32Array): Promise<Float32Array> =>
    ipcRenderer.invoke("detectFaces", input);

const faceEmbedding = (input: Float32Array): Promise<Float32Array> =>
    ipcRenderer.invoke("faceEmbedding", input);

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

const watchGet = (): Promise<FolderWatch[]> => ipcRenderer.invoke("watchGet");

const watchAdd = (
    folderPath: string,
    collectionMapping: CollectionMapping,
): Promise<FolderWatch[]> =>
    ipcRenderer.invoke("watchAdd", folderPath, collectionMapping);

const watchRemove = (folderPath: string): Promise<FolderWatch[]> =>
    ipcRenderer.invoke("watchRemove", folderPath);

const watchUpdateSyncedFiles = (
    syncedFiles: FolderWatch["syncedFiles"],
    folderPath: string,
): Promise<void> =>
    ipcRenderer.invoke("watchUpdateSyncedFiles", syncedFiles, folderPath);

const watchUpdateIgnoredFiles = (
    ignoredFiles: FolderWatch["ignoredFiles"],
    folderPath: string,
): Promise<void> =>
    ipcRenderer.invoke("watchUpdateIgnoredFiles", ignoredFiles, folderPath);

const watchOnAddFile = (f: (path: string, watch: FolderWatch) => void) => {
    ipcRenderer.removeAllListeners("watchAddFile");
    ipcRenderer.on("watchAddFile", (_, path: string, watch: FolderWatch) =>
        f(path, watch),
    );
};

const watchOnRemoveFile = (f: (path: string, watch: FolderWatch) => void) => {
    ipcRenderer.removeAllListeners("watchRemoveFile");
    ipcRenderer.on("watchRemoveFile", (_, path: string, watch: FolderWatch) =>
        f(path, watch),
    );
};

const watchOnRemoveDir = (f: (path: string, watch: FolderWatch) => void) => {
    ipcRenderer.removeAllListeners("watchRemoveDir");
    ipcRenderer.on("watchRemoveDir", (_, path: string, watch: FolderWatch) =>
        f(path, watch),
    );
};

const watchFindFiles = (folderPath: string): Promise<string[]> =>
    ipcRenderer.invoke("watchFindFiles", folderPath);

// - Upload

const pendingUploads = (): Promise<PendingUploads | undefined> =>
    ipcRenderer.invoke("pendingUploads");

const setPendingUploadCollection = (collectionName: string): Promise<void> =>
    ipcRenderer.invoke("setPendingUploadCollection", collectionName);

const setPendingUploadFiles = (
    type: PendingUploads["type"],
    filePaths: string[],
): Promise<void> =>
    ipcRenderer.invoke("setPendingUploadFiles", type, filePaths);

// - TODO: AUDIT below this
// -

const getElectronFilesFromGoogleZip = (
    filePath: string,
): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("getElectronFilesFromGoogleZip", filePath);

const getDirFiles = (dirPath: string): Promise<ElectronFile[]> =>
    ipcRenderer.invoke("getDirFiles", dirPath);

/**
 * These objects exposed here will become available to the JS code in our
 * renderer (the web/ code) as `window.ElectronAPIs.*`
 *
 * There are a few related concepts at play here, and it might be worthwhile to
 * read their (excellent) documentation to get an understanding;
 *`
 * - ContextIsolation:
 *   https://www.electronjs.org/docs/latest/tutorial/context-isolation
 *
 * - IPC https://www.electronjs.org/docs/latest/tutorial/ipc
 *
 * ---
 *
 * [Note: Transferring large amount of data over IPC]
 *
 * Electron's IPC implementation uses the HTML standard Structured Clone
 * Algorithm to serialize objects passed between processes.
 * https://www.electronjs.org/docs/latest/tutorial/ipc#object-serialization
 *
 * In particular, ArrayBuffer is eligible for structured cloning.
 * https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
 *
 * Also, ArrayBuffer is "transferable", which means it is a zero-copy operation
 * operation when it happens across threads.
 * https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects
 *
 * In our case though, we're not dealing with threads but separate processes. So
 * the ArrayBuffer will be copied:
 *
 * > "parameters, errors and return values are **copied** when they're sent over
 * > the bridge".
 * >
 * > https://www.electronjs.org/docs/latest/api/context-bridge#methods
 *
 * The copy itself is relatively fast, but the problem with transfering large
 * amounts of data is potentially running out of memory during the copy.
 *
 * For an alternative, see [Note: IPC streams].
 */
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

    // - FS

    fs: {
        exists: fsExists,
        rename: fsRename,
        mkdirIfNeeded: fsMkdirIfNeeded,
        rmdir: fsRmdir,
        rm: fsRm,
        readTextFile: fsReadTextFile,
        writeFile: fsWriteFile,
        isDir: fsIsDir,
    },

    // - Conversion

    convertToJPEG,
    generateImageThumbnail,
    ffmpegExec,

    // - ML

    clipImageEmbedding,
    clipTextEmbeddingIfAvailable,
    detectFaces,
    faceEmbedding,

    // - File selection

    selectDirectory,
    showUploadFilesDialog,
    showUploadDirsDialog,
    showUploadZipDialog,

    // - Watch

    watch: {
        get: watchGet,
        add: watchAdd,
        remove: watchRemove,
        onAddFile: watchOnAddFile,
        onRemoveFile: watchOnRemoveFile,
        onRemoveDir: watchOnRemoveDir,
        findFiles: watchFindFiles,
        updateSyncedFiles: watchUpdateSyncedFiles,
        updateIgnoredFiles: watchUpdateIgnoredFiles,
    },

    // - Upload

    pendingUploads,
    setPendingUploadCollection,
    setPendingUploadFiles,

    // -

    getElectronFilesFromGoogleZip,
    getDirFiles,
});
