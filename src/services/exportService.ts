import { runningInBrowser } from 'utils/common/utilFunctions';
import downloadManager from './downloadManager';
import { file } from './fileService';

class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    async selectDirectory() {
        const dir = await this.ElectronAPIs.selectDirectory();
        console.log(dir);
        return;
    }

    async exportFiles(files: file[], path) {
        for (let file of files) {
            const fileStream = await downloadManager.downloadFile(file);
            this.ElectronAPIs.savetoDisk(
                path + `/${file.metadata.title}`,
                fileStream
            );
        }
    }
}
export default new ExportService();
