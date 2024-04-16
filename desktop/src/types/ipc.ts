/**
 * @file types that are shared across the IPC boundary with the renderer process
 *
 * This file is manually kept in sync with the renderer code.
 * See [Note: types.ts <-> preload.ts <-> ipc.ts]
 */

/**
 * Errors that have special semantics on the web side.
 *
 * [Note: Custom errors across Electron/Renderer boundary]
 *
 * We need to use the `message` field to disambiguate between errors thrown by
 * the main process when invoked from the renderer process. This is because:
 *
 * > Errors thrown throw `handle` in the main process are not transparent as
 * > they are serialized and only the `message` property from the original error
 * > is provided to the renderer process.
 * >
 * > - https://www.electronjs.org/docs/latest/tutorial/ipc
 * >
 * > Ref: https://github.com/electron/electron/issues/24427
 */
export const CustomErrors = {
    WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED:
        "Windows native image processing is not supported",
    UNSUPPORTED_PLATFORM: (platform: string, arch: string) =>
        `Unsupported platform - ${platform} ${arch}`,
    MODEL_DOWNLOAD_PENDING:
        "Model download pending, skipping clip search request",
};

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
    /* eslint-disable no-unused-vars */
    FILES = "files",
    ZIPS = "zips",
}

export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}
