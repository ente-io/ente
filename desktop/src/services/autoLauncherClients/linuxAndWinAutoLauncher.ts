import AutoLaunch from "auto-launch";
import { app } from "electron";
import { AutoLauncherClient } from "../../types/main";

const LAUNCHED_AS_HIDDEN_FLAG = "hidden";

class LinuxAndWinAutoLauncher implements AutoLauncherClient {
    private instance: AutoLaunch;
    constructor() {
        const autoLauncher = new AutoLaunch({
            name: "ente",
            isHidden: true,
        });
        this.instance = autoLauncher;
    }
    async isEnabled() {
        return await this.instance.isEnabled();
    }
    async toggleAutoLaunch() {
        if (await this.isEnabled()) {
            await this.disableAutoLaunch();
        } else {
            await this.enableAutoLaunch();
        }
    }

    async wasAutoLaunched() {
        return app.commandLine.hasSwitch(LAUNCHED_AS_HIDDEN_FLAG);
    }

    private async disableAutoLaunch() {
        await this.instance.disable();
    }
    private async enableAutoLaunch() {
        await this.instance.enable();
    }
}

export default new LinuxAndWinAutoLauncher();
