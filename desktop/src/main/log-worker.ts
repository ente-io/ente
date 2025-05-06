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
    /**
     * Unlike the real {@link log.error}, this accepts only the first string
     * argument, not the second optional error one.
     */
    errorString: (s: string) => mainProcess("log.errorString", s),
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
