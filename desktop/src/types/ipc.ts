/**
 * @file types that are shared across the IPC boundary with the renderer process
 *
 * This file is manually kept in sync with the renderer code.
 * See [Note: types.ts <-> preload.ts <-> ipc.ts]
 */

export type UtilityProcessType = "ml";

export interface AppUpdate {
    autoUpdatable: boolean;
    version: string;
}

export interface FolderWatch {
    collectionMapping: CollectionMapping;
    folderPath: string;
    syncedFiles: FolderWatchSyncedFile[];
    ignoredFiles: string[];
    /**
     * `true` if the folder path is currently accessible on disk.
     *
     * This will be `false` for folders on external drives that are currently
     * disconnected. The watch is preserved, and syncing will resume
     * automatically when the folder becomes accessible again.
     */
    isAvailable: boolean;
}

export type CollectionMapping = "root" | "parent";

export interface FolderWatchSyncedFile {
    path: string;
    uploadedFileID: number;
    collectionID: number;
}

export type ZipItem = [zipPath: string, entryName: string];

export interface PendingUploads {
    collectionName: string | undefined;
    filePaths: string[];
    zipItems: ZipItem[];
}

export type FFmpegCommand = string[] | { default: string[]; hdr: string[] };
