import isElectron from 'is-electron';
import { ElectronAPIs } from 'types/electron';

class ElectronService {
    private electronAPIs: ElectronAPIs;
    private isBundledApp: boolean = false;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.isBundledApp = !!this.electronAPIs?.openDiskCache;
    }

    checkIsBundledApp() {
        return isElectron() && this.isBundledApp;
    }

    logToDisk(msg: string) {
        if (this.electronAPIs?.logToDisk) {
            this.electronAPIs?.logToDisk(msg);
        }
    }
}

export default new ElectronService();
