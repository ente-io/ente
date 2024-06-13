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

import { contextBridge, ipcRenderer, webUtils } from "electron/renderer";

// While we can't import other code, we can import types since they're just
// needed when compiling and will not be needed or looked around for at runtime.
import type {
    AppUpdate,
    CollectionMapping,
    FolderWatch,
    PendingUploads,
    ZipItem,
} from "./types/ipc";

// - General

const appVersion = () => ipcRenderer.invoke("appVersion");

const logToDisk = (message: string): void =>
    ipcRenderer.send("logToDisk", message);

const openDirectory = (dirPath: string) =>
    ipcRenderer.invoke("openDirectory", dirPath);

const openLogDirectory = () => ipcRenderer.invoke("openLogDirectory");

const selectDirectory = () => ipcRenderer.invoke("selectDirectory");

const logout = () => {
    watchRemoveListeners();
    return ipcRenderer.invoke("logout");
};

const encryptionKey = () => ipcRenderer.invoke("encryptionKey");

const saveEncryptionKey = (encryptionKey: string) =>
    ipcRenderer.invoke("saveEncryptionKey", encryptionKey);

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

const computeCLIPImageEmbedding = (jpegImageData: Uint8Array) =>
    ipcRenderer.invoke("computeCLIPImageEmbedding", jpegImageData);

const computeCLIPTextEmbeddingIfAvailable = (text: string) =>
    ipcRenderer.invoke("computeCLIPTextEmbeddingIfAvailable", text);

const detectFaces = (input: Float32Array) =>
    ipcRenderer.invoke("detectFaces", input);

const computeFaceEmbeddings = (input: Float32Array) =>
    ipcRenderer.invoke("computeFaceEmbeddings", input);

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

const watchFindFiles = (folderPath: string) =>
    ipcRenderer.invoke("watchFindFiles", folderPath);

const watchRemoveListeners = () => {
    ipcRenderer.removeAllListeners("watchAddFile");
    ipcRenderer.removeAllListeners("watchRemoveFile");
    ipcRenderer.removeAllListeners("watchRemoveDir");
};

// - Upload

const pathForFile = (file: File) => {
    const path = webUtils.getPathForFile(file);
    // The path that we get back from `webUtils.getPathForFile` on Windows uses
    // "/" as the path separator. Convert them to POSIX separators.
    //
    // Note that we do not have access to the path or the os module in the
    // preload script, thus this hand rolled transformation.

    // However that makes TypeScript fidgety since we it cannot find navigator,
    // as we haven't included "lib": ["dom"] in our tsconfig to avoid making DOM
    // APIs available to our main Node.js code. We could create a separate
    // tsconfig just for the preload script, but for now let's go with a cast.
    //
    // @ts-expect-error navigator is not defined.
    const platform = (navigator as { platform: string }).platform;
    return platform.toLowerCase().includes("win")
        ? path.split("\\").join("/")
        : path;
};

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
    selectDirectory,
    logout,
    encryptionKey,
    saveEncryptionKey,
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
    },

    // - Conversion

    convertToJPEG,
    generateImageThumbnail,
    ffmpegExec,

    // - ML

    computeCLIPImageEmbedding,
    computeCLIPTextEmbeddingIfAvailable,
    detectFaces,
    computeFaceEmbeddings,

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
        findFiles: watchFindFiles,
    },

    // - Upload

    pathForFile,
    listZipItems,
    pathOrZipItemSize,
    pendingUploads,
    setPendingUploads,
    markUploadedFiles,
    markUploadedZipItems,
    clearPendingUploads,
});
