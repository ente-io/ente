/**
 * A subset of {@link Electron} provided to the {@link MLWorker}.
 *
 * `globalThis.electron` does not exist in the execution context of web workers.
 * So instead, we manually provide a proxy object of type
 * {@link MLWorkerElectron} that exposes a subset of the functions from
 * {@link Electron} that are needed by the code running in the ML web worker.
 */
export interface MLWorkerElectron {
    appVersion: () => Promise<string>;
    detectFaces: (input: Float32Array) => Promise<Float32Array>;
    computeFaceEmbeddings: (input: Float32Array) => Promise<Float32Array>;
    computeCLIPImageEmbedding: (input: Float32Array) => Promise<Float32Array>;
}
