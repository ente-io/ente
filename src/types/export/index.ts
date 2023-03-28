import { ExportStage } from 'constants/export';

export type CollectionIDNameMap = Map<number, string>;
export type CollectionIDPathMap = Map<number, string>;
export interface ExportProgress {
    current: number;
    total: number;
}
export interface ExportedCollectionPaths {
    [collectionID: number]: string;
}

export interface ExportRecordV1 {
    version?: number;
    stage?: ExportStage;
    lastAttemptTimestamp?: number;
    progress?: ExportProgress;
    queuedFiles?: string[];
    exportedFiles?: string[];
    failedFiles?: string[];
    exportedCollectionPaths?: ExportedCollectionPaths;
}

export interface ExportRecord {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    exportedFiles: string[];
    exportedCollectionPaths: ExportedCollectionPaths;
}

export interface ExportSettings {
    folder: string;
    continuousExport: boolean;
}
