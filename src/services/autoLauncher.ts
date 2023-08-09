import { isPlatform } from '../utils/common/platform';
import { AutoLauncherClient } from '../types/autoLauncher';
import linuxAndWinAutoLauncher from './autoLauncherClients/linuxAndWinAutoLauncher';
import macAutoLauncher from './autoLauncherClients/macAutoLauncher';

class AutoLauncher {
    private client: AutoLauncherClient;
    init() {
        if (isPlatform('linux') || isPlatform('windows')) {
            this.client = linuxAndWinAutoLauncher;
        } else {
            this.client = macAutoLauncher;
        }
    }
    async isEnabled() {
        if (!this.client) {
            this.init();
        }
        return await this.client.isEnabled();
    }
    async toggleAutoLaunch() {
        if (!this.client) {
            this.init();
        }
        await this.client.toggleAutoLaunch();
    }

    wasAutoLaunched() {
        if (!this.client) {
            this.init();
        }
        return this.client.wasAutoLaunched();
    }
}

export default new AutoLauncher();
