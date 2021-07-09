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
class ExportService {
    ElectronAPIs: any;

    exportInProgress: Promise<void> = null;

    stopExport: boolean = false;
    pauseExport: boolean = false;
    failedFiles: File[] = [];
    constructor() {
        const main = async () => {
            this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
            if (this.ElectronAPIs) {
                const autoStartExport = getData(LS_KEYS.EXPORT);
                if (autoStartExport?.status) {
                    this.exportFiles(null);
                }
            }
        };
        main();
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
        this.exportInProgress = this.fileExporter(files, collections, updateProgress);
        return this.exportInProgress;
    }

    async fileExporter(files: File[], collections: Collection[], updateProgress: (stats: ExportStats) => void) {
        try {
            const dir = getData(LS_KEYS.EXPORT).folder;
            if (!dir) {
                // no-export folder set
                return;
            }
            const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
                dir,
            );
            this.ElectronAPIs.showOnTray({
                export_progress:
                    `0 / ${files.length} files exported`,
            });
            updateProgress({ current: 0, total: files.length, failed: this.failedFiles.length });
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
                if (!exportedFiles.has(filePath)) {
                    try {
                        await this.downloadAndSave(file, filePath);
                        this.ElectronAPIs.updateExportRecord(dir, filePath);
                    } catch (e) {
                        this.failedFiles.push(file);
                        logError(e, 'download and save failed for file during export');
                    }
                }
                this.ElectronAPIs.showOnTray({
                    export_progress:
                        `${index + 1} / ${files.length} files exported`,
                });
                updateProgress({ current: index + 1, total: files.length, failed: this.failedFiles.length });
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
            } else if (this.failedFiles.length > 0) {
                this.ElectronAPIs.sendNotification(
                    ExportNotification.FAILED,
                );
                this.ElectronAPIs.registerRetryFailedExportListener(this.fileExporter.bind(this, this.failedFiles, collections));
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
            this.failedFiles = [];
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
