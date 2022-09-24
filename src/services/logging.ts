import log from 'electron-log';

export function logToDisk(logLine: string) {
    log.info(logLine);
}
