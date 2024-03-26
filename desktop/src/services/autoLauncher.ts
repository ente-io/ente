import { AutoLauncherClient } from "../types/main";
import { isPlatform } from "../utils/common/platform";
import linuxAndWinAutoLauncher from "./autoLauncherClients/linuxAndWinAutoLauncher";
import macAutoLauncher from "./autoLauncherClients/macAutoLauncher";

class AutoLauncher {
    private client: AutoLauncherClient;
    async init() {
        if (isPlatform("linux") || isPlatform("windows")) {
            this.client = linuxAndWinAutoLauncher;
        } else {
            this.client = macAutoLauncher;
        }
        // migrate old auto launch settings for windows from mac auto launcher to linux and windows auto launcher
        if (isPlatform("windows") && (await macAutoLauncher.isEnabled())) {
            await macAutoLauncher.toggleAutoLaunch();
            await linuxAndWinAutoLauncher.toggleAutoLaunch();
        }
    }
    async isEnabled() {
        if (!this.client) {
            await this.init();
        }
        return await this.client.isEnabled();
    }
    async toggleAutoLaunch() {
        if (!this.client) {
            await this.init();
        }
        await this.client.toggleAutoLaunch();
    }

    async wasAutoLaunched() {
        if (!this.client) {
            await this.init();
        }
        return this.client.wasAutoLaunched();
    }
}

export default new AutoLauncher();
