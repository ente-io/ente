import { UPLOAD_STRATEGY } from "@ente/shared/upload/constants";
import { ElectronFile } from "@ente/shared/upload/types";

export interface WatchMappingSyncedFile {
    path: string;
    uploadedFileID: number;
    collectionID: number;
}

export interface WatchMapping {
    rootFolderName: string;
    folderPath: string;
    uploadStrategy: UPLOAD_STRATEGY;
    syncedFiles: WatchMappingSyncedFile[];
    ignoredFiles: string[];
}

export interface EventQueueItem {
    type: "upload" | "trash";
    folderPath: string;
    collectionName?: string;
    paths?: string[];
    files?: ElectronFile[];
}
