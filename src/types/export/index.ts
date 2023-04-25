import { ExportStage } from 'constants/export';

export interface ExportProgress {
    success: number;
    failed: number;
    total: number;
}
export interface ExportedCollectionPaths {
    [ID: number]: string;
}

export interface ExportedFilePaths {
    [ID: string]: string;
}
export interface FileExportStats {
    totalCount: number;
    pendingCount: number;
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

export interface ExportRecordV2 {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    exportedFiles: string[];
    exportedCollectionPaths: ExportedCollectionPaths;
}

export interface ExportRecord {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    exportedCollectionPaths: ExportedCollectionPaths;
    exportedFilePaths: ExportedFilePaths;
}

export interface ExportSettings {
    folder: string;
    continuousExport: boolean;
}

export interface ExportUIUpdaters {
    updateExportStage: (stage: ExportStage) => Promise<void>;
    updateExportProgress: (progress: ExportProgress) => void;
    updateFileExportStats: (fileExportStats: FileExportStats) => void;
    updateLastExportTime: (exportTime: number) => Promise<void>;
}
