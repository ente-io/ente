import isElectron from 'is-electron';
import { ElectronAPIs } from 'types/electron';

class ElectronService {
    private electronAPIs: ElectronAPIs;

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

    getSentryUserID() {
        if (this.electronAPIs?.getSentryUserID) {
            return this.electronAPIs.getSentryUserID();
        }
    }
}

export default new ElectronService();
