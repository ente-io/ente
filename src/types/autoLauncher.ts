export interface AutoLauncherClient {
    isEnabled: () => Promise<boolean>;
    toggleAutoLaunch: () => Promise<void>;
    wasOpenedAsHidden: () => Promise<boolean>;
}
