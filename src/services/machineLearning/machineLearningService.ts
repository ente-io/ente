import { File, FILE_TYPE, getLocalFiles } from 'services/fileService';

import * as tf from '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-backend-webgl';
import '@tensorflow/tfjs-backend-wasm';
import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';
import '@tensorflow/tfjs-backend-cpu';

import {
    DetectedFace,
    Face,
    MlFileData,
    MLSyncConfig,
    MLSyncContext,
    MLSyncFileContext,
    MLSyncResult,
    Person,
} from 'types/machineLearning';

import { toTSNE } from 'utils/machineLearning/visualization';
// import {
//     incrementIndexVersion,
//     mlFilesStore
// } from 'utils/storage/mlStorage';
import {
    findFirstIfSorted,
    getAllFacesFromMap,
    getFaceId,
    getFaceImage,
    getLocalFileImageBitmap,
    getMLSyncConfig,
    getOriginalImageBitmap,
    getThumbnailImageBitmap,
    isDifferentOrOld,
} from 'utils/machineLearning';
import { MLFactory } from './machineLearningFactory';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import {
    getFaceImageBlobFromStorage,
    getStoredFaceCrop,
} from 'utils/machineLearning/faceCrop';

class MachineLearningService {
    private initialized = false;
    // private faceDetectionService: FaceDetectionService;
    // private faceLandmarkService: FAPIFaceLandmarksService;
    // private faceAlignmentService: FaceAlignmentService;
    // private faceEmbeddingService: FaceEmbeddingService;
    // private faceEmbeddingService: FAPIFaceEmbeddingService;
    // private clusteringService: ClusteringService;

    public constructor() {
        setWasmPaths('/js/tfjs/');
        // this.faceDetectionService = new TFJSFaceDetectionService();
        // this.faceLandmarkService = new FAPIFaceLandmarksService();
        // this.faceAlignmentService = new ArcfaceAlignmentService();
        // this.faceEmbeddingService = new TFJSFaceEmbeddingService();
        // this.faceEmbeddingService = new FAPIFaceEmbeddingService();
        // this.clusteringService = new ClusteringService();
    }

    public async sync(token: string): Promise<MLSyncResult> {
        if (!token) {
            throw Error('Token needed by ml service to sync file');
        }

        // await this.init();

        // Used to debug tf memory leak, all tf memory
        // needs to be cleaned using tf.dispose or tf.tidy
        // tf.engine().startScope();

        const mlSyncConfig = await getMLSyncConfig();
        const syncContext = MLFactory.getMLSyncContext(
            token,
            mlSyncConfig,
            true
        );

        await this.syncLocalFiles(syncContext);

        await this.getOutOfSyncFiles(syncContext);

        if (syncContext.outOfSyncFiles.length > 0) {
            await this.syncFiles(syncContext);
        } else {
            await this.syncIndex(syncContext);
        }

        // tf.engine().endScope();

        if (syncContext.config.tsne) {
            await this.runTSNE(syncContext);
        }

        const mlSyncResult: MLSyncResult = {
            nOutOfSyncFiles: syncContext.outOfSyncFiles.length,
            nSyncedFiles: syncContext.syncedFiles.length,
            nSyncedFaces: syncContext.syncedFaces.length,
            nFaceClusters:
                syncContext.mlLibraryData?.faceClusteringResults?.clusters
                    .length,
            nFaceNoise:
                syncContext.mlLibraryData?.faceClusteringResults?.noise.length,
            tsne: syncContext.tsne,
        };
        // console.log('[MLService] sync results: ', mlSyncResult);

        await syncContext.dispose();
        console.log('Final TF Memory stats: ', tf.memory());

        return mlSyncResult;
    }

    private newMlData(fileId: number) {
        return {
            fileId,
            mlVersion: 0,
            errorCount: 0,
        } as MlFileData;
    }

    private async getLocalFilesMap(syncContext: MLSyncContext) {
        if (!syncContext.localFilesMap) {
            const localFiles = await getLocalFiles();
            syncContext.localFilesMap = new Map<number, File>();
            localFiles.forEach((f) => syncContext.localFilesMap.set(f.id, f));
        }

        return syncContext.localFilesMap;
    }

    private async syncLocalFiles(syncContext: MLSyncContext) {
        console.time('syncLocalFiles');
        const localFilesMap = await this.getLocalFilesMap(syncContext);

        const db = await mlIDbStorage.db;
        const tx = db.transaction('files', 'readwrite');
        const mlFileIdsArr = await mlIDbStorage.getAllFileIdsForUpdate(tx);
        const mlFileIds = new Set<number>();
        mlFileIdsArr.forEach((mlFileId) => mlFileIds.add(mlFileId));

        const newFileIds: Array<number> = [];
        for (const localFileId of localFilesMap.keys()) {
            if (!mlFileIds.has(localFileId)) {
                newFileIds.push(localFileId);
            }
        }

        let updated = false;
        if (newFileIds.length > 0) {
            console.log('newFiles: ', newFileIds.length);
            const newFiles = newFileIds.map((fileId) => this.newMlData(fileId));
            await mlIDbStorage.putAllFiles(newFiles, tx);
            updated = true;
        }

        const removedFileIds: Array<number> = [];
        for (const mlFileId of mlFileIds) {
            if (!localFilesMap.has(mlFileId)) {
                removedFileIds.push(mlFileId);
            }
        }

        if (removedFileIds.length > 0) {
            console.log('removedFiles: ', removedFileIds.length);
            await mlIDbStorage.removeAllFiles(removedFileIds, tx);
            updated = true;
        }

        await tx.done;

        if (updated) {
            // TODO: should do in same transaction
            await mlIDbStorage.incrementIndexVersion('files');
        }

        console.timeEnd('syncLocalFiles');
    }

    // TODO: not required if ml data is stored as field inside ente file object
    // it removes ml data for files in trash, they will be resynced if restored
    // private async syncRemovedFiles(syncContext: MLSyncContext) {
    //     const db = await mlIDbStorage.db;
    //     const localFileIdMap = await this.getLocalFilesMap(syncContext);

    //     const removedFileIds: Array<string> = [];
    //     await mlFilesStore.iterate((file, idStr) => {
    //         if (!localFileIdMap.has(parseInt(idStr))) {
    //             removedFileIds.push(idStr);
    //         }
    //     });

    //     if (removedFileIds.length < 1) {
    //         return;
    //     }

    //     removedFileIds.forEach((fileId) => mlFilesStore.removeItem(fileId));
    //     console.log('Removed local file ids: ', removedFileIds);

    //     await incrementIndexVersion('files');
    // }

    private async getOutOfSyncFiles(syncContext: MLSyncContext) {
        console.time('getOutOfSyncFiles');
        const fileIds = await mlIDbStorage.getFileIds(
            syncContext.config.batchSize,
            syncContext.config.mlVersion,
            2
        );

        console.log('fileIds: ', fileIds);

        const localFilesMap = await this.getLocalFilesMap(syncContext);
        syncContext.outOfSyncFiles = fileIds.map((fileId) =>
            localFilesMap.get(fileId)
        );
        console.timeEnd('getOutOfSyncFiles');
    }

    // TODO: optimize, use indexdb indexes, move facecrops to cache to reduce io
    private async getUniqueOutOfSyncFilesNoIdx(
        syncContext: MLSyncContext,
        files: File[]
    ) {
        const limit = syncContext.config.batchSize;
        const mlVersion = syncContext.config.mlVersion;
        const uniqueFiles: Map<number, File> = new Map<number, File>();
        for (let i = 0; uniqueFiles.size < limit && i < files.length; i++) {
            const mlFileData = await this.getMLFileData(files[i].id);
            const mlFileVersion = mlFileData?.mlVersion || 0;
            if (
                !uniqueFiles.has(files[i].id) &&
                (!mlFileData?.errorCount || mlFileData.errorCount < 2) &&
                (mlFileVersion < mlVersion ||
                    syncContext.config.imageSource !== mlFileData.imageSource)
            ) {
                uniqueFiles.set(files[i].id, files[i]);
            }
        }

        return [...uniqueFiles.values()];
    }

    private async getOutOfSyncFilesNoIdx(syncContext: MLSyncContext) {
        const existingFilesMap = await this.getLocalFilesMap(syncContext);
        // existingFiles.sort(
        //     (a, b) => b.metadata.creationTime - a.metadata.creationTime
        // );
        console.time('getUniqueOutOfSyncFiles');
        syncContext.outOfSyncFiles = await this.getUniqueOutOfSyncFilesNoIdx(
            syncContext,
            [...existingFilesMap.values()]
        );
        console.timeEnd('getUniqueOutOfSyncFiles');
        console.log(
            'Got unique outOfSyncFiles: ',
            syncContext.outOfSyncFiles.length,
            'for batchSize: ',
            syncContext.config.batchSize
        );
    }

    private async syncFiles(syncContext: MLSyncContext) {
        for (const outOfSyncfile of syncContext.outOfSyncFiles) {
            syncContext.syncQueue.add(async () => {
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

                    await this.persistMLFileSyncError(
                        syncContext,
                        outOfSyncfile,
                        e
                    );
                }
            });
        }
        // TODO: can use addAll instead
        await syncContext.syncQueue.onIdle();
        console.log('allFaces: ', syncContext.syncedFaces);

        await mlIDbStorage.incrementIndexVersion('files');
        // await this.disposeMLModels();
    }

    public async syncLocalFile(
        token: string,
        enteFile: File,
        localFile: globalThis.File,
        config?: MLSyncConfig
    ) {
        const mlSyncConfig = config || (await getMLSyncConfig());
        const syncContext = MLFactory.getMLSyncContext(
            token,
            mlSyncConfig,
            false
        );
        // await this.init();

        try {
            const mlFileData = await this.syncFile(
                syncContext,
                enteFile,
                localFile
            );
            await syncContext.dispose();
            return mlFileData;
        } catch (e) {
            console.error('Error while syncing local file: ', enteFile.id, e);
            await this.persistMLFileSyncError(syncContext, enteFile, e);
        }
    }

    private async syncFile(
        syncContext: MLSyncContext,
        enteFile: File,
        localFile?: globalThis.File
    ) {
        const fileContext: MLSyncFileContext = { enteFile, localFile };
        fileContext.oldMLFileData = await this.getMLFileData(enteFile.id);
        if (!fileContext.oldMLFileData) {
            fileContext.newMLFileData = this.newMlData(enteFile.id);
        } else if (
            fileContext.oldMLFileData?.mlVersion ===
                syncContext.config.mlVersion &&
            fileContext.oldMLFileData?.imageSource ===
                syncContext.config.imageSource
        ) {
            return fileContext.oldMLFileData;
        } else {
            // TODO: let rest of sync populate new file data correctly
            fileContext.newMLFileData = { ...fileContext.oldMLFileData };
            fileContext.newMLFileData.imageSource =
                syncContext.config.imageSource;
        }

        if (syncContext.shouldUpdateMLVersion) {
            fileContext.newMLFileData.mlVersion = syncContext.config.mlVersion;
        }

        await this.syncFileFaceDetections(syncContext, fileContext);

        if (fileContext.faces && fileContext.faces.length > 0) {
            await this.syncFileFaceCrops(syncContext, fileContext);

            await this.syncFileFaceAlignments(syncContext, fileContext);

            await this.syncFileFaceEmbeddings(syncContext, fileContext);

            fileContext.newMLFileData.faces = fileContext.faces;
        } else {
            fileContext.newMLFileData.faces = undefined;
        }

        fileContext.tfImage && fileContext.tfImage.dispose();
        fileContext.imageBitmap && fileContext.imageBitmap.close();
        // console.log('8 TF Memory stats: ', tf.memory());
        await this.persistMLFileData(syncContext, fileContext.newMLFileData);

        // TODO: enable once faceId changes go in
        // await removeOldFaceCrops(
        //     fileContext.oldMLFileData,
        //     fileContext.newMLFileData
        // );

        return fileContext.newMLFileData;
    }

    private async getImageBitmap(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        // console.log('1 TF Memory stats: ', tf.memory());
        if (fileContext.localFile) {
            fileContext.imageBitmap = await getLocalFileImageBitmap(
                fileContext.localFile
            );
            // fileContext.newMLFileData.imageSource = 'Original';
        } else if (
            syncContext.config.imageSource === 'Original' &&
            [FILE_TYPE.IMAGE, FILE_TYPE.LIVE_PHOTO].includes(
                fileContext.enteFile.metadata.fileType
            )
        ) {
            fileContext.imageBitmap = await getOriginalImageBitmap(
                fileContext.enteFile,
                syncContext.token,
                await syncContext.getEnteWorker(fileContext.enteFile.id)
            );
            // fileContext.newMLFileData.imageSource = 'Original';
        } else {
            fileContext.imageBitmap = await getThumbnailImageBitmap(
                fileContext.enteFile,
                syncContext.token
            );
            // fileContext.newMLFileData.imageSource = 'Preview';
        }

        if (!fileContext.newMLFileData.imageDimentions) {
            const { width, height } = fileContext.imageBitmap;
            fileContext.newMLFileData.imageDimentions = { width, height };
        }
        // console.log('2 TF Memory stats: ', tf.memory());
    }

    private async syncFileFaceDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        if (
            isDifferentOrOld(
                fileContext.oldMLFileData?.faceDetectionMethod,
                syncContext.faceDetectionService.method
            ) ||
            fileContext.oldMLFileData?.imageSource !==
                syncContext.config.imageSource
        ) {
            fileContext.newMLFileData.faceDetectionMethod =
                syncContext.faceDetectionService.method;
            fileContext.newMLFileData.imageSource =
                syncContext.config.imageSource;
            fileContext.newDetection = true;
            await this.getImageBitmap(syncContext, fileContext);
            const faceDetections =
                await syncContext.faceDetectionService.detectFaces(
                    fileContext.imageBitmap
                );
            // console.log('3 TF Memory stats: ', tf.memory());
            // TODO: reenable faces filtering based on width
            const detectedFaces = faceDetections?.map((detection) => {
                return {
                    fileId: fileContext.enteFile.id,
                    detection,
                } as DetectedFace;
            });
            fileContext.faces = detectedFaces?.map((detectedFace) => ({
                ...detectedFace,
                id: getFaceId(
                    detectedFace,
                    fileContext.newMLFileData.imageDimentions
                ),
            }));
            // ?.filter((f) =>
            //     f.box.width > syncContext.config.faceDetection.minFaceSize
            // );
            console.log(
                '[MLService] filtertedFaces: ',
                fileContext.faces?.length
            );
        } else {
            fileContext.faces = fileContext.oldMLFileData?.faces;
        }
    }

    private async syncFileFaceCrops(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const imageBitmap = fileContext.imageBitmap;
        if (
            !fileContext.newDetection ||
            !syncContext.config.faceCrop.enabled ||
            !imageBitmap
        ) {
            return;
        }
        fileContext.newMLFileData.faceCropMethod =
            syncContext.faceCropService.method;

        for (const face of fileContext.faces) {
            const faceCrop = await syncContext.faceCropService.getFaceCrop(
                imageBitmap,
                face.detection,
                syncContext.config.faceCrop
            );
            face.crop = await getStoredFaceCrop(
                face.id,
                faceCrop,
                syncContext.config.faceCrop.blobOptions
            );
            faceCrop.image.close();
        }
    }

    private async syncFileFaceAlignments(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        if (
            fileContext.newDetection ||
            isDifferentOrOld(
                fileContext.oldMLFileData?.faceAlignmentMethod,
                syncContext.faceAlignmentService.method
            )
        ) {
            fileContext.newMLFileData.faceAlignmentMethod =
                syncContext.faceAlignmentService.method;
            fileContext.newAlignment = true;
            for (const face of fileContext.faces) {
                face.alignment =
                    syncContext.faceAlignmentService.getFaceAlignment(
                        face.detection
                    );
            }
            console.log(
                '[MLService] alignedFaces: ',
                fileContext.faces?.length
            );
            // console.log('4 TF Memory stats: ', tf.memory());
        } else {
            fileContext.faces = fileContext.oldMLFileData?.faces;
        }
    }

    private async syncFileFaceEmbeddings(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        if (
            fileContext.newAlignment ||
            isDifferentOrOld(
                fileContext.oldMLFileData?.faceEmbeddingMethod,
                syncContext.faceEmbeddingService.method
            )
        ) {
            fileContext.newMLFileData.faceEmbeddingMethod =
                syncContext.faceEmbeddingService.method;
            // TODO: when not storing face crops image will be needed to extract faces
            // fileContext.imageBitmap ||
            //     (await this.getImageBitmap(syncContext, fileContext));
            const embeddings =
                await syncContext.faceEmbeddingService.getFaceEmbeddings(
                    fileContext.imageBitmap,
                    fileContext.faces
                );

            fileContext.faces.forEach((f, i) => (f.embedding = embeddings[i]));

            console.log('[MLService] facesWithEmbeddings: ', fileContext.faces);
            // console.log('5 TF Memory stats: ', tf.memory());
        } else {
            fileContext.faces = fileContext.oldMLFileData?.faces;
        }
    }

    public async init() {
        if (this.initialized) {
            return;
        }

        await tf.ready();

        console.log('01 TF Memory stats: ', tf.memory());
        // await tfjsFaceDetectionService.init();
        // // console.log('02 TF Memory stats: ', tf.memory());
        // await this.faceLandmarkService.init();
        // await faceapi.nets.faceLandmark68Net.loadFromUri('/models/face-api/');
        // // console.log('03 TF Memory stats: ', tf.memory());
        // await tfjsFaceEmbeddingService.init();
        // await faceapi.nets.faceRecognitionNet.loadFromUri('/models/face-api/');
        // console.log('04 TF Memory stats: ', tf.memory());

        this.initialized = true;
    }

    public async dispose() {
        this.initialized = false;
        // await this.faceDetectionService.dispose();
        // console.log('11 TF Memory stats: ', tf.memory());
        // await this.faceLandmarkService.dispose();
        // console.log('12 TF Memory stats: ', tf.memory());
        // await this.faceEmbeddingService.dispose();
        // console.log('13 TF Memory stats: ', tf.memory());
    }

    private async getMLFileData(fileId: number) {
        // return mlFilesStore.getItem<MlFileData>(fileId);
        return mlIDbStorage.getFile(fileId);
    }

    private async persistMLFileData(
        syncContext: MLSyncContext,
        mlFileData: MlFileData
    ) {
        // return mlFilesStore.setItem(mlFileData.fileId.toString(), mlFileData);
        mlIDbStorage.putFile(mlFileData);
    }

    private async persistMLFileSyncError(
        syncContext: MLSyncContext,
        enteFile: File,
        e: Error
    ) {
        try {
            const oldMlFileData = await this.getMLFileData(enteFile.id);
            let mlFileData = oldMlFileData;
            if (!mlFileData) {
                mlFileData = this.newMlData(enteFile.id);
            }
            mlFileData.errorCount = (mlFileData.errorCount || 0) + 1;
            mlFileData.lastErrorMessage = e.message;
            return this.persistMLFileData(syncContext, mlFileData);
        } catch (e) {
            // TODO: logError or stop sync job after most of the requests are failed
            console.error('Error while storing ml sync error', e);
        }
    }

    private async getMLLibraryData(syncContext: MLSyncContext) {
        syncContext.mlLibraryData = await mlIDbStorage.getLibraryData();
        if (!syncContext.mlLibraryData) {
            syncContext.mlLibraryData = {};
        }
    }

    private async persistMLLibraryData(syncContext: MLSyncContext) {
        // return mlLibraryStore.setItem('data', syncContext.mlLibraryData);
        return mlIDbStorage.putLibraryData(syncContext.mlLibraryData);
    }

    public async syncIndex(syncContext: MLSyncContext) {
        await this.getMLLibraryData(syncContext);

        // await this.init();
        await this.syncPeopleIndex(syncContext);

        await this.persistMLLibraryData(syncContext);
    }

    private async syncPeopleIndex(syncContext: MLSyncContext) {
        const filesVersion = await mlIDbStorage.getIndexVersion('files');
        if (
            filesVersion <= (await mlIDbStorage.getIndexVersion('people')) &&
            !isDifferentOrOld(
                syncContext.mlLibraryData?.faceClusteringMethod,
                syncContext.faceClusteringService.method
            )
        ) {
            console.log(
                '[MLService] Skipping people index as already synced to latest version'
            );
            return;
        }

        // TODO: have faces addresable through fileId + faceId
        // to avoid index based addressing, which is prone to wrong results
        // one way could be to match nearest face within threshold in the file
        const allFacesMap = await this.getAllSyncedFacesMap(syncContext);
        const allFaces = getAllFacesFromMap(allFacesMap);

        await this.runFaceClustering(syncContext, allFaces);
        await this.syncPeopleFromClusters(syncContext, allFacesMap, allFaces);

        await mlIDbStorage.setIndexVersion('people', filesVersion);
    }

    private async getAllSyncedFacesMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedFacesMap) {
            return syncContext.allSyncedFacesMap;
        }

        syncContext.allSyncedFacesMap = await mlIDbStorage.getAllFacesMap();
        return syncContext.allSyncedFacesMap;
    }

    public async runFaceClustering(
        syncContext: MLSyncContext,
        allFaces: Array<Face>
    ) {
        // await this.init();

        const clusteringConfig = syncContext.config.faceClustering;

        if (!allFaces || allFaces.length < clusteringConfig.minInputSize) {
            console.log(
                '[MLService] Too few faces to cluster, not running clustering: ',
                allFaces.length
            );
            return;
        }

        console.log('Running clustering allFaces: ', allFaces.length);
        syncContext.mlLibraryData.faceClusteringResults =
            await syncContext.faceClusteringService.cluster(
                allFaces.map((f) => Array.from(f.embedding)),
                syncContext.config.faceClustering
            );
        syncContext.mlLibraryData.faceClusteringMethod =
            syncContext.faceClusteringService.method;
        console.log(
            '[MLService] Got face clustering results: ',
            syncContext.mlLibraryData.faceClusteringResults
        );

        // syncContext.faceClustersWithNoise = {
        //     clusters: syncContext.faceClusteringResults.clusters.map(
        //         (faces) => ({
        //             faces,
        //         })
        //     ),
        //     noise: syncContext.faceClusteringResults.noise,
        // };
    }

    private async syncPeopleFromClusters(
        syncContext: MLSyncContext,
        allFacesMap: Map<number, Array<Face>>,
        allFaces: Array<Face>
    ) {
        const clusters =
            syncContext.mlLibraryData.faceClusteringResults?.clusters;
        if (!clusters || clusters.length < 1) {
            return;
        }

        await mlIDbStorage.clearAllPeople();
        for (const [index, cluster] of clusters.entries()) {
            const faces = cluster.map((f) => allFaces[f]).filter((f) => f);

            const personFace = findFirstIfSorted(
                faces,
                (a, b) =>
                    a.detection.probability * a.alignment.size -
                    b.detection.probability * b.alignment.size
            );

            let faceImage = await getFaceImageBlobFromStorage(personFace.crop);
            if (!faceImage) {
                faceImage = await getFaceImage(personFace, syncContext.token);
            }

            const person: Person = {
                id: index,
                files: faces.map((f) => f.fileId),
                faceImage,
            };

            await mlIDbStorage.putPerson(person);

            faces.forEach((face) => {
                face.personId = person.id;
            });
            // console.log("Creating person: ", person, faces);
        }

        await mlIDbStorage.updateFaces(allFacesMap);
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

export default new MachineLearningService();
