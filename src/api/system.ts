import { ipcRenderer } from 'electron';

export const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};
export const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};
export const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

export const registerUpdateEventListener = (showUpdateDialog: () => void) => {
    ipcRenderer.on('show-update-dialog', () => {
        showUpdateDialog();
    });
};

export const updateAndRestart = () => {
    ipcRenderer.send('update-and-restart');
};
