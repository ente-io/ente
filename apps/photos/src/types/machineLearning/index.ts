import * as tf from "@tensorflow/tfjs-core";

// import {
//     FaceDetection,
//     FaceLandmarks68,
//     WithFaceDescriptor,
//     WithFaceLandmarks,
// } from 'face-api.js';
import { DebugInfo } from "hdbscan";
import PQueue from "p-queue";

// import { Point as D3Point, RawNodeDatum } from 'react-d3-tree/lib/types/common';
import { EnteFile } from "types/file";
import { Dimensions } from "types/image";
import { Box, Point } from "../../../thirdparty/face-api/classes";

export interface MLSyncResult {
    nOutOfSyncFiles: number;
    nSyncedFiles: number;
    nSyncedFaces: number;
    nFaceClusters: number;
    nFaceNoise: number;
    tsne?: any;
    error?: Error;
}

export interface DebugFace {
    fileId: string;
    // face: FaceApiResult;
    face: AlignedFace;
    embedding: FaceEmbedding;
    faceImage: FaceImage;
}

// export interface MLDebugResult {
//     allFaces: DebugFace[];
//     clustersWithNoise: FacesClustersWithNoise;
//     tree: RawNodeDatum;
//     tsne: TSNEData;
// }

export declare type FaceImage = Array<Array<Array<number>>>;
export declare type FaceImageBlob = Blob;

// export declare type FaceApiResult = WithFaceDescriptor<
//     WithFaceLandmarks<
//         {
//             detection: FaceDetection;
//         },
//         FaceLandmarks68
//     >
// >;

export declare type FaceDescriptor = Float32Array;

export declare type Cluster = Array<number>;

export interface ClusteringResults {
    clusters: Array<Cluster>;
    noise: Cluster;
}

export interface HdbscanResults extends ClusteringResults {
    debugInfo?: DebugInfo;
}

export interface FacesCluster {
    faces: Cluster;
    summary?: FaceDescriptor;
}

export interface FacesClustersWithNoise {
    clusters: Array<FacesCluster>;
    noise: Cluster;
}

export interface NearestCluster {
    cluster: FacesCluster;
    distance: number;
}

// export interface TSNEData {
//     width: number;
//     height: number;
//     dataset: D3Point[];
// }

export declare type Landmark = Point;

export declare type ImageType = "Original" | "Preview";

export declare type FaceDetectionMethod = "BlazeFace" | "FaceApiSSD";

export declare type ObjectDetectionMethod = "SSDMobileNetV2";

export declare type SceneDetectionMethod = "ImageScene";

export declare type FaceCropMethod = "ArcFace";

export declare type FaceAlignmentMethod =
    | "ArcFace"
    | "FaceApiDlib"
    | "RotatedFaceApiDlib";

export declare type FaceEmbeddingMethod = "MobileFaceNet" | "FaceApiDlib";

export declare type ClusteringMethod = "Hdbscan" | "Dbscan";

export class AlignedBox {
    box: Box;
    rotation: number;
}

export interface Versioned<T> {
    value: T;
    version: number;
}

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
    imageUrl: string;
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
    displayImageUrl?: string;
}

export interface ObjectDetection {
    bbox: [number, number, number, number];
    class: string;
    score: number;
}

export interface DetectedObject {
    fileID: number;
    detection: ObjectDetection;
}

export interface RealWorldObject extends DetectedObject {
    id: string;
    className: string;
}

export interface Thing {
    id: number;
    name: string;
    files: Array<number>;
}

export interface WordGroup {
    word: string;
    files: Array<number>;
}

export interface MlFileData {
    fileId: number;
    faces?: Face[];
    objects?: RealWorldObject[];
    imageSource?: ImageType;
    imageDimensions?: Dimensions;
    faceDetectionMethod?: Versioned<FaceDetectionMethod>;
    faceCropMethod?: Versioned<FaceCropMethod>;
    faceAlignmentMethod?: Versioned<FaceAlignmentMethod>;
    faceEmbeddingMethod?: Versioned<FaceEmbeddingMethod>;
    objectDetectionMethod?: Versioned<ObjectDetectionMethod>;
    sceneDetectionMethod?: Versioned<SceneDetectionMethod>;
    mlVersion: number;
    errorCount: number;
    lastErrorMessage?: string;
}

export interface FaceDetectionConfig {
    method: FaceDetectionMethod;
    minFaceSize: number;
}

export interface ObjectDetectionConfig {
    method: ObjectDetectionMethod;
    maxNumBoxes: number;
    minScore: number;
}

export interface SceneDetectionConfig {
    method: SceneDetectionMethod;
    minScore: number;
}

export interface FaceCropConfig {
    enabled: boolean;
    method: FaceCropMethod;
    padding: number;
    maxSize: number;
    blobOptions: {
        type: string;
        quality: number;
    };
}

export interface FaceAlignmentConfig {
    method: FaceAlignmentMethod;
}

export interface FaceEmbeddingConfig {
    method: FaceEmbeddingMethod;
    faceSize: number;
    generateTsne?: boolean;
}

export interface FaceClusteringConfig extends ClusteringConfig {}

export declare type TSNEMetric = "euclidean" | "manhattan";

export interface TSNEConfig {
    samples: number;
    dim: number;
    perplexity?: number;
    earlyExaggeration?: number;
    learningRate?: number;
    nIter?: number;
    metric?: TSNEMetric;
}

export interface MLSyncConfig {
    batchSize: number;
    imageSource: ImageType;
    faceDetection: FaceDetectionConfig;
    faceCrop: FaceCropConfig;
    faceAlignment: FaceAlignmentConfig;
    faceEmbedding: FaceEmbeddingConfig;
    faceClustering: FaceClusteringConfig;
    objectDetection: ObjectDetectionConfig;
    sceneDetection: SceneDetectionConfig;
    tsne?: TSNEConfig;
    mlVersion: number;
}

export interface MLSearchConfig {
    enabled: boolean;
}

export interface MLSyncContext {
    token: string;
    userID: number;
    config: MLSyncConfig;
    shouldUpdateMLVersion: boolean;

    faceDetectionService: FaceDetectionService;
    faceCropService: FaceCropService;
    faceAlignmentService: FaceAlignmentService;
    faceEmbeddingService: FaceEmbeddingService;
    faceClusteringService: ClusteringService;
    objectDetectionService: ObjectDetectionService;
    sceneDetectionService: SceneDetectionService;

    localFilesMap: Map<number, EnteFile>;
    outOfSyncFiles: EnteFile[];
    nSyncedFiles: number;
    nSyncedFaces: number;
    allSyncedFacesMap?: Map<number, Array<Face>>;
    allSyncedObjectsMap?: Map<number, Array<RealWorldObject>>;
    tsne?: any;

    error?: Error;

    // oldMLLibraryData: MLLibraryData;
    mlLibraryData: MLLibraryData;

    syncQueue: PQueue;

    getEnteWorker(id: number): Promise<any>;
    dispose(): Promise<void>;
}

export interface MLSyncFileContext {
    enteFile: EnteFile;
    localFile?: globalThis.File;

    oldMlFile?: MlFileData;
    newMlFile?: MlFileData;

    tfImage?: tf.Tensor3D;
    imageBitmap?: ImageBitmap;

    newDetection?: boolean;
    newAlignment?: boolean;
}

export interface MLLibraryData {
    faceClusteringMethod?: Versioned<ClusteringMethod>;
    faceClusteringResults?: ClusteringResults;
    faceClustersWithNoise?: FacesClustersWithNoise;
}

export declare type MLIndex = "files" | "people";

export interface FaceDetectionService {
    method: Versioned<FaceDetectionMethod>;
    // init(): Promise<void>;
    detectFaces(image: ImageBitmap): Promise<Array<FaceDetection>>;
    dispose(): Promise<void>;
}

export interface ObjectDetectionService {
    method: Versioned<ObjectDetectionMethod>;
    // init(): Promise<void>;
    detectObjects(
        image: ImageBitmap,
        maxNumBoxes: number,
        minScore: number,
    ): Promise<ObjectDetection[]>;
    dispose(): Promise<void>;
}

export interface SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    // init(): Promise<void>;
    detectScenes(
        image: ImageBitmap,
        minScore: number,
    ): Promise<ObjectDetection[]>;
}

export interface FaceCropService {
    method: Versioned<FaceCropMethod>;

    getFaceCrop(
        imageBitmap: ImageBitmap,
        face: FaceDetection,
        config: FaceCropConfig,
    ): Promise<FaceCrop>;
}

export interface FaceAlignmentService {
    method: Versioned<FaceAlignmentMethod>;
    getFaceAlignment(faceDetection: FaceDetection): FaceAlignment;
}

export interface FaceEmbeddingService {
    method: Versioned<FaceEmbeddingMethod>;
    faceSize: number;
    // init(): Promise<void>;
    getFaceEmbeddings(
        faceImages: Array<ImageBitmap>,
    ): Promise<Array<FaceEmbedding>>;
    dispose(): Promise<void>;
}

export interface ClusteringService {
    method: Versioned<ClusteringMethod>;

    cluster(
        input: ClusteringInput,
        config: ClusteringConfig,
    ): Promise<ClusteringResults>;
}

export interface ClusteringConfig {
    method: ClusteringMethod;
    minClusterSize: number;
    minSamples?: number;
    clusterSelectionEpsilon?: number;
    clusterSelectionMethod?: "eom" | "leaf";
    maxDistanceInsideCluster?: number;
    minInputSize?: number;
    generateDebugInfo?: boolean;
}

export declare type ClusteringInput = Array<Array<number>>;

export interface MachineLearningWorker {
    closeLocalSyncContext(): Promise<void>;

    syncLocalFile(
        token: string,
        userID: number,
        enteFile: EnteFile,
        localFile: globalThis.File,
    ): Promise<MlFileData | Error>;

    sync(token: string, userID: number): Promise<MLSyncResult>;

    close(): void;
}

// export class TFImageBitmap {
//     imageBitmap: ImageBitmap;
//     tfImage: tf.Tensor3D;

//     constructor(imageBitmap: ImageBitmap, tfImage: tf.Tensor3D) {
//         this.imageBitmap = imageBitmap;
//         this.tfImage = tfImage;
//     }

//     async dispose() {
//         this.tfImage && (await tf.dispose(this.tfImage));
//         this.imageBitmap && this.imageBitmap.close();
//     }
// }
