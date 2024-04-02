/**
 * @file types that are shared across the IPC boundary with the renderer process
 *
 * This file is manually kept in sync with the renderer code.
 * See [Note: types.ts <-> preload.ts <-> ipc.ts]
 */
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

export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}

export enum Model {
    GGML_CLIP = "ggml-clip",
    ONNX_CLIP = "onnx-clip",
}
