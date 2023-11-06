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
    getAppVersion() {
        if (this.electronAPIs?.getAppVersion) {
            return this.electronAPIs.getAppVersion();
        }
    }
    logRendererProcessMemoryUsage(message: string) {
        if (this.electronAPIs?.logRendererProcessMemoryUsage) {
            return this.electronAPIs.logRendererProcessMemoryUsage(message);
        }
    }
    registerForegroundEventListener(onForeground: () => void) {
        if (this.electronAPIs?.registerForegroundEventListener) {
            this.electronAPIs.registerForegroundEventListener(onForeground);
        }
    }

    checkExistsAndCreateDir(dirPath: string) {
        if (this.electronAPIs?.checkExistsAndCreateDir) {
            this.electronAPIs.checkExistsAndCreateDir(dirPath);
        }
    }

    openDirectory(dirPath: string) {
        if (this.electronAPIs?.openDirectory) {
            this.electronAPIs.openDirectory(dirPath);
        }
    }

    selectDirectory() {
        if (this.electronAPIs?.selectDirectory) {
            return this.electronAPIs.selectDirectory();
        }
    }

    updateOptOutOfCrashReports(optOut: boolean) {
        if (this.electronAPIs?.updateOptOutOfCrashReports) {
            return this.electronAPIs.updateOptOutOfCrashReports(optOut);
        }
    }
    getPlatform() {
        if (this.electronAPIs?.getPlatform) {
            return this.electronAPIs.getPlatform();
        }
    }
}

export default new ElectronService();
