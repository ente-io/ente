import { LOG_FILENAME, MAX_LOG_SIZE } from '../config';
import log from 'electron-log';
import { ipcRenderer } from 'electron';
log.transports.file.fileName = LOG_FILENAME;
log.transports.file.maxSize = MAX_LOG_SIZE;
log.transports.console.level = false;

export function logToDisk(logLine: string) {
    log.info(logLine);
}

export function openLogDirectory() {
    ipcRenderer.invoke('open-log-dir');
}
