import { runningInBrowser } from 'utils/common';

class ElectronService {
    ElectronAPIs: any;
    private isBundledApp: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.isBundledApp = !!this.ElectronAPIs?.openLocalCache;
    }

    checkIsBundledApp() {
        return this.isBundledApp;
    }
}

export default new ElectronService();
