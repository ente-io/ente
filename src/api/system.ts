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
