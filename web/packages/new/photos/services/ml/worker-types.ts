/**
 * @file Types for the objects shared between the main thread and the ML worker.
 */

/**
 * Callbacks invoked by the worker at various points in the indexing pipeline to
 * notify the main thread of events it might be interested in.
 */
export interface MLWorkerDelegate {
    /**
     * Called whenever the worker processes a file during indexing (either
     * successfully or with errors), or when in goes into the "idle" state.
     */
    workerDidProcessFileOrIdle: () => void;
}

/**
 * The result of file ids that should be considered as matches for a particular
 * search phrase, each with their associated score.
 *
 * This is a map of file (IDs) that should be shown in the search results.
 * They're returned as a map from fileIDs to the scores they got (higher is
 * better). This map will only contains entries whose score was above our
 * minimum threshold.
 */
export type CLIPMatches = Map<number, number>;
