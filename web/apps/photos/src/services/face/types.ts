import { Box, Dimensions, Point } from "services/face/geom";
import { EnteFile } from "types/file";

export declare type Cluster = Array<number>;

export declare type Landmark = Point;

export interface FaceDetection {
    // box and landmarks is relative to image dimentions stored at mlFileData
    box: Box;
    landmarks?: Array<Landmark>;
    probability?: number;
}

export interface DetectedFace {
    fileId: number;
    detection: FaceDetection;
}

export interface DetectedFaceWithId extends DetectedFace {
    id: string;
}

export interface FaceCrop {
    image: ImageBitmap;
    // imageBox is relative to image dimentions stored at mlFileData
    imageBox: Box;
}

export interface StoredFaceCrop {
    cacheKey: string;
    imageBox: Box;
}

export interface CroppedFace extends DetectedFaceWithId {
    crop?: StoredFaceCrop;
}

export interface FaceAlignment {
    // TODO: remove affine matrix as rotation, size and center
    // are simple to store and use, affine matrix adds complexity while getting crop
    affineMatrix: Array<Array<number>>;
    rotation: number;
    // size and center is relative to image dimentions stored at mlFileData
    size: number;
    center: Point;
}

export interface AlignedFace extends CroppedFace {
    alignment?: FaceAlignment;
    blurValue?: number;
}

export declare type FaceEmbedding = Float32Array;

export interface FaceWithEmbedding extends AlignedFace {
    embedding?: FaceEmbedding;
}

export interface Face extends FaceWithEmbedding {
    personId?: number;
}

export interface Person {
    id: number;
    name?: string;
    files: Array<number>;
    displayFaceId?: string;
    faceCropCacheKey?: string;
}

export interface MlFileData {
    fileId: number;
    faces?: Face[];
    imageDimensions?: Dimensions;
    mlVersion: number;
    errorCount: number;
}

export interface MLSearchConfig {
    enabled: boolean;
}

export interface MLSyncFileContext {
    enteFile: EnteFile;
    localFile?: globalThis.File;

    oldMlFile?: MlFileData;
    newMlFile?: MlFileData;

    imageBitmap?: ImageBitmap;

    newDetection?: boolean;
    newAlignment?: boolean;
}

export declare type MLIndex = "files" | "people";
