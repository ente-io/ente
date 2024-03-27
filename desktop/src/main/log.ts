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

const logError1 = (message: string, e?: unknown) => {
    if (!e) {
        log.error(message);
        return;
    }

    let es: string;
    if (e instanceof Error) {
        // In practice, we expect ourselves to be called with Error objects, so
        // this is the happy path so to say.
        es = `${e.name}: ${e.message}\n${e.stack}`;
    } else {
        // For the rest rare cases, use the default string serialization of e.
        es = String(e);
    }

    log.error(`${message}: ${es}`);
};

const logInfo = (message: string) => {
    log.info(message);
};

const logDebug = (message: () => string) => {
    if (isDev) log.debug(() => message);
};

export default {
    /**
     * Log an error message with an optional associated error object.
     *
     * {@link e} is generally expected to be an `instanceof Error` but it can be
     * any arbitrary object too that we obtain, say, when in a try-catch
     * handler.
     *
     * The log is written to disk, and is also printed to the console.
     */
    error: logError1,
    /**
     * Log a message.
     *
     * The log is written to disk, and is also printed to the console.
     */
    info: logInfo,
    /**
     * Log a debug message.
     *
     * The log is not written to disk. And it is printed to the console only on
     * development builds.
     *
     * To avoid running unnecessary code in release builds, this function takes
     * a function to call to get the log message instead of directly taking the
     * message. This function will only be called in development builds.
     */
    debug: logDebug,
};
