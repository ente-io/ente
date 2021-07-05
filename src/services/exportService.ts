import { retryPromise, runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { Collection, getLocalCollections } from './collectionService';
import downloadManager from './downloadManager';
import { File, getLocalFiles } from './fileService';

enum ExportNotification {
    START = 'export started',
    IN_PROGRESS = 'export already in progress',
    FINISH = 'export finished',
    FAILED = 'export failed',
    ABORT = 'export aborted',
}
class ExportService {
    ElectronAPIs: any;

    exportInProgress: Promise<void> = null;

    abortExport: boolean = false;
    failedFiles: File[] = [];
    constructor() {
        const main = async () => {
            this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
            if (this.ElectronAPIs) {
                const autoStartExport = getData(LS_KEYS.EXPORT_IN_PROGRESS);
                if (autoStartExport?.status) {
                    this.exportFiles(await getLocalFiles(), await getLocalCollections());
                }
            }
        };
        main();
    }
    async exportFiles(files: File[], collections: Collection[]) {
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.exportInProgress = this.fileExporter(files, collections);
        return this.exportInProgress;
    }

    async fileExporter(files: File[], collections: Collection[]) {
        try {
            const dir = await this.ElectronAPIs.selectRootDirectory();
            if (!dir) {
                // directory selector closed
                return;
            }
            const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
                dir,
            );
            this.ElectronAPIs.showOnTray('starting export');
            this.ElectronAPIs.registerStopExportListener(
                () => (this.abortExport = true),
            );
            setData(LS_KEYS.EXPORT_IN_PROGRESS, { status: true });
            const collectionIDMap = new Map<number, string>();
            for (const collection of collections) {
                const collectionFolderPath = `${dir}/${collection.id}_${this.sanitizeName(collection.name)}`;
                await this.ElectronAPIs.checkExistsAndCreateCollectionDir(
                    collectionFolderPath,
                );
                collectionIDMap.set(collection.id, collectionFolderPath);
            }
            this.ElectronAPIs.sendNotification(ExportNotification.START);
            for (const [index, file] of files.entries()) {
                if (this.abortExport) {
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
                        `exporting file ${index + 1} / ${files.length}`,
                });
            }
            this.ElectronAPIs.sendNotification(
                this.abortExport ?
                    ExportNotification.ABORT :
                    this.failedFiles.length > 0 ? ExportNotification.FAILED :
                        ExportNotification.FINISH,
            );
            if (this.failedFiles.length > 0) {
                this.ElectronAPIs.registerRetryFailedExportListener(this.fileExporter.bind(this, this.failedFiles, collections));
                this.ElectronAPIs.showOnTray({
                    retry_export:
                        `export failed - retry export`,
                });
            } else {
                this.ElectronAPIs.showOnTray();
                setData(LS_KEYS.EXPORT_IN_PROGRESS, { status: false });
            }
        } catch (e) {
            logError(e);
        } finally {
            this.exportInProgress = null;
            this.abortExport = false;
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
