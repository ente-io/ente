/**
 * @file Main thread interface to {@link FaceWorker}.
 */

import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { FaceWorker } from "./worker";

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof FaceWorker> | undefined;

/** Lazily created, cached, instance of {@link FaceWorker}. */
export const faceWorker = async () =>
    (_comlinkWorker ??= createComlinkWorker()).remote;

const createComlinkWorker = () =>
    new ComlinkWorker<typeof FaceWorker>(
        "face",
        new Worker(new URL("worker.ts", import.meta.url)),
    );

/**
 * Terminate {@link faceWorker} (if any).
 *
 * This is useful during logout to immediately stop any background face related
 * operations that are in-flight for the current user. After the user logs in
 * again, a new {@link faceWorker} will be created on demand.
 */
export const terminateFaceWorker = () => {
    if (_comlinkWorker) {
        _comlinkWorker.terminate();
        _comlinkWorker = undefined;
    }
};
