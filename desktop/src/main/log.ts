import log from "electron-log";
import util from "node:util";
import { isDev } from "./util";

/**
 * Initialize logging in the main process.
 *
 * This will set our underlying logger up to log to a file named `ente.log`,
 *
 * - on Linux at ~/.config/ente/logs/main.log
 * - on macOS at ~/Library/Logs/ente/main.log
 * - on Windows at %USERPROFILE%\AppData\Roaming\ente\logs\main.log
 *
 * On dev builds, it will also log to the console.
 */
export const initLogging = () => {
    log.transports.file.fileName = "ente.log";
    log.transports.file.maxSize = 50 * 1024 * 1024; // 50MB;
    log.transports.file.format = "[{y}-{m}-{d}T{h}:{i}:{s}{z}] {text}";

    log.transports.console.level = false;
};

/**
 * Write a {@link message} to the on-disk log.
 *
 * This is used by the renderer process (via the contextBridge) to add entries
 * in the log that is saved on disk.
 */
export const logToDisk = (message: string) => {
    log.info(`[rndr] ${message}`);
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
        logError_(message);
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

    logError_(`${message}: ${es}`);
};

const logError_ = (message: string) => {
    log.error(`[main] [error] ${message}`);
    if (isDev) console.error(`[error] ${message}`);
};

const logInfo = (...params: any[]) => {
    const message = params
        .map((p) => (typeof p == "string" ? p : util.inspect(p)))
        .join(" ");
    log.info(`[main] ${message}`);
    if (isDev) console.log(message);
};

const logDebug = (param: () => any) => {
    if (isDev) console.log(`[debug] ${util.inspect(param())}`);
};

/**
 * Ente's logger.
 *
 * This is an object that provides three functions to log at the corresponding
 * levels - error, info or debug.
 *
 * {@link initLogging} needs to be called once before using any of these.
 */
export default {
    /**
     * Log an error message with an optional associated error object.
     *
     * {@link e} is generally expected to be an `instanceof Error` but it can be
     * any arbitrary object that we obtain, say, when in a try-catch handler.
     *
     * The log is written to disk. In development builds, the log is also
     * printed to the (Node.js process') console.
     */
    error: logError1,
    /**
     * Log a message.
     *
     * This is meant as a replacement of {@link console.log}, and takes an
     * arbitrary number of arbitrary parameters that it then serializes.
     *
     * The log is written to disk. In development builds, the log is also
     * printed to the (Node.js process') console.
     */
    info: logInfo,
    /**
     * Log a debug message.
     *
     * To avoid running unnecessary code in release builds, this takes a
     * function to call to get the log message instead of directly taking the
     * message. The provided function will only be called in development builds.
     *
     * The function can return an arbitrary value which is serialied before
     * being logged.
     *
     * This log is not written to disk. It is printed to the (Node.js process')
     * console only on development builds.
     */
    debug: logDebug,
};
