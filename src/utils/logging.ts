import log from 'electron-log';
import { LOG_FILENAME, MAX_LOG_SIZE } from '../config';

export function setupLogging() {
    log.transports.file.fileName = LOG_FILENAME;
    log.transports.file.maxSize = MAX_LOG_SIZE;
    log.transports.console.level = false;
}
