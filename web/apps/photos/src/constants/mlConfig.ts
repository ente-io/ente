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
        method: "BlazeFace",
        minFaceSize: 32,
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
    objectDetection: {
        method: "SSDMobileNetV2",
        maxNumBoxes: 20,
        minScore: 0.2,
    },
    sceneDetection: {
        method: "ImageScene",
        minScore: 0.1,
    },
    // tsne: {
    //     samples: 200,
    //     dim: 2,
    //     perplexity: 10.0,
    //     learningRate: 10.0,
    //     metric: 'euclidean',
    // },
    mlVersion: 3,
};

export const DEFAULT_ML_SEARCH_CONFIG: MLSearchConfig = {
    enabled: false,
};

export const ML_SYNC_DOWNLOAD_TIMEOUT_MS = 300000;

export const MAX_FACE_DISTANCE_PERCENT = Math.sqrt(2) / 100;

export const MAX_ML_SYNC_ERROR_COUNT = 4;

export const TEXT_DETECTION_TIMEOUT_MS = [10000, 30000, 60000, 120000, 240000];

export const BLAZEFACE_MAX_FACES = 50;
export const BLAZEFACE_INPUT_SIZE = 256;
export const BLAZEFACE_IOU_THRESHOLD = 0.3;
export const BLAZEFACE_SCORE_THRESHOLD = 0.75;
export const BLAZEFACE_PASS1_SCORE_THRESHOLD = 0.4;
export const BLAZEFACE_FACE_SIZE = 112;
export const MOBILEFACENET_FACE_SIZE = 112;

// scene detection model takes fixed-shaped (224x224) inputs
// https://tfhub.dev/sayannath/lite-model/image-scene/1
export const SCENE_DETECTION_IMAGE_SIZE = 224;

// SSD with Mobilenet v2 initialized from Imagenet classification checkpoint. Trained on COCO 2017 dataset (images scaled to 320x320 resolution).
// https://tfhub.dev/tensorflow/ssd_mobilenet_v2/2
export const OBJECT_DETECTION_IMAGE_SIZE = 320;

export const BATCHES_BEFORE_SYNCING_INDEX = 5;
