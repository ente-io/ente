import { DebugInfo } from "hdbscan";
import PQueue from "p-queue";
import { EnteFile } from "types/file";
import { Dimensions } from "types/image";
import { Box, Point } from "../../../thirdparty/face-api/classes";

export interface MLSyncResult {
    nOutOfSyncFiles: number;
    nSyncedFiles: number;
    nSyncedFaces: number;
    nFaceClusters: number;
    nFaceNoise: number;
    error?: Error;
}

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

export declare type Landmark = Point;

export declare type ImageType = "Original" | "Preview";

export declare type FaceDetectionMethod = "YoloFace";

export declare type FaceCropMethod = "ArcFace";

export declare type FaceAlignmentMethod = "ArcFace";

export declare type FaceEmbeddingMethod = "MobileFaceNet";

export declare type BlurDetectionMethod = "Laplacian";

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
    imageSource?: ImageType;
    imageDimensions?: Dimensions;
    faceDetectionMethod?: Versioned<FaceDetectionMethod>;
    faceCropMethod?: Versioned<FaceCropMethod>;
    faceAlignmentMethod?: Versioned<FaceAlignmentMethod>;
    faceEmbeddingMethod?: Versioned<FaceEmbeddingMethod>;
    mlVersion: number;
    errorCount: number;
    lastErrorMessage?: string;
}

export interface FaceDetectionConfig {
    method: FaceDetectionMethod;
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

export interface BlurDetectionConfig {
    method: BlurDetectionMethod;
    threshold: number;
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
    blurDetection: BlurDetectionConfig;
    faceEmbedding: FaceEmbeddingConfig;
    faceClustering: FaceClusteringConfig;
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
    blurDetectionService: BlurDetectionService;
    faceClusteringService: ClusteringService;

    localFilesMap: Map<number, EnteFile>;
    outOfSyncFiles: EnteFile[];
    nSyncedFiles: number;
    nSyncedFaces: number;
    allSyncedFacesMap?: Map<number, Array<Face>>;

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

    detectFaces(image: ImageBitmap): Promise<Array<FaceDetection>>;
    getRelativeDetection(
        faceDetection: FaceDetection,
        imageDimensions: Dimensions,
    ): FaceDetection;
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

    getFaceEmbeddings(faceImages: Float32Array): Promise<Array<FaceEmbedding>>;
}

export interface BlurDetectionService {
    method: Versioned<BlurDetectionMethod>;
    detectBlur(alignedFaces: Float32Array): number[];
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
