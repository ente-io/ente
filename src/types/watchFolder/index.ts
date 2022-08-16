import { UPLOAD_STRATEGY } from 'constants/upload';
import { ElectronFile } from 'types/upload';

export interface WatchMapping {
    rootFolderName: string;
    folderPath: string;
    uploadStrategy: UPLOAD_STRATEGY;
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
