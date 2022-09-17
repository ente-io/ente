import { ipcRenderer } from 'electron';

export function logError(error: Error, message: string, info?: string): void {
    ipcRenderer.invoke('log-error', error, message, info);
}
