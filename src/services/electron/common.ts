import isElectron from 'is-electron';
import { ElectronAPIs } from 'types/electron';
import { runningInBrowser } from 'utils/common';

class ElectronService {
    private electronAPIs: ElectronAPIs;
    private isBundledApp: boolean = false;

    constructor() {
        this.electronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.isBundledApp = !!this.electronAPIs?.openDiskCache;
    }

    checkIsBundledApp() {
        return isElectron() && this.isBundledApp;
    }
}

export default new ElectronService();
