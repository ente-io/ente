import isElectron from 'is-electron';
import { runningInBrowser } from 'utils/common';

class ElectronService {
    private ElectronAPIs: any;
    private isBundledApp: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.isBundledApp = !!this.ElectronAPIs?.openLocalCache;
    }

    checkIsBundledApp() {
        return isElectron() && this.isBundledApp;
    }
}

export default new ElectronService();
