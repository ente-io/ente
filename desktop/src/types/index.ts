/**
 * Deprecated - Use File + webUtils.getPathForFile instead
 *
 * Electron used to augment the standard web
 * [File](https://developer.mozilla.org/en-US/docs/Web/API/File) object with an
 * additional `path` property. This is now deprecated, and will be removed in a
 * future release.
 * https://www.electronjs.org/docs/latest/api/file-object
 *
 * The alternative to the `path` property is to use `webUtils.getPathForFile`
 * https://www.electronjs.org/docs/latest/api/web-utils
 */
export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    stream: () => Promise<ReadableStream<Uint8Array>>;
    blob: () => Promise<Blob>;
    arrayBuffer: () => Promise<Uint8Array>;
}

export interface UploadStoreType {
    filePaths: string[];
    zipPaths: string[];
    collectionName: string;
}

export interface KeysStoreType {
    AnonymizeUserID: {
        id: string;
    };
}

interface WatchMappingSyncedFile {
    path: string;
    uploadedFileID: number;
    collectionID: number;
}

export interface WatchMapping {
    rootFolderName: string;
    uploadStrategy: number;
    folderPath: string;
    syncedFiles: WatchMappingSyncedFile[];
    ignoredFiles: string[];
}

export interface WatchStoreType {
    mappings: WatchMapping[];
}

export enum FILE_PATH_TYPE {
    FILES = "files",
    ZIPS = "zips",
}

export const FILE_PATH_KEYS: {
    [k in FILE_PATH_TYPE]: keyof UploadStoreType;
} = {
    [FILE_PATH_TYPE.ZIPS]: "zipPaths",
    [FILE_PATH_TYPE.FILES]: "filePaths",
};

export interface SafeStorageStoreType {
    encryptionKey: string;
}

export interface UserPreferencesType {
    hideDockIcon: boolean;
    skipAppVersion: string;
    muteUpdateNotificationVersion: string;
}

export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}

export enum Model {
    GGML_CLIP = "ggml-clip",
    ONNX_CLIP = "onnx-clip",
}
