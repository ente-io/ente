import { NormalizedFace } from '@tensorflow-models/blazeface';
import {
    FaceDetection,
    FaceLandmarks68,
    WithFaceDescriptor,
    WithFaceLandmarks,
} from 'face-api.js';

export interface MLSyncResult {
    allFaces: FaceWithEmbedding[];
    clustersWithNoise: ClustersWithNoise;
}

export interface AlignedFace extends NormalizedFace {
    alignedBox: [number, number, number, number];
}

export declare type FaceEmbedding = Array<number>;

export declare type FaceImage = Array<Array<Array<number>>>;

export declare type FaceApiResult = WithFaceDescriptor<
    WithFaceLandmarks<
        {
            detection: FaceDetection;
        },
        FaceLandmarks68
    >
>;

export declare type FaceDescriptor = Float32Array;

export declare type ClusterFaces = Array<number>;

export interface Cluster {
    faces: ClusterFaces;
    summary: FaceDescriptor;
}

export interface ClustersWithNoise {
    clusters: Array<Cluster>;
    noise: ClusterFaces;
}

export interface ClusteringResults {
    clusters: Array<ClusterFaces>;
    noise: ClusterFaces;
}

export interface NearestCluster {
    cluster: Cluster;
    distance: number;
}

export interface FaceWithEmbedding {
    fileId: string;
    face: FaceApiResult;
    // face: AlignedFace;
    // embedding: FaceEmbedding;
    faceImage: FaceImage;
}
