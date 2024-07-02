/**
 * @file Main thread interface to {@link MLWorker}.
 */

import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { MLWorker } from "./worker";

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof MLWorker> | undefined;

/** Lazily created, cached, instance of {@link MLWorker}. */
export const worker = async () =>
    (_comlinkWorker ??= createComlinkWorker()).remote;

const createComlinkWorker = () =>
    new ComlinkWorker<typeof MLWorker>(
        "ml",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Terminate {@link worker} (if any).
 *
 * This is useful during logout to immediately stop any background ML operations
 * that are in-flight for the current user. After the user logs in again, a new
 * {@link worker} will be created on demand for subsequent usage.
 */
export const terminateMLWorker = () => {
    if (_comlinkWorker) {
        _comlinkWorker.terminate();
        _comlinkWorker = undefined;
    }
};
