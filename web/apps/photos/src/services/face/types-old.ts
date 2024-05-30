import type { Box, Dimensions, Point } from "./types";

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
    fileId: number;
    faces?: Face[];
    imageDimensions?: Dimensions;
    mlVersion: number;
    errorCount: number;
}
