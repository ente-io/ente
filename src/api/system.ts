import { ipcRenderer } from 'electron';
import { AppUpdateInfo } from '../types';

export const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};
export const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};
export const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

export const registerUpdateEventListener = (
    showUpdateDialog: (updateInfo: AppUpdateInfo) => void
) => {
    ipcRenderer.removeAllListeners('show-update-dialog');
    ipcRenderer.on('show-update-dialog', (_, updateInfo: AppUpdateInfo) => {
        showUpdateDialog(updateInfo);
    });
};

export const updateAndRestart = () => {
    ipcRenderer.send('update-and-restart');
};
