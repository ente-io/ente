import { retryPromise, runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { Collection, getLocalCollections } from './collectionService';
import downloadManager from './downloadManager';
import { File, getLocalFiles } from './fileService';

export interface ExportProgress {
    current: number;
    total: number;
}
export interface ExportStats {
    failed: number;
    success: number;
}

export interface ExportRecord {
    stage: ExportStage
    lastAttemptTimestamp: number;
    progress: ExportProgress;
    exportedFiles: string[];
    failedFiles: string[];
}
export enum ExportStage {
    INIT,
    INPROGRESS,
    PAUSED,
    FINISHED
}

enum ExportNotification {
    START = 'export started',
    IN_PROGRESS = 'export already in progress',
    FINISH = 'export finished',
    FAILED = 'export failed',
    ABORT = 'export aborted',
    PAUSE = 'export paused',
    UP_TO_DATE = `no new files to export`
}

enum RecordType {
    SUCCESS = 'success',
    FAILED = 'failed'
}
class ExportService {
    ElectronAPIs: any;

    private exportInProgress = null;
    private recordUpdateInProgress = Promise.resolve();
    private stopExport: boolean = false;
    private pauseExport: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
    }
    async selectExportDirectory() {
        return await this.ElectronAPIs.selectRootDirectory();
    }
    stopRunningExport() {
        this.stopExport = true;
    }
    pauseRunningExport() {
        this.pauseExport = true;
    }
    async exportFiles(updateProgress: (progress: ExportProgress) => void) {
        const files = await getLocalFiles();
        const collections = await getLocalCollections();
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.ElectronAPIs.showOnTray('starting export');
        const dir = getData(LS_KEYS.EXPORT)?.folder;
        if (!dir) {
            // no-export folder set
            return;
        }
        const exportRecord = await this.getExportRecord(dir);
        const exportedFiles = new Set(exportRecord?.exportedFiles);
        const failedFiles = new Set(exportRecord?.failedFiles);
        console.log(dir, exportedFiles);
        const unExportedFiles = files.filter((file) => {
            const fileUID = `${file.id}_${file.collectionID}`;
            if (!exportedFiles.has(fileUID) && !failedFiles.has(fileUID)) {
                return files;
            }
        });
        if (!unExportedFiles?.length) {
            this.ElectronAPIs.sendNotification(ExportNotification.UP_TO_DATE);
            return;
        }
        this.exportInProgress = this.fileExporter(unExportedFiles, collections, updateProgress, dir);
        return this.exportInProgress;
    }

    async retryFailedFiles(updateProgress: (progress: ExportProgress) => void) {
        const files = await getLocalFiles();
        const collections = await getLocalCollections();
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.ElectronAPIs.showOnTray('starting export');
        const dir = getData(LS_KEYS.EXPORT)?.folder;
        console.log(dir);
        if (!dir) {
            // no-export folder set
            return;
        }
        const exportRecord = await this.getExportRecord(dir);
        const failedFiles = new Set(exportRecord?.failedFiles);

        const filesToExport = files.filter((file) => {
            if (failedFiles.has(`${file.id}_${file.collectionID}`)) {
                return files;
            }
        });
        this.exportInProgress = this.fileExporter(filesToExport, collections, updateProgress, dir);
        return this.exportInProgress;
    }

    async fileExporter(files: File[], collections: Collection[], updateProgress: (progress: ExportProgress,) => void, dir: string): Promise<{ paused: boolean }> {
        try {
            this.stopExport = false;
            this.pauseExport = false;
            const failedFileCount = 0;

            this.ElectronAPIs.showOnTray({
                export_progress:
                    `0 / ${files.length} files exported`,
            });
            updateProgress({ current: 0, total: files.length });
            this.ElectronAPIs.sendNotification(ExportNotification.START);

            const collectionIDMap = new Map<number, string>();
            for (const collection of collections) {
                const collectionFolderPath = `${dir}/${collection.id}_${this.sanitizeName(collection.name)}`;
                await this.ElectronAPIs.checkExistsAndCreateCollectionDir(
                    collectionFolderPath,
                );
                collectionIDMap.set(collection.id, collectionFolderPath);
            }
            for (const [index, file] of files.entries()) {
                if (this.stopExport || this.pauseExport) {
                    if (this.pauseExport) {
                        this.ElectronAPIs.showOnTray({
                            export_progress:
                                `${index} / ${files.length} files exported (paused)`,
                            paused: true,
                        });
                    }
                    break;
                }
                const uid = `${file.id}_${this.sanitizeName(
                    file.metadata.title,
                )}`;
                const filePath = `${collectionIDMap.get(file.collectionID)}/${uid}`;
                try {
                    await this.downloadAndSave(file, filePath);
                    await this.addFileExportRecord(dir, `${file.id}_${file.collectionID}`, RecordType.SUCCESS);
                } catch (e) {
                    await this.addFileExportRecord(dir, `${file.id}_${file.collectionID}`, RecordType.FAILED);
                    logError(e, 'download and save failed for file during export');
                }
                this.ElectronAPIs.showOnTray({
                    export_progress:
                        `${index + 1} / ${files.length} files exported`,
                });
                updateProgress({ current: index + 1, total: files.length });
            }
            if (this.stopExport) {
                this.ElectronAPIs.sendNotification(
                    ExportNotification.ABORT,
                );
                this.ElectronAPIs.showOnTray();
            } else if (this.pauseExport) {
                this.ElectronAPIs.sendNotification(
                    ExportNotification.PAUSE,
                );
                return { paused: true };
            } else if (failedFileCount > 0) {
                this.ElectronAPIs.sendNotification(
                    ExportNotification.FAILED,
                );
                this.ElectronAPIs.showOnTray({
                    retry_export:
                        `export failed - retry export`,
                });
            } else {
                this.ElectronAPIs.sendNotification(
                    ExportNotification.FINISH,
                );
                this.ElectronAPIs.showOnTray();
            }
            return { paused: false };
        } catch (e) {
            logError(e);
        } finally {
            this.exportInProgress = null;
        }
    }

    async addFileExportRecord(folder: string, fileUID: string, type: RecordType) {
        const exportRecord = await this.getExportRecord(folder);
        if (type === RecordType.SUCCESS) {
            if (!exportRecord.exportedFiles) {
                exportRecord.exportedFiles = [];
            }
            exportRecord.exportedFiles.push(fileUID);
            exportRecord.failedFiles = exportRecord.failedFiles.filter((FailedFileUID) => FailedFileUID !== fileUID);
        } else {
            if (!exportRecord.failedFiles) {
                exportRecord.failedFiles = [];
            }
            if (!exportRecord.failedFiles.find((x) => x === fileUID)) {
                exportRecord.failedFiles.push(fileUID);
            }
        }
        await this.updateExportRecord(exportRecord, folder);
    }

    async updateExportRecord(newData: Record<string, any>, folder?: string) {
        await this.recordUpdateInProgress;
        this.recordUpdateInProgress = (async () => {
            try {
                if (!folder) {
                    folder = getData(LS_KEYS.EXPORT)?.folder;
                }
                const exportRecord = await this.getExportRecord(folder);
                const newRecord = { ...exportRecord, ...newData };
                console.log(newRecord, JSON.stringify(newRecord, null, 2));
                await this.ElectronAPIs.setExportRecord(folder, JSON.stringify(newRecord, null, 2));
            } catch (e) {
                console.log(e);
            }
        })();
    }

    async getExportRecord(folder?: string): Promise<ExportRecord> {
        try {
            console.log(folder);
            if (!folder) {
                folder = getData(LS_KEYS.EXPORT)?.folder;
            }
            const recordFile = await this.ElectronAPIs.getExportRecord(folder);
            if (recordFile) {
                return JSON.parse(recordFile);
            }
        } catch (e) {
            console.log(e);
        }
    }

    async downloadAndSave(file: File, path) {
        const fileStream = await retryPromise(downloadManager.downloadFile(file));
        this.ElectronAPIs.saveStreamToDisk(path, fileStream);
        this.ElectronAPIs.saveFileToDisk(
            `${path}.json`,
            JSON.stringify(file.metadata, null, 2),
        );
    }

    private sanitizeName(name) {
        return name.replaceAll('/', '_').replaceAll(' ', '_');
    }

    isExportInProgress = () => {
        return this.exportInProgress !== null;
    }
}
export default new ExportService();
