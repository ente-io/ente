import type { Box, Point } from "./types";

export interface FaceDetection {
    // box and landmarks is relative to image dimentions stored at mlFileData
    box: Box;
    landmarks?: Point[];
}

export interface Face {
    faceID: string;
    detection: FaceDetection;
    score: number;
    blurValue?: number;

    embedding?: Float32Array;
}

export interface MlFileData {
    fileID: number;
    width: number;
    height: number;
    faceEmbedding: {
        version: number;
        client: string;
        faces: Face[];
    };
    mlVersion: number;
    errorCount: number;
}
