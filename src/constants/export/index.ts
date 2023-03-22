export const ENTE_METADATA_FOLDER = 'metadata';

export enum ExportNotification {
    START = 'Export started',
    IN_PROGRESS = 'Export already in progress',
    FINISH = 'Export finished',
    FAILED = 'Export failed',
    ABORT = 'Export aborted',
    PAUSE = 'Export paused',
    UP_TO_DATE = `No new files to export`,
}

export enum RecordType {
    SUCCESS = 'success',
    FAILED = 'failed',
}
export enum ExportStage {
    INIT = 0,
    INPROGRESS = 1,
    FINISHED = 3,
}
