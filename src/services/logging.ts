import { LOG_FILENAME } from '../config';
import log from 'electron-log';
log.transports.file.fileName = LOG_FILENAME;

export function logToDisk(logLine: string) {
    log.info(logLine);
}
