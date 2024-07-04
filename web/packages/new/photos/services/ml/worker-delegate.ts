/**
 * Callback functions made available to the ML worker.
 *
 * These primarily allow the worker code to access the functions exposed by our
 * desktop app. Normally code accesses this via `globalThis.electron`, but that
 * doesn't exist in the execution context of web workers.
 *
 * As such, this is currently a subset of {@link Electron}.
 */
export interface MLWorkerDelegate {
    appVersion: () => Promise<string>;
    detectFaces: (input: Float32Array) => Promise<Float32Array>;
    computeFaceEmbeddings: (input: Float32Array) => Promise<Float32Array>;
}
