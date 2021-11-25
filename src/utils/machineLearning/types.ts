import * as tf from '@tensorflow/tfjs-core';

// import {
//     FaceDetection,
//     FaceLandmarks68,
//     WithFaceDescriptor,
//     WithFaceLandmarks,
// } from 'face-api.js';
import { DebugInfo } from 'hdbscan';

import { Point as D3Point, RawNodeDatum } from 'react-d3-tree/lib/types/common';
import { File } from 'services/fileService';
import { Box, Point } from '../../../thirdparty/face-api/classes';

export interface MLSyncResult {
    nFiles: number;
    nFaces: number;
    nClusters: number;
    nNoise: number;
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
    clustersWithNoise: ClustersWithNoise;
    tree: RawNodeDatum;
    tsne: TSNEData;
}

export declare type FaceEmbedding = Array<number>;

export declare type FaceImage = Array<Array<Array<number>>>;

// export declare type FaceApiResult = WithFaceDescriptor<
//     WithFaceLandmarks<
//         {
//             detection: FaceDetection;
//         },
//         FaceLandmarks68
//     >
// >;

export declare type FaceDescriptor = Float32Array;

export declare type ClusterFaces = Array<number>;

export interface Cluster {
    faces: ClusterFaces;
    summary?: FaceDescriptor;
}

export interface ClustersWithNoise {
    clusters: Array<Cluster>;
    noise: ClusterFaces;
}

export interface ClusteringResults {
    clusters: Array<ClusterFaces>;
    noise: ClusterFaces;
}

export interface HdbscanResults extends ClusteringResults {
    debugInfo?: DebugInfo;
}

export interface NearestCluster {
    cluster: Cluster;
    distance: number;
}

export interface TSNEData {
    width: number;
    height: number;
    dataset: D3Point[];
}

export declare type Landmark = Point;

export declare type FaceDetectionMethod = 'BlazeFace' | 'FaceApiSSD';

export declare type FaceAlignmentMethod =
    | 'ArcFace'
    | 'FaceApiDlib'
    | 'RotatedFaceApiDlib';

export declare type FaceEmbeddingMethod = 'MobileFaceNet' | 'FaceApiDlib';

export declare type FaceClusteringMethod = 'Hdbscan' | 'Dbscan';

export class AlignedBox {
    box: Box;
    rotation: number;
}

export interface Versioned<T> {
    value: T;
    version: number;
}

export interface DetectedFace {
    box: Box;
    landmarks: Array<Landmark>;
    probability?: number;
    detectionMethod: Versioned<FaceDetectionMethod>;
}

export interface AlignedFace extends DetectedFace {
    affineMatrix: Array<Array<number>>;
    alignmentMethod: Versioned<FaceAlignmentMethod>;
}

export interface FaceWithEmbedding extends AlignedFace {
    embedding: FaceEmbedding;
    embeddingMethod: Versioned<FaceEmbeddingMethod>;
}

export interface Face extends FaceWithEmbedding {
    fileId: number;
    personId?: number;
}

export interface MlFileData {
    fileId: number;
    faces: Face[];
    mlVersion: number;
}

export interface FaceDetectionConfig {
    method: Versioned<FaceDetectionMethod>;
    minFaceSize: number;
}

export interface FaceAlignmentConfig {
    method: Versioned<FaceAlignmentMethod>;
}

export interface FaceEmbeddingConfig {
    method: Versioned<FaceEmbeddingMethod>;
    faceSize: number;
    generateTsne?: boolean;
}

export interface FaceClusteringConfig {
    method: Versioned<FaceClusteringMethod>;
    minClusterSize: number;
    clusterFaceDistance?: number;
    generateDebugInfo?: boolean;
}

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
    batchSize: number;
    faceDetection: FaceDetectionConfig;
    faceAlignment: FaceAlignmentConfig;
    faceEmbedding: FaceEmbeddingConfig;
    faceClustering: FaceClusteringConfig;
    tsne?: TSNEConfig;
    mlVersion: number;
}

export class MLSyncContext {
    token: string;
    config: MLSyncConfig;

    files?: File[];
    faces?: Face[];
    clusteringResults?: HdbscanResults;
    clustersWithNoise?: ClustersWithNoise;
    tsne?: any;

    constructor(token, config) {
        this.token = token;
        this.config = config;
    }
}

export interface FaceDetectionService {
    detectFaces(image: tf.Tensor3D): Promise<Array<DetectedFace>>;
}

export interface FaceAlignmentService {
    getAlignedFaces(faces: Array<DetectedFace>): Array<AlignedFace>;
}

export interface FaceEmbeddingService {
    getFaceEmbeddings(
        image: tf.Tensor3D,
        faces: Array<AlignedFace>
    ): Promise<Array<FaceWithEmbedding>>;
}
