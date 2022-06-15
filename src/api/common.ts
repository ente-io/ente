import { ipcRenderer } from 'electron';
import fs from 'promise-fs';

export const sendNotification = (content: string) => {
    ipcRenderer.send('send-notification', content);
};
export const showOnTray = (content: string) => {
    ipcRenderer.send('update-tray', content);
};
export const reloadWindow = () => {
    ipcRenderer.send('reload-window');
};

export async function doesFolderExists(dirPath: string) {
    return await fs
        .stat(dirPath)
        .then((stats) => {
            return stats.isDirectory();
        })
        .catch(() => false);
}
