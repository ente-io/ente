import { wrap } from "comlink";
import { inWorker } from "../env";
import type { WorkerBridge } from "./comlink-worker";

/**
 * The web worker side handle to the {@link WorkerBridge} exposed by the main
 * thread.
 *
 * This file is meant to be run inside a worker. Accessing the properties of
 * this object will be transparently (but asynchrorously) relayed to the
 * implementation of the {@link WorkerBridge} in `comlink-worker.ts`.
 */
export const workerBridge = inWorker()
    ? wrap<WorkerBridge>(globalThis)
    : undefined;
