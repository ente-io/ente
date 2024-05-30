import type { Box, Point } from "./types";

export interface FaceDetection {
    // box and landmarks is relative to image dimentions stored at mlFileData
    box: Box;
    landmarks?: Point[];
    probability?: number;
}

export interface Face {
    fileId: number;
    detection: FaceDetection;
    id: string;
    blurValue?: number;

    embedding?: Float32Array;
}

export interface MlFileData {
    fileID: number;
    faces?: Face[];
    width: number;
    height: number;
    faceEmbedding: {
        version: number;
    };
    mlVersion: number;
    errorCount: number;
}
