export const EXPORT_RECORD_FILE_NAME = 'export_status.json';
export const METADATA_FOLDER_NAME = 'metadata';

export enum ExportNotification {
    START = 'export started',
    IN_PROGRESS = 'export already in progress',
    FINISH = 'export finished',
    FAILED = 'export failed',
    ABORT = 'export aborted',
    PAUSE = 'export paused',
    UP_TO_DATE = `no new files to export`,
}

export enum RecordType {
    SUCCESS = 'success',
    FAILED = 'failed',
}
export const LATEST_EXPORT_VERSION = 1;

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
export enum ExportStage {
    INIT,
    INPROGRESS,
    PAUSED,
    FINISHED,
}

export enum ExportType {
    NEW,
    PENDING,
    RETRY_FAILED,
}
