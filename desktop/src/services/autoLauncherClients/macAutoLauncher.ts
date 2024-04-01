import { app } from "electron";
import { AutoLauncherClient } from "../../types/main";

class MacAutoLauncher implements AutoLauncherClient {
    async isEnabled() {
        return app.getLoginItemSettings().openAtLogin;
    }
    async toggleAutoLaunch() {
        if (await this.isEnabled()) {
            this.disableAutoLaunch();
        } else {
            this.enableAutoLaunch();
        }
    }

    async wasAutoLaunched() {
        return app.getLoginItemSettings().wasOpenedAtLogin;
    }

    private disableAutoLaunch() {
        app.setLoginItemSettings({ openAtLogin: false });
    }
    private enableAutoLaunch() {
        app.setLoginItemSettings({ openAtLogin: true });
    }
}

export default new MacAutoLauncher();
