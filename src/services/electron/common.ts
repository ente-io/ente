import isElectron from 'is-electron';
import { ElectronAPIs } from 'types/electron';
import { runningInBrowser } from 'utils/common';

class ElectronService {
    private ElectronAPIs: ElectronAPIs;
    private isBundledApp: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.isBundledApp = !!this.ElectronAPIs?.openDiskCache;
    }

    checkIsBundledApp() {
        return isElectron() && this.isBundledApp;
    }
}

export default new ElectronService();
