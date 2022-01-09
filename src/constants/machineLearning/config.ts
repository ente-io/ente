import { MLSyncConfig } from 'types/machineLearning';
import { JobConfig } from 'utils/common/job';

export const DEFAULT_ML_SYNC_JOB_CONFIG: JobConfig = {
    intervalSec: 30,
    // TODO: finalize this after seeing effects on and from machine sleep
    maxItervalSec: 960,
    backoffMultiplier: 2,
};

export const DEFAULT_ML_SYNC_CONFIG: MLSyncConfig = {
    batchSize: 200,
    imageSource: 'Original',
    faceDetection: {
        method: 'BlazeFace',
        minFaceSize: 32,
    },
    faceCrop: {
        enabled: true,
        method: 'ArcFace',
        padding: 0.25,
        maxSize: 256,
        blobOptions: {
            type: 'image/jpeg',
            quality: 0.8,
        },
    },
    faceAlignment: {
        method: 'ArcFace',
    },
    faceEmbedding: {
        method: 'MobileFaceNet',
        faceSize: 112,
        generateTsne: true,
    },
    faceClustering: {
        method: 'Hdbscan',
        minClusterSize: 6,
        minSamples: 6,
        minInputSize: 50,
        // maxDistanceInsideCluster: 0.4,
        generateDebugInfo: true,
    },
    // tsne: {
    //     samples: 200,
    //     dim: 2,
    //     perplexity: 10.0,
    //     learningRate: 10.0,
    //     metric: 'euclidean',
    // },
    mlVersion: 2,
};
