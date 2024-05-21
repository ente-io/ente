import { Box, Dimensions, Point } from "services/face/geom";

export interface FaceDetection {
    // box and landmarks is relative to image dimentions stored at mlFileData
    box: Box;
    landmarks?: Point[];
    probability?: number;
}

export interface FaceAlignment {
    /**
     * An affine transformation matrix (rotation, translation, scaling) to align
     * the face extracted from the image.
     */
    affineMatrix: number[][];
    /**
     * The bounding box of the transformed box.
     *
     * The affine transformation shifts the original detection box a new,
     * transformed, box (possibily rotated). This property is the bounding box
     * of that transformed box. It is in the coordinate system of the original,
     * full, image on which the detection occurred.
     */
    boundingBox: Box;
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
