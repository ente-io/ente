export interface IndexStatus {
    outOfSyncFilesExists: boolean;
    nSyncedFiles: number;
    nTotalFiles: number;
    localFilesSynced: boolean;
    peopleIndexSynced: boolean;
}
