import { File } from 'services/fileService';
import {
    ClusteringResults,
    ClustersWithNoise,
    Face,
    FaceAlignmentMethod,
    FaceAlignmentService,
    FaceDetectionMethod,
    FaceDetectionService,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    MLSyncConfig,
    MLSyncContext,
} from 'types/machineLearning';
import arcfaceAlignmentService from './arcfaceAlignmentService';
import blazeFaceDetectionService from './tfjsFaceDetectionService';
import mobileFaceNetEmbeddingService from './tfjsFaceEmbeddingService';

export class MLFactory {
    public static getFaceDetectionService(
        method: FaceDetectionMethod
    ): FaceDetectionService {
        if (method === 'BlazeFace') {
            return blazeFaceDetectionService;
        }

        throw Error('Unknon face detection method: ' + method);
    }

    public static getFaceAlignmentService(
        method: FaceAlignmentMethod
    ): FaceAlignmentService {
        if (method === 'ArcFace') {
            return arcfaceAlignmentService;
        }

        throw Error('Unknon face alignment method: ' + method);
    }

    public static getFaceEmbeddingService(
        method: FaceEmbeddingMethod
    ): FaceEmbeddingService {
        if (method === 'MobileFaceNet') {
            return mobileFaceNetEmbeddingService;
        }

        throw Error('Unknon face embedding method: ' + method);
    }

    public static getMLSyncContext(
        token: string,
        config: MLSyncConfig,
        shouldUpdateMLVersion: boolean = true
    ) {
        return new LocalMLSyncContext(token, config, shouldUpdateMLVersion);
    }
}

export class LocalMLSyncContext implements MLSyncContext {
    public token: string;
    public config: MLSyncConfig;
    public shouldUpdateMLVersion: boolean;

    public faceDetectionService: FaceDetectionService;
    public faceAlignmentService: FaceAlignmentService;
    public faceEmbeddingService: FaceEmbeddingService;

    public outOfSyncFiles: File[];
    public syncedFiles: File[];
    public syncedFaces: Face[];
    public allSyncedFacesMap?: Map<number, Array<Face>>;
    public faceClusteringResults?: ClusteringResults;
    public faceClustersWithNoise?: ClustersWithNoise;
    public tsne?: any;

    constructor(
        token: string,
        config: MLSyncConfig,
        shouldUpdateMLVersion: boolean = true
    ) {
        this.token = token;
        this.config = config;
        this.shouldUpdateMLVersion = shouldUpdateMLVersion;

        this.faceDetectionService = MLFactory.getFaceDetectionService(
            this.config.faceDetection.method
        );
        this.faceAlignmentService = MLFactory.getFaceAlignmentService(
            this.config.faceAlignment.method
        );
        this.faceEmbeddingService = MLFactory.getFaceEmbeddingService(
            this.config.faceEmbedding.method
        );

        this.outOfSyncFiles = [];
        this.syncedFiles = [];
        this.syncedFaces = [];
    }

    public async dispose() {
        await this.faceDetectionService.dispose();
        await this.faceEmbeddingService.dispose();
    }
}
