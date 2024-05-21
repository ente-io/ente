import { Box, Dimensions, Point } from "services/face/geom";

export interface FaceDetection {
    // box and landmarks is relative to image dimentions stored at mlFileData
    box: Box;
    landmarks?: Point[];
    probability?: number;
}

export interface FaceAlignment {
    // An affine transformation matrix (rotation, translation, scaling) to align
    // the face extracted from the image.
    affineMatrix: number[][];
    // size and center is relative to image dimentions stored at mlFileData
    size: number;
    center: Point;
}

export interface Face {
    fileId: number;
    detection: FaceDetection;
    id: string;

    alignment?: FaceAlignment;
    blurValue?: number;

    embedding?: Float32Array;

    personId?: number;
}

export interface MlFileData {
    fileId: number;
    faces?: Face[];
    imageDimensions?: Dimensions;
    mlVersion: number;
    errorCount: number;
}
