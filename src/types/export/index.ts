import { ExportStage } from 'constants/export';

export interface ExportProgress {
    success: number;
    failed: number;
    total: number;
}
export interface ExportedEntityPaths {
    [ID: number]: string;
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
    exportedCollectionPaths?: ExportedEntityPaths;
}

export interface ExportRecord {
    version: number;
    stage: ExportStage;
    lastAttemptTimestamp: number;
    exportedFiles: string[];
    exportedCollectionPaths: ExportedEntityPaths;
    exportedFilePaths: ExportedEntityPaths;
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
