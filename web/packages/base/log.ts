import { inWorker } from "ente-base/env";
import { isDevBuild } from "./env";
import { logToDisk as webLogToDisk } from "./log-web";
import { workerBridge } from "./worker/worker-bridge";

/**
 * Whether logs go to disk or are always emitted to the console.
 */
let shouldLogToDisk = true;

/**
 * By default, logs get saved into a ring buffer in the browser's local storage.
 * However, in some contexts, e.g. when we're running as the cast app, there is
 * no mechanism for the user to retrieve these logs. So this function exists as
 * a way to disable the on disk logging and always use the console.
 */
export const disableDiskLogs = () => (shouldLogToDisk = false);

/**
 * Write a {@link message} to the on-disk log.
 *
 * This is used by the renderer process (via the contextBridge) to add entries
 * in the log that is saved on disk.
 */
export const logToDisk = (message: string) => {
    const electron = globalThis.electron;
    if (electron) electron.logToDisk(message);
    else if (inWorker()) workerLogToDisk(message);
    else webLogToDisk(message);
};

const workerLogToDisk = (message: string) => {
    workerBridge!.logToDisk(message).catch((e: unknown) => {
        console.error(
            "Failed to log a message from worker",
            e,
            "\nThe message was",
            message,
        );
    });
};

const messageWithError = (message: string, e?: unknown) => {
    if (!e) return message;

    let es: string;
    if (e instanceof Error) {
        // In practice, we expect ourselves to be called with Error objects, so
        // this is the happy path so to say.
        es = `${e.name}: ${e.message}`;
        const st = e.stack;
        if (st) {
            // On V8 (as of 2024), the stack trace begins by repeating the error's
            // name and message, trim that off.
            // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/stack
            es = st.startsWith(es)
                ? es.concat(st.slice(es.length)) /* retain the '\n' */
                : [es, st].join("\n");
        }
    } else {
        // For the rest rare cases, use the default string serialization of e.
        // eslint-disable-next-line @typescript-eslint/no-base-to-string
        es = String(e);
    }

    return `${message}: ${es}`;
};

const logError = (message: unknown, e?: unknown) => {
    const m =
        typeof message == "string"
            ? `[error] ${messageWithError(message, e)}`
            : `[error] ${messageWithError("Error", message)}`;
    console.error(m);
    if (shouldLogToDisk) logToDisk(m);
};

const logWarn = (message: string, e?: unknown) => {
    const m = `[warn] ${messageWithError(message, e)}`;
    console.error(m);
    if (shouldLogToDisk) logToDisk(m);
};

const logInfo = (...params: unknown[]) => {
    const message = params
        .map((p) => (typeof p == "string" ? p : JSON.stringify(p)))
        .join(" ");
    const m = `[info] ${message}`;
    if (isDevBuild || !shouldLogToDisk) console.log(m);
    if (shouldLogToDisk) logToDisk(m);
};

const logDebug = (param: () => unknown) => {
    if (isDevBuild) {
        const p = param();
        // Transform
        //     log.debug(() => ["tag", {x: y}])
        //     =>
        //     console.log("[debug] tag", {x: y})
        if (Array.isArray(p)) {
            // tseslint is not happy with us for destructuring any, but this is
            // non-production dev build only code, so silence it and go ahead.
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
            const [tag, ...rest] = p;
            // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
            console.log(`[debug] ${tag}`, ...rest);
        } else {
            /* Let console.log serialize it */
            console.log("[debug]", p);
        }
    }
};

/**
 * Ente's logger.
 *
 * This is an object that provides functions to log at the corresponding levels:
 * error, warn, info or debug.
 *
 * Whenever we need to save a log message to disk,
 *
 * - When running under electron these messages are saved to the log maintained
 *   by the electron app we're running under.
 *
 * - Otherwise such messages are written to a ring buffer in local storage.
 */
export default {
    /**
     * Log an error message with an optional associated error object.
     *
     * {@link e} is generally expected to be an `instanceof Error` but it can be
     * any arbitrary object that we obtain, say, when in a try-catch handler (in
     * JavaScript any arbitrary value can be thrown).
     *
     * If only one argument is specified, and it is not a string, then it is
     * taken as the error to be printed, paired with a generic message.
     *
     * The log is written to disk and printed to the browser console.
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
     * The log is written to disk. However, if logging to disk is disabled by
     * using {@link disableDiskLogs}, then the log is printed to the console.
     *
     * In development builds, the log is always printed to the browser console.
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
     * being logged. As a special case, arrays are spread, which allows one to
     * write `log.debug(() => ["tag", {x: y}])` and have that be printed as if
     * it were `console.log("[debug] tag", {x: y})`.
     *
     * This log is NOT written to disk. It is printed to the browser console,
     * but only in development builds.
     */
    debug: logDebug,
};
