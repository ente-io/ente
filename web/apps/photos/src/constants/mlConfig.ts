import { JobConfig } from "types/common/job";
import { MLSearchConfig, MLSyncConfig } from "types/machineLearning";

export const DEFAULT_ML_SYNC_JOB_CONFIG: JobConfig = {
    intervalSec: 5,
    // TODO: finalize this after seeing effects on and from machine sleep
    maxItervalSec: 960,
    backoffMultiplier: 2,
};

export const DEFAULT_ML_SYNC_CONFIG: MLSyncConfig = {
    batchSize: 200,
    imageSource: "Original",
    faceDetection: {
        method: "YoloFace",
    },
    faceCrop: {
        enabled: true,
        method: "ArcFace",
        padding: 0.25,
        maxSize: 256,
        blobOptions: {
            type: "image/jpeg",
            quality: 0.8,
        },
    },
    faceAlignment: {
        method: "ArcFace",
    },
    blurDetection: {
        method: "Laplacian",
        threshold: 15,
    },
    faceEmbedding: {
        method: "MobileFaceNet",
        faceSize: 112,
        generateTsne: true,
    },
    faceClustering: {
        method: "Hdbscan",
        minClusterSize: 3,
        minSamples: 5,
        clusterSelectionEpsilon: 0.6,
        clusterSelectionMethod: "leaf",
        minInputSize: 50,
        // maxDistanceInsideCluster: 0.4,
        generateDebugInfo: true,
    },
    mlVersion: 3,
};

export const DEFAULT_ML_SEARCH_CONFIG: MLSearchConfig = {
    enabled: false,
};

export const MAX_ML_SYNC_ERROR_COUNT = 1;
