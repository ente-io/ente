/**
 * @file Types for the objects shared (as a Comlink proxy) by the main thread
 * and the ML worker.
 */

/**
 * Callbacks invoked by the worker at various points in the indexing pipeline to
 * notify the main thread of events it might be interested in.
 */
export interface MLWorkerDelegate {
    /**
     * Called whenever a file is processed during indexing.
     *
     * It is called both when the indexing was successful or it failed.
     */
    workerDidProcessFile: () => void;
}
