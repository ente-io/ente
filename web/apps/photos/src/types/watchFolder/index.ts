import { UPLOAD_STRATEGY } from "constants/upload";
import { ElectronFile } from "types/upload";

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
