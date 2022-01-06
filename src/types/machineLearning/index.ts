import * as tf from '@tensorflow/tfjs-core';

// import {
//     FaceDetection,
//     FaceLandmarks68,
//     WithFaceDescriptor,
//     WithFaceLandmarks,
// } from 'face-api.js';
import { DebugInfo } from 'hdbscan';
import PQueue from 'p-queue';

import { Point as D3Point, RawNodeDatum } from 'react-d3-tree/lib/types/common';
import { File } from 'services/fileService';
import { Dimensions } from 'types/image';
import { Box, Point } from '../../../thirdparty/face-api/classes';

export interface MLSyncResult {
    nOutOfSyncFiles: number;
    nSyncedFiles: number;
    nSyncedFaces: number;
    nFaceClusters: number;
    nFaceNoise: number;
    tsne?: any;
}

export interface DebugFace {
    fileId: string;
    // face: FaceApiResult;
    face: AlignedFace;
    embedding: FaceEmbedding;
    faceImage: FaceImage;
}

export interface MLDebugResult {
    allFaces: DebugFace[];
    clustersWithNoise: FacesClustersWithNoise;
    tree: RawNodeDatum;
    tsne: TSNEData;
}

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

export interface TSNEData {
    width: number;
    height: number;
    dataset: D3Point[];
}

export declare type Landmark = Point;

export declare type ImageType = 'Original' | 'Preview';

export declare type FaceDetectionMethod = 'BlazeFace' | 'FaceApiSSD';

export declare type FaceCropMethod = 'ArcFace';

export declare type FaceAlignmentMethod =
    | 'ArcFace'
    | 'FaceApiDlib'
    | 'RotatedFaceApiDlib';

export declare type FaceEmbeddingMethod = 'MobileFaceNet' | 'FaceApiDlib';

export declare type ClusteringMethod = 'Hdbscan' | 'Dbscan';

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

export const FACE_CROPS_CACHE_NAME = 'face-crops';

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

export declare type FaceEmbedding = Array<number>;

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
    faceImage: FaceImageBlob;
}

export interface MlFileData {
    fileId: number;
    faces?: Face[];
    imageSource?: ImageType;
    imageDimentions?: Dimensions;
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
    minFaceSize: number;
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

export declare type TSNEMetric = 'euclidean' | 'manhattan';

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
    syncIntervalSec: number;
    maxSyncIntervalSec: number;
    batchSize: number;
    imageSource: ImageType;
    faceDetection: FaceDetectionConfig;
    faceCrop: FaceCropConfig;
    faceAlignment: FaceAlignmentConfig;
    faceEmbedding: FaceEmbeddingConfig;
    faceClustering: FaceClusteringConfig;
    tsne?: TSNEConfig;
    mlVersion: number;
}

export interface MLSyncContext {
    token: string;
    config: MLSyncConfig;
    shouldUpdateMLVersion: boolean;

    faceDetectionService: FaceDetectionService;
    faceCropService: FaceCropService;
    faceAlignmentService: FaceAlignmentService;
    faceEmbeddingService: FaceEmbeddingService;
    faceClusteringService: ClusteringService;

    localFilesMap: Map<number, File>;
    outOfSyncFiles: File[];
    syncedFiles: File[];
    syncedFaces: Face[];
    allSyncedFacesMap?: Map<number, Array<Face>>;
    tsne?: any;

    // oldMLLibraryData: MLLibraryData;
    mlLibraryData: MLLibraryData;

    syncQueue: PQueue;

    getEnteWorker(id: number): Promise<any>;
}

export interface MLSyncFileContext {
    enteFile: File;
    localFile?: globalThis.File;

    oldMLFileData?: MlFileData;
    newMLFileData?: MlFileData;

    tfImage?: tf.Tensor3D;
    imageBitmap?: ImageBitmap;

    newDetection?: boolean;
    newAlignment?: boolean;

    faces?: Array<Face>;
}

export interface MLLibraryData {
    faceClusteringMethod?: Versioned<ClusteringMethod>;
    faceClusteringResults?: ClusteringResults;
    faceClustersWithNoise?: FacesClustersWithNoise;
}

export declare type MLIndex = 'files' | 'people';

export const BLAZEFACE_MAX_FACES = 20;
export const BLAZEFACE_INPUT_SIZE = 256;
export const BLAZEFACE_IOU_THRESHOLD = 0.3;
export const BLAZEFACE_SCORE_THRESHOLD = 0.7;
export const BLAZEFACE_PASS1_SCORE_THRESHOLD = 0.4;
export const BLAZEFACE_FACE_SIZE = 112;

export interface FaceDetectionService {
    method: Versioned<FaceDetectionMethod>;
    // init(): Promise<void>;
    detectFaces(image: ImageBitmap): Promise<Array<FaceDetection>>;
    dispose(): Promise<void>;
}

export interface FaceCropService {
    method: Versioned<FaceCropMethod>;

    getFaceCrop(
        imageBitmap: ImageBitmap,
        face: FaceDetection,
        config: FaceCropConfig
    ): Promise<FaceCrop>;
}

export interface FaceAlignmentService {
    method: Versioned<FaceAlignmentMethod>;
    getFaceAlignment(faceDetection: FaceDetection): FaceAlignment;
}

export interface FaceEmbeddingService {
    method: Versioned<FaceEmbeddingMethod>;
    // init(): Promise<void>;
    getFaceEmbeddings(
        image: ImageBitmap,
        faces: Array<AlignedFace>
    ): Promise<Array<FaceEmbedding>>;
    dispose(): Promise<void>;
}

export interface ClusteringService {
    method: Versioned<ClusteringMethod>;

    cluster(
        input: ClusteringInput,
        config: ClusteringConfig
    ): Promise<ClusteringResults>;
}

export interface ClusteringConfig {
    method: ClusteringMethod;
    minClusterSize: number;
    maxDistanceInsideCluster?: number;
    minInputSize?: number;
    generateDebugInfo?: boolean;
}

export declare type ClusteringInput = Array<Array<number>>;

export interface MachineLearningWorker {
    syncLocalFile(
        token: string,
        enteFile: File,
        localFile: globalThis.File,
        config?: MLSyncConfig
    ): Promise<MlFileData>;

    sync(token: string): Promise<MLSyncResult>;

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
