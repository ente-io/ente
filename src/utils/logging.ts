import { ipcRenderer } from 'electron';
import { app } from 'electron/main';

export function logError(error: Error, message: string, info?: string): void {
    ipcRenderer.invoke('log-error', error, message, info);
}

export const getLogFolderPath = () => `${app.getPath('logs')}/${app.name}`;
