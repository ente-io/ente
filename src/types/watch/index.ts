export interface WatchMapping {
    collectionName: string;
    folderPath: string;
    files: {
        path: string;
        id: number;
    }[];
}

export interface EventQueueType {
    type: 'upload' | 'trash';
    collectionName: string;
    paths: string[];
}
