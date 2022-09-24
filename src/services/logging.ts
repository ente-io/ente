import { LOG_FILENAME, MAX_LOG_SIZE } from '../config';
import log from 'electron-log';
log.transports.file.fileName = LOG_FILENAME;
log.transports.file.maxSize = MAX_LOG_SIZE;

export function logToDisk(logLine: string) {
    log.info(logLine);
}
