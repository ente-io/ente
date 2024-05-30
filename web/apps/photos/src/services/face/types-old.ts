import type { FaceIndex } from "./types";

export type MlFileData = FaceIndex & {
    mlVersion: number;
    errorCount: number;
};
