import log from "electron-log";
import { LOG_FILENAME, MAX_LOG_SIZE } from "../config";

export function setupLogging(isDev?: boolean) {
    log.transports.file.fileName = LOG_FILENAME;
    log.transports.file.maxSize = MAX_LOG_SIZE;
    if (!isDev) {
        log.transports.console.level = false;
    }
    log.transports.file.format =
        "[{y}-{m}-{d}T{h}:{i}:{s}{z}] [{level}]{scope} {text}";
}

export function makeID(length: number) {
    let result = "";
    const characters =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}

export function convertBytesToHumanReadable(
    bytes: number,
    precision = 2
): string {
    if (bytes === 0 || isNaN(bytes)) {
        return "0 MB";
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + " " + sizes[i];
}
