import log from "electron-log";
import util from "node:util";
import { isDev } from "./utils/electron";

/**
 * Initialize logging in the main process.
 *
 * This will set our underlying logger up to log to a file named `ente.log`, see
 * [Note: App log path].
 *
 * On dev builds, it will also log to the console.
 */
export const initLogging = () => {
    log.transports.file.fileName = "ente.log";
    log.transports.file.maxSize = 50 * 1024 * 1024; // 50 MB
    log.transports.file.format = "[{y}-{m}-{d}T{h}:{i}:{s}{z}] {text}";

    log.transports.console.level = false;

    // Log unhandled errors and promise rejections.
    log.errorHandler.startCatching({
        onError: ({ error, errorName }) => {
            logError(errorName, error);
            // Prevent the default electron-log actions (e.g. showing a dialog)
            // from getting triggered.
            return false;
        },
    });
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

const messageWithError = (message: string, e?: unknown) => {
    if (!e) return message;

    let es: string;
    if (e instanceof Error) {
        // In practice, we expect ourselves to be called with Error objects, so
        // this is the happy path so to say.
        es = [`${e.name}: ${e.message}`, e.stack].filter((x) => x).join("\n");
    } else {
        // For the rest rare cases, use the default string serialization of e.
        // eslint-disable-next-line @typescript-eslint/no-base-to-string
        es = String(e);
    }

    return `${message}: ${es}`;
};

const logError = (message: string, e?: unknown) => {
    const m = `[error] ${messageWithError(message, e)}`;
    console.error(m);
    log.error(`[main] ${m}`);
};

const logWarn = (message: string, e?: unknown) => {
    const m = `[warn] ${messageWithError(message, e)}`;
    console.error(m);
    log.error(`[main] ${m}`);
};

const logInfo = (...params: unknown[]) => {
    const message = params
        .map((p) => (typeof p == "string" ? p : util.inspect(p)))
        .join(" ");
    const m = `[info] ${message}`;
    if (isDev) console.log(m);
    log.info(`[main] ${m}`);
};

const logDebug = (param: () => unknown) => {
    if (isDev) {
        const p = param();
        console.log(`[debug] ${typeof p == "string" ? p : util.inspect(p)}`);
    }
};

/**
 * Handle log messages posted from the utility process in the main process.
 *
 * See: [Note: Using Electron APIs in UtilityProcess]
 *
 * @param message The arbitrary message that was received as an argument to the
 * "message" event invoked on a {@link UtilityProcess}.
 *
 * @returns true if the message was recognized and handled, and false otherwise.
 */
export const processUtilityProcessLogMessage = (
    logTag: string,
    message: unknown,
) => {
    const m = message; /* shorter alias */
    if (m && typeof m == "object" && "method" in m && "p" in m) {
        const p = m.p;
        switch (m.method) {
            case "log.errorString":
                if (typeof p == "string") {
                    logError(`${logTag} ${p}`);
                    return true;
                }
                break;
            case "log.warnString":
                if (typeof p == "string") {
                    logWarn(`${logTag} ${p}`);
                    return true;
                }
                break;
            case "log.info":
                if (Array.isArray(p)) {
                    // Need to cast from any[] to unknown[]
                    logInfo(logTag, ...(p as unknown[]));
                    return true;
                }
                break;
            case "log.debugString":
                if (typeof p == "string") {
                    logDebug(() => `${logTag} ${p}`);
                    return true;
                }
                break;
            default:
                break;
        }
    }
    return false;
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
     * any arbitrary object that we obtain, say, when in a try-catch handler (in
     * JavaScript any arbitrary value can be thrown).
     *
     * The log is written to disk and printed to the main (Node.js) process's
     * console.
     */
    error: logError,
    /**
     * Sibling of {@link error}, with the same parameters and behaviour, except
     * it gets prefixed with a warning instead of an error tag.
     */
    warn: logWarn,
    /**
     * Log a message.
     *
     * This is meant as a replacement of {@link console.log}, and takes an
     * arbitrary number of arbitrary parameters that it then serializes.
     *
     * The log is written to disk. In development builds, the log is also
     * printed to the main (Node.js) process console.
     */
    info: logInfo,
    /**
     * Log a debug message.
     *
     * To avoid running unnecessary code in release builds, this takes a
     * function to call to get the log message instead of directly taking the
     * message. The provided function will only be called in development builds.
     *
     * The function can return an arbitrary value which is serialized before
     * being logged.
     *
     * This log is NOT written to disk. It is printed to the main (Node.js)
     * process console, but only on development builds.
     */
    debug: logDebug,
};
