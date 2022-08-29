import { ElectronAPIs } from 'types/electron';
import { runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';

class ElectronFSService {
    private ElectronAPIs: ElectronAPIs;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
    }

    getDirFiles(dirPath: string) {
        if (this.ElectronAPIs.getDirFiles) {
            return this.ElectronAPIs.getDirFiles(dirPath);
        }
    }

    async isFolder(folderPath: string) {
        try {
            const isFolder = await this.ElectronAPIs.isFolder(folderPath);
            return isFolder;
        } catch (e) {
            logError(e, 'error while checking if is Folder');
        }
    }
}

export default new ElectronFSService();
