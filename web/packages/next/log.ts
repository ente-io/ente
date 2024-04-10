import { inWorker } from "@/next/env";
import { isDevBuild } from "./env";
import { logToDisk as webLogToDisk } from "./log-web";
import { workerBridge } from "./worker/worker-bridge";

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
    workerBridge.logToDisk(message).catch((e) => {
        console.error(
            "Failed to log a message from worker",
            e,
            "\nThe message was",
            message,
        );
    });
};

const logError = (message: string, e?: unknown) => {
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
    const m = `[error] ${message}`;
    if (isDevBuild) console.error(m);
    logToDisk(m);
};

const logInfo = (...params: unknown[]) => {
    const message = params
        .map((p) => (typeof p == "string" ? p : JSON.stringify(p)))
        .join(" ");
    const m = `[info] ${message}`;
    if (isDevBuild) console.log(m);
    logToDisk(m);
};

const logDebug = (param: () => unknown) => {
    if (isDevBuild) console.log("[debug]", param());
};

/**
 * Ente's logger.
 *
 * This is an object that provides three functions to log at the corresponding
 * levels - error, info or debug.
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
     * The log is written to disk. In development builds, the log is also
     * printed to the browser console.
     */
    error: logError,
    /**
     * Log a message.
     *
     * This is meant as a replacement of {@link console.log}, and takes an
     * arbitrary number of arbitrary parameters that it then serializes.
     *
     * The log is written to disk. In development builds, the log is also
     * printed to the browser console.
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
     * This log is NOT written to disk. And it is printed to the browser
     * console, but only in development builds.
     */
    debug: logDebug,
};
