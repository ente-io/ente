import { File, getLocalFiles } from 'services/fileService';

import * as tf from '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-backend-webgl';
import '@tensorflow/tfjs-backend-wasm';
import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';
import '@tensorflow/tfjs-backend-cpu';

import TFJSFaceDetectionService from './tfjsFaceDetectionService';
import TFJSFaceEmbeddingService from './tfjsFaceEmbeddingService';
import {
    Face,
    FaceAlignmentService,
    FaceDetectionService,
    FaceEmbeddingService,
    MlFileData,
    MLSyncConfig,
    MLSyncContext,
    MLSyncResult,
    Person,
} from 'utils/machineLearning/types';

import ClusteringService from './clusteringService';

import { toTSNE } from 'utils/machineLearning/visualization';
import {
    getIndexVersion,
    incrementIndexVersion,
    mlFilesStore,
    mlPeopleStore,
    setIndexVersion,
} from 'utils/storage/mlStorage';
import ArcfaceAlignmentService from './arcfaceAlignmentService';
import {
    findFirstIfSorted,
    getAllFacesFromMap,
    getFaceImage,
    getThumbnailTFImage,
} from 'utils/machineLearning';

class MachineLearningService {
    private faceDetectionService: FaceDetectionService;
    // private faceLandmarkService: FAPIFaceLandmarksService;
    private faceAlignmentService: FaceAlignmentService;
    private faceEmbeddingService: FaceEmbeddingService;
    // private faceEmbeddingService: FAPIFaceEmbeddingService;
    private clusteringService: ClusteringService;

    public constructor() {
        setWasmPaths('/js/tfjs/');

        this.faceDetectionService = new TFJSFaceDetectionService();
        // this.faceLandmarkService = new FAPIFaceLandmarksService();
        this.faceAlignmentService = new ArcfaceAlignmentService();
        this.faceEmbeddingService = new TFJSFaceEmbeddingService();
        // this.faceEmbeddingService = new FAPIFaceEmbeddingService();
        this.clusteringService = new ClusteringService();
    }

    public async sync(
        token: string,
        config: MLSyncConfig
    ): Promise<MLSyncResult> {
        if (!token) {
            throw Error('Token needed by ml service to sync file');
        }

        tf.engine().startScope();

        const syncContext = new MLSyncContext(token, config);

        await this.getOutOfSyncFiles(syncContext);

        if (syncContext.outOfSyncFiles.length > 0) {
            await this.syncFiles(syncContext);
        } else {
            await this.syncIndex(syncContext);
        }

        tf.engine().endScope();
        console.log('Final TF Memory stats: ', tf.memory());

        if (syncContext.config.tsne) {
            await this.runTSNE(syncContext);
        }

        const mlSyncResult: MLSyncResult = {
            nOutOfSyncFiles: syncContext.outOfSyncFiles.length,
            nSyncedFiles: syncContext.syncedFiles.length,
            nSyncedFaces: syncContext.syncedFaces.length,
            nFaceClusters: syncContext.faceClustersWithNoise?.clusters.length,
            nFaceNoise: syncContext.faceClustersWithNoise?.noise.length,
            tsne: syncContext.tsne,
        };
        console.log('[MLService] sync results: ', mlSyncResult);

        return mlSyncResult;
    }

    private async getMLFileVersion(file: File) {
        const mlFileData: MlFileData = await mlFilesStore.getItem(
            file.id.toString()
        );
        return mlFileData && mlFileData.mlVersion;
    }

    private async getUniqueOutOfSyncFiles(
        syncContext: MLSyncContext,
        files: File[]
    ) {
        const limit = syncContext.config.batchSize;
        const mlVersion = syncContext.config.mlVersion;
        const uniqueFiles: Map<number, File> = new Map<number, File>();
        for (let i = 0; uniqueFiles.size < limit && i < files.length; i++) {
            const mlFileVersion = (await this.getMLFileVersion(files[i])) || 0;
            if (!uniqueFiles.has(files[i].id) && mlFileVersion < mlVersion) {
                uniqueFiles.set(files[i].id, files[i]);
            }
        }

        return [...uniqueFiles.values()];
    }

    private async getOutOfSyncFiles(syncContext: MLSyncContext) {
        const existingFiles = await getLocalFiles();
        existingFiles.sort(
            (a, b) => b.metadata.creationTime - a.metadata.creationTime
        );
        syncContext.outOfSyncFiles = await this.getUniqueOutOfSyncFiles(
            syncContext,
            existingFiles
        );
        console.log(
            'Got unique outOfSyncFiles: ',
            syncContext.outOfSyncFiles.length,
            'for batchSize: ',
            syncContext.config.batchSize
        );
    }

    private async syncFiles(syncContext: MLSyncContext) {
        // await this.initMLModels();

        for (const outOfSyncfile of syncContext.outOfSyncFiles) {
            try {
                const mlFileData = await this.syncFile(
                    syncContext,
                    outOfSyncfile
                );
                mlFileData.faces &&
                    syncContext.syncedFaces.push(...mlFileData.faces);
                syncContext.syncedFiles.push(outOfSyncfile);
                console.log('TF Memory stats: ', tf.memory());
            } catch (e) {
                console.error(
                    'Error while syncing file: ',
                    outOfSyncfile.id,
                    e
                );
            }
        }
        console.log('allFaces: ', syncContext.syncedFaces);

        await incrementIndexVersion('files');
        // await this.disposeMLModels();
    }

    private async syncFile(syncContext: MLSyncContext, file: File) {
        const mlFileData: MlFileData = {
            fileId: file.id,
            mlVersion: syncContext.config.mlVersion,
        };

        // console.log('1 TF Memory stats: ', tf.memory());
        const tfImage = await getThumbnailTFImage(file, syncContext.token);
        // console.log('2 TF Memory stats: ', tf.memory());
        const detectedFaces = await this.faceDetectionService.detectFaces(
            tfImage
        );
        // console.log('3 TF Memory stats: ', tf.memory());

        const filtertedFaces = detectedFaces.filter(
            (f) => f.box.width > syncContext.config.faceDetection.minFaceSize
        );
        console.log('[MLService] filtertedFaces: ', filtertedFaces);
        if (filtertedFaces.length < 1) {
            await this.persistMLFileData(syncContext, mlFileData);
            return mlFileData;
        }

        const alignedFaces =
            this.faceAlignmentService.getAlignedFaces(filtertedFaces);
        console.log('[MLService] alignedFaces: ', alignedFaces);
        // console.log('4 TF Memory stats: ', tf.memory());

        const facesWithEmbeddings =
            await this.faceEmbeddingService.getFaceEmbeddings(
                tfImage,
                alignedFaces
            );
        console.log('[MLService] facesWithEmbeddings: ', facesWithEmbeddings);
        // console.log('5 TF Memory stats: ', tf.memory());

        tf.dispose(tfImage);
        // console.log('8 TF Memory stats: ', tf.memory());

        const faces = facesWithEmbeddings.map(
            (faceWithEmbeddings) =>
                ({
                    fileId: file.id,

                    ...faceWithEmbeddings,
                } as Face)
        );

        mlFileData.faces = faces;
        await this.persistMLFileData(syncContext, mlFileData);

        return mlFileData;
    }

    public async init() {
        await tf.ready();

        console.log('01 TF Memory stats: ', tf.memory());
        await this.faceDetectionService.init();
        // // console.log('02 TF Memory stats: ', tf.memory());
        // await this.faceLandmarkService.init();
        // await faceapi.nets.faceLandmark68Net.loadFromUri('/models/face-api/');
        // // console.log('03 TF Memory stats: ', tf.memory());
        await this.faceEmbeddingService.init();
        // await faceapi.nets.faceRecognitionNet.loadFromUri('/models/face-api/');
        console.log('04 TF Memory stats: ', tf.memory());
    }

    public async dispose() {
        await this.faceDetectionService.dispose();
        // console.log('11 TF Memory stats: ', tf.memory());
        // await this.faceLandmarkService.dispose();
        // console.log('12 TF Memory stats: ', tf.memory());
        await this.faceEmbeddingService.dispose();
        // console.log('13 TF Memory stats: ', tf.memory());
    }

    private async persistMLFileData(
        syncContext: MLSyncContext,
        mlFileData: MlFileData
    ) {
        return mlFilesStore.setItem(mlFileData.fileId.toString(), mlFileData);
    }

    public async syncIndex(syncContext: MLSyncContext) {
        await this.syncPeopleIndex(syncContext);
    }

    private async syncPeopleIndex(syncContext: MLSyncContext) {
        const filesVersion = await getIndexVersion('files');
        if (filesVersion <= (await getIndexVersion('people'))) {
            console.log(
                '[MLService] Skipping people index as already synced to latest version'
            );
            return;
        }

        const allFacesMap = await this.getAllSyncedFacesMap(syncContext);
        const allFaces = getAllFacesFromMap(allFacesMap);

        await this.runFaceClustering(syncContext, allFaces);
        await this.syncPeopleFromClusters(syncContext, allFacesMap, allFaces);

        await setIndexVersion('people', filesVersion);
    }

    private async getAllSyncedFacesMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedFacesMap) {
            return syncContext.allSyncedFacesMap;
        }

        const allSyncedFacesMap = new Map<number, Array<Face>>();
        await mlFilesStore.iterate((mlFileData: MlFileData) => {
            mlFileData.faces &&
                allSyncedFacesMap.set(mlFileData.fileId, mlFileData.faces);
        });

        syncContext.allSyncedFacesMap = allSyncedFacesMap;
        return allSyncedFacesMap;
    }

    public async runFaceClustering(
        syncContext: MLSyncContext,
        allFaces: Array<Face>
    ) {
        const clusteringConfig =
            syncContext.config.faceClustering.clusteringConfig;

        if (!allFaces || allFaces.length < clusteringConfig.minInputSize) {
            console.log(
                '[MLService] Too few faces to cluster, not running clustering: ',
                allFaces.length
            );
            return;
        }

        console.log('Running clustering allFaces: ', allFaces.length);
        syncContext.faceClusteringResults = this.clusteringService.cluster(
            syncContext.config.faceClustering.method,
            allFaces.map((f) => Array.from(f.embedding)),
            syncContext.config.faceClustering.clusteringConfig
        );
        console.log(
            '[MLService] Got face clustering results: ',
            syncContext.faceClusteringResults
        );

        syncContext.faceClustersWithNoise = {
            clusters: syncContext.faceClusteringResults.clusters.map(
                (faces) => ({
                    faces,
                })
            ),
            noise: syncContext.faceClusteringResults.noise,
        };
    }

    private async syncPeopleFromClusters(
        syncContext: MLSyncContext,
        allFacesMap: Map<number, Array<Face>>,
        allFaces: Array<Face>
    ) {
        const clusters = syncContext.faceClustersWithNoise?.clusters;
        if (!clusters || clusters.length < 1) {
            return;
        }

        await mlPeopleStore.clear();
        for (const [index, cluster] of clusters.entries()) {
            const faces = cluster.faces
                .map((f) => allFaces[f])
                .filter((f) => f);

            // TODO: face box to be normalized to 0..1 scale
            const personFace = findFirstIfSorted(
                faces,
                (a, b) =>
                    a.probability * a.box.width - b.probability * b.box.width
            );
            const faceImageTensor = await getFaceImage(
                personFace,
                syncContext.token
            );
            const faceImage = await faceImageTensor.array();
            tf.dispose(faceImageTensor);

            const person: Person = {
                id: index,
                files: faces.map((f) => f.fileId),
                faceImage: faceImage,
            };

            await mlPeopleStore.setItem(person.id.toString(), person);

            faces.forEach((face) => {
                face.personId = person.id;
            });
            // console.log("Creating person: ", person, faces);
        }

        await mlFilesStore.iterate((mlFileData: MlFileData, key) => {
            mlFileData.faces = allFacesMap.get(mlFileData.fileId);
            mlFilesStore.setItem(key, mlFileData);
        });
    }

    private async runTSNE(syncContext: MLSyncContext) {
        let faces = syncContext.syncedFaces;
        if (!faces || faces.length < 1) {
            const allFacesMap = await this.getAllSyncedFacesMap(syncContext);
            faces = getAllFacesFromMap(allFacesMap);
        }

        const input = faces
            .slice(0, syncContext.config.tsne.samples)
            .map((f) => f.embedding);
        syncContext.tsne = toTSNE(input, syncContext.config.tsne);
        console.log('tsne: ', syncContext.tsne);
    }
}

export default MachineLearningService;
