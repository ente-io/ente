import { runningInBrowser } from 'utils/common/utilFunctions';
import { collection } from './collectionService';
import downloadManager from './downloadManager';
import { file } from './fileService';

enum ExportNotification {
    START = 'export started',
    FINISH = 'export finished',
}
class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    async exportFiles(files: file[], collections: collection[]) {
        try {
            const dir = await this.ElectronAPIs.selectRootDirectory();
            if (!dir) {
                // directory selector closed
                return;
            }
            const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
                dir
            );
            const collectionIDMap = new Map<number, string>();
            for (let collection of collections) {
                let collectionFolderPath = `${dir}/${
                    collection.id
                }_${this.sanitizeNames(collection.name)}`;
                await this.ElectronAPIs.checkExistsAndCreateCollectionDir(
                    collectionFolderPath
                );
                collectionIDMap.set(collection.id, collectionFolderPath);
            }
            this.ElectronAPIs.sendNotification(ExportNotification.START);
            for (let [index, file] of files.entries()) {
                const uid = `${file.id}_${this.sanitizeNames(
                    file.metadata.title
                )}`;
                const filePath =
                    collectionIDMap.get(file.collectionID) + '/' + uid;
                if (!exportedFiles.has(filePath)) {
                    await this.downloadAndSave(file, filePath);
                    this.ElectronAPIs.updateExportRecord(dir, filePath);
                }
                this.ElectronAPIs.showOnTray([
                    { label: `${index + 1} / ${files.length} files exported` },
                ]);
            }
            this.ElectronAPIs.sendNotification(ExportNotification.FINISH);
            this.ElectronAPIs.showOnTray([]);
        } catch (e) {
            console.error(e);
        }
    }

    async downloadAndSave(file: file, path) {
        const fileStream = await downloadManager.downloadFile(file);

        this.ElectronAPIs.saveToDisk(path, fileStream);
    }
    private sanitizeNames(name) {
        return name.replaceAll('/', '_').replaceAll(' ', '_');
    }
}
export default new ExportService();
