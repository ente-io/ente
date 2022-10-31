import { ElectronAPIs } from 'types/electron';

class ElectronUpdateService {
    private electronAPIs: ElectronAPIs;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    registerUpdateEventListener(
        showUpdateDialog: (updateInfo: { updateDownloaded: boolean }) => void
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
