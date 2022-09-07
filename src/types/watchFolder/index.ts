import { UPLOAD_STRATEGY } from 'constants/upload';
import { ElectronFile } from 'types/upload';

interface WatchMappingSyncedFile {
    path: string;
    id: number;
}

export interface WatchMapping {
    rootFolderName: string;
    folderPath: string;
    uploadStrategy: UPLOAD_STRATEGY;
    syncedFiles: WatchMappingSyncedFile[];
    ignoredFiles: string[];
}

export interface EventQueueItem {
    type: 'upload' | 'trash';
    folderPath: string;
    collectionName?: string;
    paths?: string[];
    files?: ElectronFile[];
}
