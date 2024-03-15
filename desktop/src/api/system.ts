import { ipcRenderer } from "electron";
import { AppUpdateInfo } from "../types";

export const reloadWindow = () => {
    ipcRenderer.send("reload-window");
};

export const registerUpdateEventListener = (
    showUpdateDialog: (updateInfo: AppUpdateInfo) => void,
) => {
    ipcRenderer.removeAllListeners("show-update-dialog");
    ipcRenderer.on("show-update-dialog", (_, updateInfo: AppUpdateInfo) => {
        showUpdateDialog(updateInfo);
    });
};

export const registerForegroundEventListener = (onForeground: () => void) => {
    ipcRenderer.removeAllListeners("app-in-foreground");
    ipcRenderer.on("app-in-foreground", () => {
        onForeground();
    });
};

export const updateAndRestart = () => {
    ipcRenderer.send("update-and-restart");
};

export const skipAppUpdate = (version: string) => {
    ipcRenderer.send("skip-app-update", version);
};

export const muteUpdateNotification = (version: string) => {
    ipcRenderer.send("mute-update-notification", version);
};
