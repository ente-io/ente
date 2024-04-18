import AutoLaunch from "auto-launch";
import { app } from "electron/main";

class AutoLauncher {
    /**
     * This property will be set and used on Linux and Windows. On macOS,
     * there's a separate API
     */
    private autoLaunch?: AutoLaunch;

    constructor() {
        if (process.platform != "darwin") {
            this.autoLaunch = new AutoLaunch({
                name: "ente",
                isHidden: true,
            });
        }
    }

    async isEnabled() {
        const autoLaunch = this.autoLaunch;
        if (autoLaunch) {
            return await autoLaunch.isEnabled();
        } else {
            return app.getLoginItemSettings().openAtLogin;
        }
    }

    async toggleAutoLaunch() {
        const isEnabled = await this.isEnabled();
        const autoLaunch = this.autoLaunch;
        if (autoLaunch) {
            if (isEnabled) await autoLaunch.disable();
            else await autoLaunch.enable();
        } else {
            if (isEnabled) app.setLoginItemSettings({ openAtLogin: false });
            else app.setLoginItemSettings({ openAtLogin: true });
        }
    }

    async wasAutoLaunched() {
        if (this.autoLaunch) {
            return app.commandLine.hasSwitch("hidden");
        } else {
            // TODO(MR): This apparently doesn't work anymore.
            return app.getLoginItemSettings().wasOpenedAtLogin;
        }
    }
}

export default new AutoLauncher();
