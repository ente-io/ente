// Following are types shared with the Electron process. This list is manually
// kept in sync with `desktop/src/types/ipc.ts`.
//
// See [Note: types.ts <-> preload.ts <-> ipc.ts]

import type { ElectronFile, WatchMapping } from "./file";

export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}

export enum FILE_PATH_TYPE {
    FILES = "files",
    ZIPS = "zips",
}

export enum PICKED_UPLOAD_TYPE {
    FILES = "files",
    FOLDERS = "folders",
    ZIPS = "zips",
}

/**
 * Extra APIs provided by our Node.js layer when our code is running inside our
 * desktop (Electron) app.
 *
 * This list is manually kept in sync with `desktop/src/preload.ts`. In case of
 * a mismatch, the types may lie. See also: [Note: types.ts <-> preload.ts <->
 * ipc.ts]
 *
 * These extra objects and functions will only be available when our code is
 * running as the renderer process in Electron. These can be accessed by using
 * the `electron` property of the window (See @{link globalElectron} for a
 * systematic way of getting at that).
 */
export interface Electron {
    // - General

    /**
     * Return the version of the desktop app.
     *
     * The return value is of the form `v1.2.3`.
     */
    appVersion: () => Promise<string>;

    /**
     * Log the given {@link message} to the on-disk log file maintained by the
     * desktop app.
     *
     * Note: Unlike the other functions exposed over the Electron bridge,
     * logToDisk is fire-and-forget and does not return a promise.
     */
    logToDisk: (message: string) => void;

    /**
     * Open the given {@link dirPath} in the system's folder viewer.
     *
     * For example, on macOS this'll open {@link dirPath} in Finder.
     */
    openDirectory: (dirPath: string) => Promise<void>;

    /**
     * Open the app's log directory in the system's folder viewer.
     *
     * @see {@link openDirectory}
     */
    openLogDirectory: () => Promise<void>;

    /**
     * Clear any stored data.
     *
     * This is a coarse single shot cleanup, meant for use in clearing any
     * Electron side state during logout.
     */
    clearStores: () => void;

    /**
     * Return the previously saved encryption key from persistent safe storage.
     *
     * If no such key is found, return `undefined`.
     *
     * See also: {@link saveEncryptionKey}.
     */
    encryptionKey: () => Promise<string | undefined>;

    /**
     * Save the given {@link encryptionKey} into persistent safe storage.
     */
    saveEncryptionKey: (encryptionKey: string) => Promise<void>;

    /**
     * Set or clear the callback {@link cb} to invoke whenever the app comes
     * into the foreground. More precisely, the callback gets invoked when the
     * main window gets focus.
     *
     * Note: Setting a callback clears any previous callbacks.
     *
     * @param cb The function to call when the main window gets focus. Pass
     * `undefined` to clear the callback.
     */
    onMainWindowFocus: (cb?: () => void) => void;

    // - App update

    /**
     * Set or clear the callback {@link cb} to invoke whenever a new
     * (actionable) app update is available. This allows the Node.js layer to
     * ask the renderer to show an "Update available" dialog to the user.
     *
     * Note: Setting a callback clears any previous callbacks.
     */
    onAppUpdateAvailable: (
        cb?: ((updateInfo: AppUpdateInfo) => void) | undefined,
    ) => void;

    /**
     * Restart the app to apply the latest available update.
     *
     * This is expected to be called in response to {@link onAppUpdateAvailable}
     * if the user so wishes.
     */
    updateAndRestart: () => void;

    /**
     * Mute update notifications for the given {@link version}. This allows us
     * to implement the "Install on next launch" functionality in response to
     * the {@link onAppUpdateAvailable} event.
     */
    updateOnNextRestart: (version: string) => void;

    /**
     * Skip the app update with the given {@link version}.
     *
     * This is expected to be called in response to {@link onAppUpdateAvailable}
     * if the user so wishes. It will remember this {@link version} as having
     * been marked as skipped so that we don't prompt the user again.
     */
    skipAppUpdate: (version: string) => void;

    /**
     * A subset of filesystem access APIs.
     *
     * The renderer process, being a web process, does not have full access to
     * the local filesystem apart from files explicitly dragged and dropped (or
     * selected by the user in a native file open dialog).
     *
     * The main process, however, has full filesystem access (limited only be an
     * OS level sandbox on the entire process).
     *
     * When we're running in the desktop app, we want to better utilize the
     * local filesystem access to provide more integrated features to the user -
     * things that are not currently possible using web technologies. For
     * example, continuous exports to an arbitrary user chosen location on disk,
     * or watching some folders for changes and syncing them automatically.
     *
     * Towards this end, this fs object provides some generic file system access
     * functions that are needed for such features (in some cases, there are
     * other feature specific methods too in the top level electron object).
     */
    fs: {
        /** Return true if there is an item at the given {@link path}. */
        exists: (path: string) => Promise<boolean>;

        /**
         * Equivalent of `mkdir -p`.
         *
         * Create a directory at the given path if it does not already exist.
         * Any parent directories in the path that don't already exist will also
         * be created recursively, i.e. this command is analogous to an running
         * `mkdir -p`.
         */
        mkdirIfNeeded: (dirPath: string) => Promise<void>;

        /** Rename {@link oldPath} to {@link newPath} */
        rename: (oldPath: string, newPath: string) => Promise<void>;

        /**
         * Equivalent of `rmdir`.
         *
         * Delete the directory at the {@link path} if it is empty.
         */
        rmdir: (path: string) => Promise<void>;

        /**
         * Equivalent of `rm`.
         *
         * Delete the file at {@link path}.
         */
        rm: (path: string) => Promise<void>;
    };

    /*
     * TODO: AUDIT below this - Some of the types we use below are not copyable
     * across process boundaries, and such functions will (expectedly) fail at
     * runtime. For such functions, find an efficient alternative or refactor
     * the dataflow.
     */

    // - Conversion

    convertToJPEG: (
        fileData: Uint8Array,
        filename: string,
    ) => Promise<Uint8Array>;

    generateImageThumbnail: (
        inputFile: File | ElectronFile,
        maxDimension: number,
        maxSize: number,
    ) => Promise<Uint8Array>;

    runFFmpegCmd: (
        cmd: string[],
        inputFile: File | ElectronFile,
        outputFileName: string,
        dontTimeout?: boolean,
    ) => Promise<File>;

    // - ML

    /**
     * Return a CLIP embedding of the given image.
     *
     * See: [Note: CLIP based magic search]
     *
     * @param jpegImageData The raw bytes of the image encoded as an JPEG.
     *
     * @returns A CLIP embedding.
     */
    clipImageEmbedding: (jpegImageData: Uint8Array) => Promise<Float32Array>;

    /**
     * Return a CLIP embedding of the given image.
     *
     * See: [Note: CLIP based magic search]
     *
     * @param text The string whose embedding we want to compute.
     *
     * @returns A CLIP embedding.
     */
    clipTextEmbedding: (text: string) => Promise<Float32Array>;

    /**
     * Detect faces in the given image using YOLO.
     *
     * Both the input and output are opaque binary data whose internal structure
     * is specific to our implementation and the model (YOLO) we use.
     */
    detectFaces: (input: Float32Array) => Promise<Float32Array>;

    /**
     * Return a MobileFaceNet embedding for the given face data.
     *
     * Both the input and output are opaque binary data whose internal structure
     * is specific to our implementation and the model (MobileFaceNet) we use.
     */
    faceEmbedding: (input: Float32Array) => Promise<Float32Array>;

    // - File selection
    // TODO: Deprecated - use dialogs on the renderer process itself

    selectDirectory: () => Promise<string>;

    showUploadFilesDialog: () => Promise<ElectronFile[]>;

    showUploadDirsDialog: () => Promise<ElectronFile[]>;

    showUploadZipDialog: () => Promise<{
        zipPaths: string[];
        files: ElectronFile[];
    }>;

    // - Watch

    registerWatcherFunctions: (
        addFile: (file: ElectronFile) => Promise<void>,
        removeFile: (path: string) => Promise<void>,
        removeFolder: (folderPath: string) => Promise<void>,
    ) => void;

    addWatchMapping: (
        collectionName: string,
        folderPath: string,
        uploadStrategy: number,
    ) => Promise<void>;

    removeWatchMapping: (folderPath: string) => Promise<void>;

    getWatchMappings: () => Promise<WatchMapping[]>;

    updateWatchMappingSyncedFiles: (
        folderPath: string,
        files: WatchMapping["syncedFiles"],
    ) => Promise<void>;

    updateWatchMappingIgnoredFiles: (
        folderPath: string,
        files: WatchMapping["ignoredFiles"],
    ) => Promise<void>;

    // - FS legacy
    saveStreamToDisk: (
        path: string,
        fileStream: ReadableStream,
    ) => Promise<void>;
    saveFileToDisk: (path: string, contents: string) => Promise<void>;
    readTextFile: (path: string) => Promise<string>;
    isFolder: (dirPath: string) => Promise<boolean>;

    // - Upload

    getPendingUploads: () => Promise<{
        files: ElectronFile[];
        collectionName: string;
        type: string;
    }>;
    setToUploadFiles: (
        /** TODO(MR): This is the actual type */
        // type: FILE_PATH_TYPE,
        type: PICKED_UPLOAD_TYPE,
        filePaths: string[],
    ) => Promise<void>;
    getElectronFilesFromGoogleZip: (
        filePath: string,
    ) => Promise<ElectronFile[]>;
    setToUploadCollection: (collectionName: string) => Promise<void>;
    getDirFiles: (dirPath: string) => Promise<ElectronFile[]>;
}
