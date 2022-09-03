export interface AutoLauncherClient {
    isEnabled: () => Promise<boolean>;
    toggleAutoLaunch: () => Promise<void>;
    wasAutoLaunched: () => Promise<boolean>;
}
