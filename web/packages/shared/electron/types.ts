// Following are types shared with the Electron process. This list is manually
// kept in sync with `desktop/src/types/ipc.ts`.
//
// See [Note: types.ts <-> preload.ts <-> ipc.ts]

import type { ElectronFile } from "@ente/shared/upload/types";
import type { WatchMapping } from "@ente/shared/watchFolder/types";

export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}

export enum Model {
    GGML_CLIP = "ggml-clip",
    ONNX_CLIP = "onnx-clip",
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
 * Extra APIs provided by the Node.js layer when our code is running in Electron
 *
 * This list is manually kept in sync with `desktop/src/preload.ts`. In case of
 * a mismatch, the types may lie. See also: [Note: types.ts <-> preload.ts <->
 * ipc.ts]
 *
 * These extra objects and functions will only be available when our code is
 * running as the renderer process in Electron. So something in the code path
 * should check for `isElectron() == true` before invoking these.
 */
export interface ElectronAPIsType {
    // - General

    /** Return the version of the desktop app. */
    appVersion: () => Promise<string>;

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
     * Log the given {@link message} to the on-disk log file maintained by the
     * desktop app.
     *
     * Note: Unlike the other functions exposed over the Electron bridge,
     * logToDisk is fire-and-forget and does not return a promise.
     */
    logToDisk: (message: string) => void;

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
     * functions that are needed for such features. In addition, there are other
     * feature specific methods too in the top level electron object.
     */
    fs: {
        /**
         * Return true if there is a file or directory at the given
         * {@link path}.
         */
        exists: (path: string) => Promise<boolean>;
    };

    /*
     * TODO: AUDIT below this - Some of the types we use below are not copyable
     * across process boundaries, and such functions will (expectedly) fail at
     * runtime. For such functions, find an efficient alternative or refactor
     * the dataflow.
     */

    // - General

    registerForegroundEventListener: (onForeground: () => void) => void;

    clearElectronStore: () => void;

    setEncryptionKey: (encryptionKey: string) => Promise<void>;

    getEncryptionKey: () => Promise<string>;

    // - App update

    updateAndRestart: () => void;

    skipAppUpdate: (version: string) => void;

    muteUpdateNotification: (version: string) => void;

    registerUpdateEventListener: (
        showUpdateDialog: (updateInfo: AppUpdateInfo) => void,
    ) => void;

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

    computeImageEmbedding: (
        model: Model,
        imageData: Uint8Array,
    ) => Promise<Float32Array>;

    computeTextEmbedding: (model: Model, text: string) => Promise<Float32Array>;

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
    checkExistsAndCreateDir: (dirPath: string) => Promise<void>;
    saveStreamToDisk: (
        path: string,
        fileStream: ReadableStream<any>,
    ) => Promise<void>;
    saveFileToDisk: (path: string, file: any) => Promise<void>;
    readTextFile: (path: string) => Promise<string>;
    isFolder: (dirPath: string) => Promise<boolean>;
    moveFile: (oldPath: string, newPath: string) => Promise<void>;
    deleteFolder: (path: string) => Promise<void>;
    deleteFile: (path: string) => Promise<void>;
    rename: (oldPath: string, newPath: string) => Promise<void>;

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
