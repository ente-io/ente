import { AutoLauncherClient } from '../types/autoLauncher';
import { isPlatformWindows, isPlatformMac } from '../utils/main';
import linuxAutoLauncher from './autoLauncherClients/linuxAutoLauncher';
import macAndWindowsAutoLauncher from './autoLauncherClients/macAndWindowsAutoLauncher';

class AutoLauncher {
    private client: AutoLauncherClient;
    init() {
        if (isPlatformMac() || isPlatformWindows()) {
            this.client = macAndWindowsAutoLauncher;
        } else {
            this.client = linuxAutoLauncher;
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
