import isElectron from 'is-electron';
import { ElectronAPIs } from 'types/electron';

class ElectronService {
    private electronAPIs: ElectronAPIs;
    private isBundledApp: boolean = false;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    checkIsBundledApp() {
        return isElectron() && !!this.electronAPIs?.openDiskCache;
    }

    logToDisk(msg: string) {
        if (this.electronAPIs?.logToDisk) {
            this.electronAPIs.logToDisk(msg);
        }
    }

    openLogDirectory() {
        if (this.electronAPIs?.openLogDirectory) {
            this.electronAPIs.openLogDirectory();
        }
    }
}

export default new ElectronService();
