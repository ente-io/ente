import { ExportStage } from 'constants/export';

export type CollectionIDPathMap = Map<number, string>;
export interface ExportProgress {
    current: number;
    total: number;
}
export interface ExportedCollectionPaths {
    [collectionID: number]: string;
}
export interface ExportStats {
    failed: number;
    success: number;
}

export interface ExportRecord {
    version?: number;
    stage?: ExportStage;
    lastAttemptTimestamp?: number;
    progress?: ExportProgress;
    queuedFiles?: string[];
    exportedFiles?: string[];
    failedFiles?: string[];
    exportedCollectionPaths?: ExportedCollectionPaths;
}
