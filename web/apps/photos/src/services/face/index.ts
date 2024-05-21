import { ComlinkWorker } from "@/next/worker/comlink-worker";
import type { DedicatedMLWorker } from "services/face/face.worker";

const createFaceWebWorker = () =>
    new Worker(new URL("face.worker.ts", import.meta.url));

export const createFaceComlinkWorker = (name: string) =>
    new ComlinkWorker<typeof DedicatedMLWorker>(name, createFaceWebWorker());
