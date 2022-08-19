import AutoLaunch from 'auto-launch';

class AutoLauncher {
    instance: AutoLaunch;
    constructor() {
        const autoLauncher = new AutoLaunch({
            name: 'ente',
            isHidden: true,
        });
        this.instance = autoLauncher;
    }
    enable() {
        this.instance.enable();
    }
    disable() {
        this.instance.disable();
    }
    isEnabled() {
        this.instance.isEnabled();
    }
}

export default new AutoLauncher();
