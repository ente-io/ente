/**
 * @file types that are shared across the IPC boundary with the renderer process
 *
 * This file is manually kept in sync with the renderer code.
 * See [Note: types.ts <-> preload.ts <-> ipc.ts]
 */

export interface AppUpdate {
    autoUpdatable: boolean;
    version: string;
}

export interface FolderWatch {
    collectionMapping: CollectionMapping;
    folderPath: string;
    syncedFiles: FolderWatchSyncedFile[];
    ignoredFiles: string[];
}

export type CollectionMapping = "root" | "parent";

export interface FolderWatchSyncedFile {
    path: string;
    uploadedFileID: number;
    collectionID: number;
}

export interface PendingUploads {
    collectionName: string;
    type: "files" | "zips";
    files: ElectronFile[];
}

/**
 * Errors that have special semantics on the web side.
 */
export const CustomErrors = {
    WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED:
        "Windows native image processing is not supported",
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
