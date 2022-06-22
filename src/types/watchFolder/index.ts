import { ElectronFile } from 'types/upload';

export interface WatchMapping {
    collectionName: string;
    folderPath: string;
    hasMultipleFolders: boolean;
    files: {
        path: string;
        id: number;
    }[];
}

export interface EventQueueItem {
    type: 'upload' | 'trash';
    folderPath: string;
    collectionName?: string;
    paths?: string[];
    files?: ElectronFile[];
}
