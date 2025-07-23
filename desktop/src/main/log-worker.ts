/**
 * A object that behaves similar to the default export of "./log", except this
 * can be used from within a utility process.
 *
 * ---
 *
 * We cannot directly do
 *
 *     import log from "../log";
 *
 * because that requires the Electron APIs that are not available to a utility
 * process (See: [Note: Using Electron APIs in UtilityProcess]).
 *
 * But even if that were to work, logging will still be problematic since we'd
 * try opening the log file from two different Node.js processes (this one, and
 * the main one), and I didn't find any indication in the electron-log
 * repository that the log file's integrity would be maintained in such cases.
 *
 * So instead we provide this proxy log object that uses the
 * `process.parentPort` to transport the logs over to the main process, where
 * the {@link processUtilityProcessLogMessage} function in the main process is
 * expected to handle these (sending them to the actual log).
 */
export default {
    error: (s: string, e?: unknown) =>
        mainProcess("log.errorString", messageWithError(s, e)),
    warn: (s: string, e?: unknown) =>
        mainProcess("log.warnString", messageWithError(s, e)),
    info: (...ms: unknown[]) => mainProcess("log.info", ms),
    /**
     * Unlike the real {@link log.debug}, this is (a) eagerly evaluated, and (b)
     * accepts only strings.
     */
    debugString: (s: string) => mainProcess("log.debugString", s),
};

/**
 * Send a message to the main process using a barebones RPC protocol.
 */
const mainProcess = (method: string, param: unknown) =>
    process.parentPort.postMessage({ method, p: param });

// Duplicated verbatim from ./log.ts
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
