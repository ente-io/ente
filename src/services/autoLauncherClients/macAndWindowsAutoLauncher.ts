import { app } from 'electron';
import { AutoLauncherClient } from '../../types/autoLauncher';

class MacAndWindowsAutoLauncher implements AutoLauncherClient {
    async isEnabled() {
        return app.getLoginItemSettings().openAtLogin;
    }
    async toggleAutoLaunch() {
        if (await this.isEnabled()) {
            this.disableAutoLogin();
        } else {
            this.enableAutoLogin();
        }
    }

    private disableAutoLogin() {
        app.setLoginItemSettings({ openAsHidden: true, openAtLogin: false });
    }
    private enableAutoLogin() {
        app.setLoginItemSettings({ openAsHidden: true, openAtLogin: true });
    }
}

export default new MacAndWindowsAutoLauncher();
