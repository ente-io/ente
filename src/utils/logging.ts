import log from 'electron-log';
import { LOG_FILENAME, MAX_LOG_SIZE } from '../config';

export function setupLogging() {
    log.transports.file.fileName = LOG_FILENAME;
    log.transports.file.maxSize = MAX_LOG_SIZE;
    log.transports.console.level = false;
    log.transports.file.format =
        '[{y}-{m}-{d}T{h}:{i}:{s}{z}] [{level}]{scope} {text}';
}

export function makeID(length: number) {
    let result = '';
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}
