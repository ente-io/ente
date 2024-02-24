export const ENTE_METADATA_FOLDER = "metadata";

export const ENTE_TRASH_FOLDER = "Trash";

export enum ExportStage {
    INIT = 0,
    MIGRATION = 1,
    STARTING = 2,
    EXPORTING_FILES = 3,
    TRASHING_DELETED_FILES = 4,
    RENAMING_COLLECTION_FOLDERS = 5,
    TRASHING_DELETED_COLLECTIONS = 6,
    FINISHED = 7,
}
