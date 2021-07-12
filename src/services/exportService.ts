import { ExportStats } from 'components/ExportModal';
import { retryPromise, runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { Collection, getLocalCollections } from './collectionService';
import downloadManager from './downloadManager';
import { File, getLocalFiles } from './fileService';

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

    exportInProgress: Promise<void> = null;

    stopExport: boolean = false;
    pauseExport: boolean = false;

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
        const dir = getData(LS_KEYS.EXPORT).folder;
        if (!dir) {
            // no-export folder set
            return;
        }
        const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
            dir,
        );
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
        const dir = getData(LS_KEYS.EXPORT).folder;
        if (!dir) {
            // no-export folder set
            return;
        }
        const failedFilesIds: Set<string> = await this.ElectronAPIs.getExportedFiles(
            dir, RecordType.FAILED,
        );
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
                    this.ElectronAPIs.updateExportRecord(dir, `${file.id}_${file.collectionID}`, RecordType.SUCCESS);
                } catch (e) {
                    failedFileCount++;
                    this.ElectronAPIs.updateExportRecord(dir, `${file.id}_${file.collectionID}`, RecordType.FAILED);
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
                this.ElectronAPIs.registerRetryFailedExportListener(this.retryFailedFiles.bind(this, updateProgress));
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
            this.stopExport = false;
            this.pauseExport = false;
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
}
export default new ExportService();
