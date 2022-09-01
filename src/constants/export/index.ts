export const ENTE_METADATA_FOLDER = 'metadata';

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
