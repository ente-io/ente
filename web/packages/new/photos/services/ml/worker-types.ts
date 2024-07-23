/**
 * @file Type for the objects shared (as a Comlink proxy) by the main thread and
 * the ML worker.
 */

/**
 * A subset of {@link Electron} provided to the {@link MLWorker}.
 *
 * `globalThis.electron` does not exist in the execution context of web workers.
 * So instead, we manually provide a proxy object of type
 * {@link MLWorkerElectron} that exposes a subset of the functions from
 * {@link Electron} that are needed by the code running in the ML web worker.
 */
export interface MLWorkerElectron {
    detectFaces: (input: Float32Array) => Promise<Float32Array>;
    computeFaceEmbeddings: (input: Float32Array) => Promise<Float32Array>;
    computeCLIPImageEmbedding: (input: Float32Array) => Promise<Float32Array>;
}

/**
 * Callbacks invoked by the worker at various points in the indexing pipeline to
 * notify the main thread of events it might be interested in.
 */
export interface MLWorkerDelegate {
    /**
     * Called whenever a file is processed during indexing.
     *
     * It is called both when the indexing was successful or failed.
     */
    workerDidProcessFile: () => void;
}
