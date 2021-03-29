import { runningInBrowser } from 'utils/common/utilFunctions';
import downloadManager from './downloadManager';
import { file } from './fileService';

class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    async exportFiles(files: file[]) {
        const dir = await this.ElectronAPIs.selectDirectory();
        console.log(files);
        for (let file of files) {
            await this.downloadAndSave(file, `${dir}/${file.metadata.title}`);
        }
    }

    async downloadAndSave(file: file, path) {
        console.log(this.ElectronAPIs);

        const fileStream = await downloadManager.downloadFile(file);

        this.ElectronAPIs.saveToDisk(path, fileStream);
    }
}
export default new ExportService();
