import { AppUpdateInfo, ElectronAPIs } from 'types/electron';

class ElectronUpdateService {
    private electronAPIs: ElectronAPIs;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    registerUpdateEventListener(
        showUpdateDialog: (updateInfo: AppUpdateInfo) => void
    ) {
        if (this.electronAPIs?.registerUpdateEventListener) {
            this.electronAPIs.registerUpdateEventListener(showUpdateDialog);
        }
    }

    updateAndRestart() {
        if (this.electronAPIs?.updateAndRestart) {
            this.electronAPIs.updateAndRestart();
        }
    }

    skipAppVersion(version: string) {
        if (this.electronAPIs?.skipAppVersion) {
            this.electronAPIs.skipAppVersion(version);
        }
    }
}

export default new ElectronUpdateService();
