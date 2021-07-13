import { retryPromise, runningInBrowser, sleep } from 'utils/common';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { Collection, getLocalCollections } from './collectionService';
import downloadManager from './downloadManager';
import { File, getLocalFiles } from './fileService';

export interface ExportStats {
    current: number;
    total: number;
    failed: number;
    success?: number;
}

export interface ExportRecord {
    stage: ExportStage
    time: number;
    stats: ExportStats;
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
}

enum RecordType {
    SUCCESS = 'success',
    FAILED = 'failed'
}
class ExportService {
    ElectronAPIs: any;

    private exportInProgress: Promise<void> = null;
    private recordUpdateInProgress: Promise<void> = null;
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
    async exportFiles(updateProgress: (stats: ExportStats) => void) {
        const files = await getLocalFiles();
        const collections = await getLocalCollections();
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.ElectronAPIs.showOnTray('starting export');
        const dir = getData(LS_KEYS.EXPORT_FOLDER);
        if (!dir) {
            // no-export folder set
            return;
        }
        const exportRecord = await this.getExportRecord(dir);
        const exportedFiles = new Set(exportRecord?.exportedFiles);
        console.log(dir, exportedFiles);
        const unExportedFiles = files.filter((file) => {
            if (!exportedFiles.has(`${file.id}_${file.collectionID}`)) {
                return files;
            }
        });
        this.exportInProgress = this.fileExporter(unExportedFiles, collections, updateProgress, dir);
        return this.exportInProgress;
    }

    async retryFailedFiles(updateProgress: (stats: ExportStats) => void) {
        const files = await getLocalFiles();
        const collections = await getLocalCollections();
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.ElectronAPIs.showOnTray('starting export');
        const dir = getData(LS_KEYS.EXPORT_FOLDER);
        console.log(dir);
        if (!dir) {
            // no-export folder set
            return;
        }

        const failedFilesIds = new Set((await this.getExportRecord()).failedFiles ?? []);
        const failedFiles = files.filter((file) => {
            if (failedFilesIds.has(`${file.id}_${file.collectionID}`)) {
                return files;
            }
        });
        this.exportInProgress = this.fileExporter(failedFiles, collections, updateProgress, dir);
        return this.exportInProgress;
    }

    async fileExporter(files: File[], collections: Collection[], updateProgress: (stats: ExportStats,) => void, dir: string) {
        try {
            this.stopExport = false;
            this.pauseExport = false;
            let failedFileCount = 0;

            this.ElectronAPIs.showOnTray({
                export_progress:
                    `0 / ${files.length} files exported`,
            });
            updateProgress({ current: 0, total: files.length, failed: 0 });
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
                    failedFileCount++;
                    await this.addFileExportRecord(dir, `${file.id}_${file.collectionID}`, RecordType.FAILED);
                    logError(e, 'download and save failed for file during export');
                }
                this.ElectronAPIs.showOnTray({
                    export_progress:
                        `${index + 1} / ${files.length} files exported`,
                });
                updateProgress({ current: index + 1, total: files.length, failed: failedFileCount });
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
        } catch (e) {
            logError(e);
        } finally {
            this.exportInProgress = null;
        }
    }

    async addFileExportRecord(folder: string, fileUID: string, type: RecordType) {
        const exportRecord = await this.ElectronAPIs.getExportRecord(folder);
        if (type === RecordType.SUCCESS) {
            if (!exportRecord.exportedFiles) {
                exportRecord.exportedFiles = [];
            }
            exportRecord.exportedFiles.push(fileUID);
        } else {
            if (!exportRecord.failedFiles) {
                exportRecord.failedFiles = [];
            }
            exportRecord.failedFiles.push(fileUID);
        }
        await this.ElectronAPIs.setExportRecord(folder, exportRecord);
    }

    async updateExportRecord(newData) {
        await sleep(100);
        if (this.recordUpdateInProgress) {
            await this.recordUpdateInProgress;
            this.recordUpdateInProgress = null;
        }
        this.recordUpdateInProgress = (async () => {
            const folder = getData(LS_KEYS.EXPORT_FOLDER);
            const exportRecord = await this.getExportRecord(folder);
            const newRecord = { ...exportRecord, ...newData };
            console.log(newRecord, JSON.stringify(newRecord, null, 2));
            this.ElectronAPIs.setExportRecord(folder, JSON.stringify(newRecord, null, 2));
        })();
        await this.recordUpdateInProgress;
    }

    async getExportRecord(folder?: string): Promise<ExportRecord> {
        console.log(folder);
        if (!folder) {
            folder = getData(LS_KEYS.EXPORT_FOLDER);
        }
        const recordFile = await this.ElectronAPIs.getExportRecord(folder);
        console.log(recordFile, JSON.parse(recordFile));
        return JSON.parse(recordFile);
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
