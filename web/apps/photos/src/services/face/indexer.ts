import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { type Remote } from "comlink";
import { FaceIndexerWorker } from "./indexer.worker";

/**
 * A promise for the lazily created singleton {@link FaceIndexerWorker} remote
 * exposed by this module.
 */
let _faceIndexer: Promise<Remote<FaceIndexerWorker>>;

const createFaceIndexerComlinkWorker = () =>
    new ComlinkWorker<typeof FaceIndexerWorker>(
        "face-indexer",
        new Worker(new URL("indexer.worker.ts", import.meta.url)),
    );

/**
 * Main thread interface to the face indexer.
 *
 * This function provides a promise that resolves to a lazily created singleton
 * remote with a {@link FaceIndexerWorker} at the other end.
 */
export const faceIndexer = (): Promise<Remote<FaceIndexerWorker>> =>
    (_faceIndexer ??= createFaceIndexerComlinkWorker().remote);
