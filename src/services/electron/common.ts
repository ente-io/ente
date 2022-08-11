import isElectron from 'is-electron';

class ElectronService {
    private ElectronAPIs: any;
    private isBundledApp: boolean = false;

    constructor() {
        this.ElectronAPIs = globalThis['ElectronAPIs'];
        this.isBundledApp = !!this.ElectronAPIs?.openDiskCache;
    }

    checkIsBundledApp() {
        return isElectron() && this.isBundledApp;
    }
}

export default new ElectronService();
