import { ComlinkWorker } from "@/next/worker/comlink-worker";
import type { DedicatedHEICConvertWorker } from "./heic-convert.worker";

export const createHEICConvertWebWorker = () =>
    new Worker(new URL("heic-convert.worker.ts", import.meta.url));

export const createHEICConvertComlinkWorker = () =>
    new ComlinkWorker<typeof DedicatedHEICConvertWorker>(
        "heic-convert-worker",
        createHEICConvertWebWorker(),
    );
