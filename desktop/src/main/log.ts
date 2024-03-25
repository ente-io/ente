import log from "electron-log";
import { isDev } from "./general";

export function setupLogging(isDev?: boolean) {
    log.transports.file.fileName = "ente.log";
    log.transports.file.maxSize = 50 * 1024 * 1024; // 50MB;
    if (!isDev) {
        log.transports.console.level = false;
    }
    log.transports.file.format =
        "[{y}-{m}-{d}T{h}:{i}:{s}{z}] [{level}]{scope} {text}";
}

export const logToDisk = (message: string) => {
    log.info(message);
};

export const logError = logErrorSentry;

/** Deprecated, but no alternative yet */
export function logErrorSentry(
    error: any,
    msg: string,
    info?: Record<string, unknown>,
) {
    logToDisk(
        `error: ${error?.name} ${error?.message} ${
            error?.stack
        } msg: ${msg} info: ${JSON.stringify(info)}`,
    );
    if (isDev) {
        console.log(error, { msg, info });
    }
}
