import { runningInBrowser } from 'utils/common/utilFunctions';
import downloadManager from './downloadManager';
import { file } from './fileService';

enum ExportNotification {
    START = 'export started',
    FINISH = 'export finished',
}
class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    async exportFiles(files: file[]) {
        const dir = await this.ElectronAPIs.selectDirectory();
        const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
            dir
        );
        this.ElectronAPIs.sendNotification(ExportNotification.START);
        for (let [index, file] of files.entries()) {
            const uid = `${file.id}_${file.metadata.title}`;
            if (!exportedFiles.has(uid)) {
                await this.downloadAndSave(file, `${dir}/${uid}`);
                this.ElectronAPIs.updateExportRecord(dir, uid);
                this.ElectronAPIs.updateExportProgress(index, files.length);
            }
        }
        this.ElectronAPIs.sendNotification(ExportNotification.FINISH);
    }

    async downloadAndSave(file: file, path) {
        console.log(this.ElectronAPIs);

        const fileStream = await downloadManager.downloadFile(file);

        this.ElectronAPIs.saveToDisk(path, fileStream);
    }
}
export default new ExportService();
