import { NormalizedFace } from '@tensorflow-models/blazeface';
import {
    FaceDetection,
    FaceLandmarks68,
    WithFaceDescriptor,
    WithFaceLandmarks,
} from 'face-api.js';

export interface MLSyncResult {
    allFaces: FaceWithEmbedding[];
    clusterResults: ClusteringResults;
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

export interface FaceWithEmbedding {
    fileId: string;
    face: FaceApiResult;
    // face: AlignedFace;
    // embedding: FaceEmbedding;
    faceImage: FaceImage;
}

export declare type Cluster = Array<number>;

export interface ClusteringResults {
    clusters: Cluster[];
    noise: Cluster;
}
