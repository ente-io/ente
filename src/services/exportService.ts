import { runningInBrowser } from 'utils/common/utilFunctions';
import { collection } from './collectionService';
import downloadManager from './downloadManager';
import { file } from './fileService';

enum ExportNotification {
    START = 'export started',
    IN_PROGRESS = 'export already in progress',
    FINISH = 'export finished',
    ABORT = 'export aborted',
}
class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    exportInProgress: Promise<void> = null;
    abortExport: boolean = false;

    async exportFiles(files: file[], collections: collection[]) {
        if (this.exportInProgress) {
            this.ElectronAPIs.sendNotification(ExportNotification.IN_PROGRESS);
            return this.exportInProgress;
        }
        this.exportInProgress = this.fileExporter(files, collections);
        return this.exportInProgress;
    }
    async fileExporter(files: file[], collections: collection[]) {
        try {
            const dir = await this.ElectronAPIs.selectRootDirectory();
            if (!dir) {
                // directory selector closed
                return;
            }
            const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
                dir
            );
            this.ElectronAPIs.showOnTray(`starting export`);
            this.ElectronAPIs.registerStopExportListener(
                () => (this.abortExport = true)
            );
            const collectionIDMap = new Map<number, string>();
            for (let collection of collections) {
                let collectionFolderPath = `${dir}/${
                    collection.id
                }_${this.sanitizeName(collection.name)}`;
                await this.ElectronAPIs.checkExistsAndCreateCollectionDir(
                    collectionFolderPath
                );
                collectionIDMap.set(collection.id, collectionFolderPath);
            }
            this.ElectronAPIs.sendNotification(ExportNotification.START);
            for (let [index, file] of files.entries()) {
                if (this.abortExport) {
                    break;
                }
                const uid = `${file.id}_${this.sanitizeName(
                    file.metadata.title
                )}`;
                const filePath =
                    collectionIDMap.get(file.collectionID) + '/' + uid;
                if (!exportedFiles.has(filePath)) {
                    await this.downloadAndSave(file, filePath);
                    this.ElectronAPIs.updateExportRecord(dir, filePath);
                }
                this.ElectronAPIs.showOnTray(
                    `exporting file ${index + 1} / ${files.length}`
                );
            }
            this.ElectronAPIs.sendNotification(
                this.abortExport
                    ? ExportNotification.ABORT
                    : ExportNotification.FINISH
            );
        } catch (e) {
            console.error(e);
        } finally {
            this.exportInProgress = null;
            this.ElectronAPIs.showOnTray();
            this.abortExport = false;
        }
    }

    async downloadAndSave(file: file, path) {
        const fileStream = await downloadManager.downloadFile(file);
        this.ElectronAPIs.saveStreamToDisk(path, fileStream);
        this.ElectronAPIs.saveFileToDisk(
            `${path}.json`,
            JSON.stringify(file.metadata, null, 2)
        );
    }
    private sanitizeName(name) {
        return name.replaceAll('/', '_').replaceAll(' ', '_');
    }
}
export default new ExportService();
