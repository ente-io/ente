import log from 'electron-log';
import { ipcRenderer } from 'electron';

export function logToDisk(logLine: string) {
    log.info(logLine);
}

export function openLogDirectory() {
    ipcRenderer.invoke('open-log-dir');
}
