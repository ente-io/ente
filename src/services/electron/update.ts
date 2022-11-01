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
}

export default new ElectronUpdateService();
