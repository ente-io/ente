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
 * - [renderer]  web/packages/base/types/ipc.ts      contains docs
 * - [preload]   desktop/src/preload.ts                    ↕︎
 * - [main]      desktop/src/main/ipc.ts             contains impl
 */

// This code runs in the (isolated) web layer. Contrary to the impression given
// by the Electron docs (as of 2024), the window object is actually available to
// the preload script, and it is necessary for legitimate uses too.
//
// > The isolated world is connected to the DOM just the same is the main world,
// > it is just the JS contexts that are separated.
// >
// > https://github.com/electron/electron/issues/27024#issuecomment-745618327
//
// Adding this reference here tells TypeScript that DOM typings (in particular,
// window) should be introduced in the ambient scope.
//
// [Note: Node and web stream type mismatch]
//
// Unfortunately, adding this reference causes the ReadableStream typings to
// break since lib.dom.d.ts adds its own incompatible definitions of
// ReadableStream to the global scope.
//
// https://github.com/DefinitelyTyped/DefinitelyTyped/discussions/68407

/// <reference lib="dom" />

import { contextBridge, ipcRenderer, webUtils } from "electron/renderer";

// While we can't import other code, we can import types since they're just
// needed when compiling and will not be needed or looked around for at runtime.
import type { IpcRendererEvent } from "electron";
import type {
    AppUpdate,
    CollectionMapping,
    FolderWatch,
    PendingUploads,
    ZipItem,
} from "./types/ipc";

// - Infrastructure

// We need to wait until the renderer is ready before sending ports via
// postMessage, and this promise comes handy in such cases. We create the
// promise at the top level so that it is guaranteed to be registered before the
// load event is fired.
//
// See: https://www.electronjs.org/docs/latest/tutorial/message-ports

const windowLoaded = new Promise((resolve) => {
    window.onload = resolve;
});

// - General

const appVersion = () => ipcRenderer.invoke("appVersion");

const logToDisk = (message: string): void =>
    ipcRenderer.send("logToDisk", message);

const openDirectory = (dirPath: string) =>
    ipcRenderer.invoke("openDirectory", dirPath);

const openLogDirectory = () => ipcRenderer.invoke("openLogDirectory");

const selectDirectory = () => ipcRenderer.invoke("selectDirectory");

// The path that we get back from `webUtils.getPathForFile` on Windows uses "\"
// as the path separator. Convert them to POSIX separators.

const pathForFile =
    process.platform == "win32"
        ? (file: File) => webUtils.getPathForFile(file).replace(/\\/g, "/")
        : (file: File) => webUtils.getPathForFile(file);

const logout = () => {
    watchRemoveListeners();
    return ipcRenderer.invoke("logout");
};

const masterKeyB64 = () => ipcRenderer.invoke("masterKeyB64");

const saveMasterKeyB64 = (masterKeyB64: string) =>
    ipcRenderer.invoke("saveMasterKeyB64", masterKeyB64);

const lastShownChangelogVersion = () =>
    ipcRenderer.invoke("lastShownChangelogVersion");

const setLastShownChangelogVersion = (version: number) =>
    ipcRenderer.invoke("setLastShownChangelogVersion", version);

const onMainWindowFocus = (cb: (() => void) | undefined) => {
    ipcRenderer.removeAllListeners("mainWindowFocus");
    if (cb) ipcRenderer.on("mainWindowFocus", cb);
};

const onOpenURL = (cb: ((url: string) => void) | undefined) => {
    ipcRenderer.removeAllListeners("openURL");
    if (cb) ipcRenderer.on("openURL", (_, url: string) => cb(url));
};

// - App update

const onAppUpdateAvailable = (
    cb: ((update: AppUpdate) => void) | undefined,
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

const fsExists = (path: string) => ipcRenderer.invoke("fsExists", path);

const fsMkdirIfNeeded = (dirPath: string) =>
    ipcRenderer.invoke("fsMkdirIfNeeded", dirPath);

const fsRename = (oldPath: string, newPath: string) =>
    ipcRenderer.invoke("fsRename", oldPath, newPath);

const fsRmdir = (path: string) => ipcRenderer.invoke("fsRmdir", path);

const fsRm = (path: string) => ipcRenderer.invoke("fsRm", path);

const fsReadTextFile = (path: string) =>
    ipcRenderer.invoke("fsReadTextFile", path);

const fsWriteFile = (path: string, contents: string) =>
    ipcRenderer.invoke("fsWriteFile", path, contents);

const fsIsDir = (dirPath: string) => ipcRenderer.invoke("fsIsDir", dirPath);

// - Conversion

const convertToJPEG = (imageData: Uint8Array) =>
    ipcRenderer.invoke("convertToJPEG", imageData);

const generateImageThumbnail = (
    dataOrPathOrZipItem: Uint8Array | string | ZipItem,
    maxDimension: number,
    maxSize: number,
) =>
    ipcRenderer.invoke(
        "generateImageThumbnail",
        dataOrPathOrZipItem,
        maxDimension,
        maxSize,
    );

const ffmpegExec = (
    command: string[],
    dataOrPathOrZipItem: Uint8Array | string | ZipItem,
    outputFileExtension: string,
) =>
    ipcRenderer.invoke(
        "ffmpegExec",
        command,
        dataOrPathOrZipItem,
        outputFileExtension,
    );

// - ML

const createMLWorker = () => {
    const l = (event: IpcRendererEvent) => {
        void windowLoaded.then(() => {
            // "*"" is the origin to send to.
            window.postMessage("createMLWorker/port", "*", event.ports);
            ipcRenderer.off("createMLWorker/port", l);
        });
    };
    ipcRenderer.on("createMLWorker/port", l);
    ipcRenderer.send("createMLWorker");
};

// - Watch

const watchGet = () => ipcRenderer.invoke("watchGet");

const watchAdd = (folderPath: string, collectionMapping: CollectionMapping) =>
    ipcRenderer.invoke("watchAdd", folderPath, collectionMapping);

const watchRemove = (folderPath: string) =>
    ipcRenderer.invoke("watchRemove", folderPath);

const watchUpdateSyncedFiles = (
    syncedFiles: FolderWatch["syncedFiles"],
    folderPath: string,
) => ipcRenderer.invoke("watchUpdateSyncedFiles", syncedFiles, folderPath);

const watchUpdateIgnoredFiles = (
    ignoredFiles: FolderWatch["ignoredFiles"],
    folderPath: string,
) => ipcRenderer.invoke("watchUpdateIgnoredFiles", ignoredFiles, folderPath);

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

const fsFindFiles = (folderPath: string) =>
    ipcRenderer.invoke("fsFindFiles", folderPath);

const watchRemoveListeners = () => {
    ipcRenderer.removeAllListeners("watchAddFile");
    ipcRenderer.removeAllListeners("watchRemoveFile");
    ipcRenderer.removeAllListeners("watchRemoveDir");
};

// - Upload

const listZipItems = (zipPath: string) =>
    ipcRenderer.invoke("listZipItems", zipPath);

const pathOrZipItemSize = (pathOrZipItem: string | ZipItem) =>
    ipcRenderer.invoke("pathOrZipItemSize", pathOrZipItem);

const pendingUploads = () => ipcRenderer.invoke("pendingUploads");

const setPendingUploads = (pendingUploads: PendingUploads) =>
    ipcRenderer.invoke("setPendingUploads", pendingUploads);

const markUploadedFiles = (paths: PendingUploads["filePaths"]) =>
    ipcRenderer.invoke("markUploadedFiles", paths);

const markUploadedZipItems = (items: PendingUploads["zipItems"]) =>
    ipcRenderer.invoke("markUploadedZipItems", items);

const clearPendingUploads = () => ipcRenderer.invoke("clearPendingUploads");

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
 * In our case though, we're not dealing with threads but separate processes.
 * Electron currently only supports transferring MessagePorts:
 * https://github.com/electron/electron/issues/34905
 *
 * So the ArrayBuffer will be copied:
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
    selectDirectory,
    pathForFile,
    logout,
    masterKeyB64,
    saveMasterKeyB64,
    lastShownChangelogVersion,
    setLastShownChangelogVersion,
    onMainWindowFocus,
    onOpenURL,

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
        findFiles: fsFindFiles,
    },

    // - Conversion

    convertToJPEG,
    generateImageThumbnail,
    ffmpegExec,

    // - ML

    createMLWorker,

    // - Watch

    watch: {
        get: watchGet,
        add: watchAdd,
        remove: watchRemove,
        updateSyncedFiles: watchUpdateSyncedFiles,
        updateIgnoredFiles: watchUpdateIgnoredFiles,
        onAddFile: watchOnAddFile,
        onRemoveFile: watchOnRemoveFile,
        onRemoveDir: watchOnRemoveDir,
    },

    // - Upload

    listZipItems,
    pathOrZipItemSize,
    pendingUploads,
    setPendingUploads,
    markUploadedFiles,
    markUploadedZipItems,
    clearPendingUploads,
});
