import PQueue from 'p-queue';
import { File } from 'services/fileService';
import {
    Face,
    FaceAlignmentMethod,
    FaceAlignmentService,
    FaceCropMethod,
    FaceCropService,
    FaceDetectionMethod,
    FaceDetectionService,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    MLSyncConfig,
    MLSyncContext,
    ClusteringMethod,
    ClusteringService,
    MLLibraryData,
} from 'types/machineLearning';
import { CONCURRENCY } from 'utils/common/concurrency';
import { ComlinkWorker, getDedicatedCryptoWorker } from 'utils/crypto';
import { logQueueStats } from 'utils/machineLearning';
import arcfaceAlignmentService from './arcfaceAlignmentService';
import arcfaceCropService from './arcfaceCropService';
import hdbscanClusteringService from './hdbscanClusteringService';
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

    public static getFaceCropService(method: FaceCropMethod) {
        if (method === 'ArcFace') {
            return arcfaceCropService;
        }

        throw Error('Unknon face crop method: ' + method);
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

    public static getClusteringService(
        method: ClusteringMethod
    ): ClusteringService {
        if (method === 'Hdbscan') {
            return hdbscanClusteringService;
        }

        throw Error('Unknon clustering method: ' + method);
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
    public faceCropService: FaceCropService;
    public faceAlignmentService: FaceAlignmentService;
    public faceEmbeddingService: FaceEmbeddingService;
    public faceClusteringService: ClusteringService;

    public outOfSyncFiles: File[];
    public syncedFiles: File[];
    public syncedFaces: Face[];
    public allSyncedFacesMap?: Map<number, Array<Face>>;
    public tsne?: any;

    public mlLibraryData: MLLibraryData;

    public syncQueue: PQueue;
    // TODO: wheather to limit concurrent downloads
    // private downloadQueue: PQueue;

    private concurrancy: number;
    private enteComlinkWorkers: Array<ComlinkWorker>;
    private enteWorkers: Array<any>;

    constructor(
        token: string,
        config: MLSyncConfig,
        shouldUpdateMLVersion: boolean = true,
        concurrancy?: number
    ) {
        this.token = token;
        this.config = config;
        this.shouldUpdateMLVersion = shouldUpdateMLVersion;

        this.faceDetectionService = MLFactory.getFaceDetectionService(
            this.config.faceDetection.method
        );
        this.faceCropService = MLFactory.getFaceCropService(
            this.config.faceCrop.method
        );
        this.faceAlignmentService = MLFactory.getFaceAlignmentService(
            this.config.faceAlignment.method
        );
        this.faceEmbeddingService = MLFactory.getFaceEmbeddingService(
            this.config.faceEmbedding.method
        );
        this.faceClusteringService = MLFactory.getClusteringService(
            this.config.faceClustering.method
        );

        this.outOfSyncFiles = [];
        this.syncedFiles = [];
        this.syncedFaces = [];

        this.concurrancy = concurrancy || CONCURRENCY;

        console.log('Using concurrency: ', this.concurrancy);
        this.syncQueue = new PQueue({ concurrency: this.concurrancy });
        logQueueStats(this.syncQueue, 'sync');
        // this.downloadQueue = new PQueue({ concurrency: 1 });
        // logQueueStats(this.downloadQueue, 'download');

        this.enteComlinkWorkers = new Array(this.concurrancy);
        this.enteWorkers = new Array(this.concurrancy);
    }

    public async getEnteWorker(id: number): Promise<any> {
        const wid = id % this.enteWorkers.length;
        if (!this.enteWorkers[wid]) {
            this.enteComlinkWorkers[wid] = getDedicatedCryptoWorker();
            this.enteWorkers[wid] = new this.enteComlinkWorkers[wid].comlink();
        }

        return this.enteWorkers[wid];
    }

    public async dispose() {
        // await this.faceDetectionService.dispose();
        // await this.faceEmbeddingService.dispose();

        await this.syncQueue.onIdle();
        this.syncQueue.removeAllListeners();
        for (const enteComlinkWorker of this.enteComlinkWorkers) {
            enteComlinkWorker?.worker.terminate();
        }
    }
}
