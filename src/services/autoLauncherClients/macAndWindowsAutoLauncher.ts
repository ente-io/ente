import { app } from 'electron';
import { AutoLauncherClient } from '../../types/autoLauncher';

class MacAndWindowsAutoLauncher implements AutoLauncherClient {
    async isEnabled() {
        return app.getLoginItemSettings().openAtLogin;
    }
    async toggleAutoLaunch() {
        if (this.isEnabled) {
            this.enableAutoLogin();
        } else {
            this.disableAutoLogin();
        }
    }

    private disableAutoLogin() {
        app.setLoginItemSettings({ openAsHidden: false, openAtLogin: false });
    }
    private enableAutoLogin() {
        app.setLoginItemSettings({ openAsHidden: false, openAtLogin: true });
    }
}

export default new MacAndWindowsAutoLauncher();
