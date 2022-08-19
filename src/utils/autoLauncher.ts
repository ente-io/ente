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
            return this.instance.disable();
        } else {
            this.instance.isEnabled();
        }
    }
}

export default new AutoLauncher();
