import AutoLaunch from 'auto-launch';

class AutoLauncher {
    private instance: AutoLaunch;
    constructor() {
        const autoLauncher = new AutoLaunch({
            name: 'ente',
            isHidden: true,
        });
        this.instance = autoLauncher;
    }
    isEnabled() {
        return this.instance.isEnabled();
    }
    async toggleAutoLaunch() {
        if (await this.instance.isEnabled()) {
            await this.instance.disable();
        } else {
            await this.instance.enable();
        }
    }
}

export default new AutoLauncher();
