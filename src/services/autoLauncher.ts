import { AutoLauncherClient } from '../types/autoLauncher';
import { isPlatformWindows, isPlatformMac } from '../utils/main';
import linuxAutoLauncher from './autoLauncherClients/linuxAutoLauncher';
import macAndWindowsAutoLauncher from './autoLauncherClients/macAndWindowsAutoLauncher';

class AutoLauncher {
    private client: AutoLauncherClient;
    constructor() {
        if (isPlatformMac() || isPlatformWindows()) {
            this.client = macAndWindowsAutoLauncher;
            console.log('platform is Mac || windows');
        } else {
            this.client = linuxAutoLauncher;
            console.log('platform is linux');
        }
    }
    async isEnabled() {
        return await this.client.isEnabled();
    }
    async toggleAutoLaunch() {
        await this.client.toggleAutoLaunch();
    }
}

export default new AutoLauncher();
