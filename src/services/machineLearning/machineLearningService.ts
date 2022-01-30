import { File, FILE_TYPE, getLocalFiles } from 'services/fileService';

import * as tf from '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-backend-webgl';
// import '@tensorflow/tfjs-backend-wasm';
// import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';
// import '@tensorflow/tfjs-backend-cpu';

import {
    DetectedFace,
    Face,
    MlFileData,
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
    areFaceIdsSame,
    extractFaceImages,
    findFirstIfSorted,
    getAllFacesFromMap,
    getFaceId,
    getLocalFile,
    getLocalFileImageBitmap,
    getOriginalImageBitmap,
    getThumbnailImageBitmap,
    isDifferentOrOld,
} from 'utils/machineLearning';
import { MLFactory } from './machineLearningFactory';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { storeFaceCrop } from 'utils/machineLearning/faceCrop';
import { getMLSyncConfig } from 'utils/machineLearning/config';
import { CustomError, parseServerError } from 'utils/common/errorUtil';

class MachineLearningService {
    private initialized = false;
    // private faceDetectionService: FaceDetectionService;
    // private faceLandmarkService: FAPIFaceLandmarksService;
    // private faceAlignmentService: FaceAlignmentService;
    // private faceEmbeddingService: FaceEmbeddingService;
    // private faceEmbeddingService: FAPIFaceEmbeddingService;
    // private clusteringService: ClusteringService;

    private localSyncContext: Promise<MLSyncContext>;

    public constructor() {
        // setWasmPaths('/js/tfjs/');
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
        }

        // TODO: running index before all files are on latest ml version
        // may be need to just take synced files on latest ml version for indexing
        if (
            syncContext.outOfSyncFiles.length <= 0 ||
            (syncContext.nSyncedFiles === syncContext.config.batchSize &&
                Math.random() < 0.2)
        ) {
            await this.syncIndex(syncContext);
        }

        // tf.engine().endScope();

        if (syncContext.config.tsne) {
            await this.runTSNE(syncContext);
        }

        const mlSyncResult: MLSyncResult = {
            nOutOfSyncFiles: syncContext.outOfSyncFiles.length,
            nSyncedFiles: syncContext.nSyncedFiles,
            nSyncedFaces: syncContext.nSyncedFaces,
            nFaceClusters:
                syncContext.mlLibraryData?.faceClusteringResults?.clusters
                    .length,
            nFaceNoise:
                syncContext.mlLibraryData?.faceClusteringResults?.noise.length,
            tsne: syncContext.tsne,
            error: syncContext.error,
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
    // remove, not required now
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
    // remove, already done
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
        try {
            const functions = syncContext.outOfSyncFiles.map(
                (outOfSyncfile) => async () => {
                    await this.syncFileWithErrorHandler(
                        syncContext,
                        outOfSyncfile
                    );
                    // TODO: just store file and faces count in syncContext
                }
            );
            syncContext.syncQueue.on('error', () => {
                syncContext.syncQueue.clear();
            });
            await syncContext.syncQueue.addAll(functions);
        } catch (error) {
            console.error('Error in sync job: ', error);
            syncContext.error = error;
        }
        await syncContext.syncQueue.onIdle();
        console.log('allFaces: ', syncContext.nSyncedFaces);

        // TODO: In case syncJob has to use multiple ml workers
        // do in same transaction with each file update
        // or keep in files store itself
        await mlIDbStorage.incrementIndexVersion('files');
        // await this.disposeMLModels();
    }

    private async getLocalSyncContext(token: string) {
        if (!this.localSyncContext) {
            console.log('Creating localSyncContext');
            this.localSyncContext = getMLSyncConfig().then((mlSyncConfig) =>
                MLFactory.getMLSyncContext(token, mlSyncConfig, false)
            );
        }

        return this.localSyncContext;
    }

    public async closeLocalSyncContext() {
        if (this.localSyncContext) {
            console.log('Closing localSyncContext');
            const syncContext = await this.localSyncContext;
            await syncContext.dispose();
            this.localSyncContext = undefined;
        }
    }

    public async syncLocalFile(
        token: string,
        enteFile: File,
        localFile: globalThis.File
    ): Promise<MlFileData | Error> {
        const syncContext = await this.getLocalSyncContext(token);

        try {
            const mlFileData = await this.syncFileWithErrorHandler(
                syncContext,
                enteFile,
                localFile
            );

            if (syncContext.nSyncedFiles >= syncContext.config.batchSize) {
                await this.closeLocalSyncContext();
            }
            // await syncContext.dispose();
            return mlFileData;
        } catch (e) {
            console.error('Error while syncing local file: ', enteFile.id, e);
            return e;
        }
    }

    private async syncFileWithErrorHandler(
        syncContext: MLSyncContext,
        enteFile: File,
        localFile?: globalThis.File
    ): Promise<MlFileData> {
        try {
            const mlFileData = await this.syncFile(
                syncContext,
                enteFile,
                localFile
            );
            syncContext.nSyncedFaces += mlFileData.faces?.length || 0;
            syncContext.nSyncedFiles += 1;
            return mlFileData;
        } catch (e) {
            let error = e;
            console.error('Error in ml sync, fileId: ', enteFile.id, error);
            if ('status' in error) {
                error = parseServerError(error).parsedError || error;
            }
            // TODO: throw errors not related to specific file
            // sync job run should stop after these errors
            // don't persist these errors against file,
            // can include indexeddb/cache errors too
            switch (error.message) {
                case CustomError.SESSION_EXPIRED_MESSAGE:
                case CustomError.NETWORK_ERROR:
                    throw error;
            }

            await this.persistMLFileSyncError(syncContext, enteFile, error);
            syncContext.nSyncedFiles += 1;
        } finally {
            console.log('TF Memory stats: ', tf.memory());
        }
    }

    private async syncFile(
        syncContext: MLSyncContext,
        enteFile: File,
        localFile?: globalThis.File
    ) {
        const fileContext: MLSyncFileContext = { enteFile, localFile };
        fileContext.oldMlFile = await this.getMLFileData(enteFile.id);
        if (
            fileContext.oldMlFile?.mlVersion === syncContext.config.mlVersion
            // TODO: reset mlversion of all files when user changes image source
        ) {
            return fileContext.oldMlFile;
        }
        const newMlFile = (fileContext.newMlFile = this.newMlData(enteFile.id));

        if (syncContext.shouldUpdateMLVersion) {
            newMlFile.mlVersion = syncContext.config.mlVersion;
        } else if (fileContext.oldMlFile?.mlVersion) {
            newMlFile.mlVersion = fileContext.oldMlFile.mlVersion;
        }

        await this.syncFileFaceDetections(syncContext, fileContext);

        if (newMlFile.faces && newMlFile.faces.length > 0) {
            await this.syncFileFaceCrops(syncContext, fileContext);

            await this.syncFileFaceAlignments(syncContext, fileContext);

            await this.syncFileFaceEmbeddings(syncContext, fileContext);
        }

        fileContext.tfImage && fileContext.tfImage.dispose();
        fileContext.imageBitmap && fileContext.imageBitmap.close();
        // console.log('8 TF Memory stats: ', tf.memory());

        newMlFile.errorCount = 0;
        newMlFile.lastErrorMessage = undefined;
        await this.persistMLFileData(syncContext, newMlFile);

        // TODO: enable once faceId changes go in
        // await removeOldFaceCrops(
        //     fileContext.oldMlFile,
        //     fileContext.newMlFile
        // );

        return newMlFile;
    }

    private async getImageBitmap(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        if (fileContext.imageBitmap) {
            return fileContext.imageBitmap;
        }
        // console.log('1 TF Memory stats: ', tf.memory());
        if (fileContext.localFile) {
            if (fileContext.enteFile.metadata.fileType !== FILE_TYPE.IMAGE) {
                throw new Error('Local file of only image type is supported');
            }
            fileContext.imageBitmap = await getLocalFileImageBitmap(
                fileContext.enteFile,
                fileContext.localFile,
                () => syncContext.getEnteWorker(fileContext.enteFile.id)
            );
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
        } else {
            fileContext.imageBitmap = await getThumbnailImageBitmap(
                fileContext.enteFile,
                syncContext.token
            );
        }

        fileContext.newMlFile.imageSource = syncContext.config.imageSource;
        const { width, height } = fileContext.imageBitmap;
        fileContext.newMlFile.imageDimentions = { width, height };
        // console.log('2 TF Memory stats: ', tf.memory());

        return fileContext.imageBitmap;
    }

    private async syncFileFaceDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.faceDetectionMethod,
                syncContext.faceDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource
        ) {
            newMlFile.faces = oldMlFile?.faces?.map((existingFace) => ({
                id: existingFace.id,
                fileId: existingFace.fileId,
                detection: existingFace.detection,
            }));

            newMlFile.imageSource = oldMlFile.imageSource;
            newMlFile.imageDimentions = oldMlFile.imageDimentions;
            newMlFile.faceDetectionMethod = oldMlFile.faceDetectionMethod;
            return;
        }

        newMlFile.faceDetectionMethod = syncContext.faceDetectionService.method;
        fileContext.newDetection = true;
        const imageBitmap = await this.getImageBitmap(syncContext, fileContext);
        const faceDetections =
            await syncContext.faceDetectionService.detectFaces(imageBitmap);
        // console.log('3 TF Memory stats: ', tf.memory());
        // TODO: reenable faces filtering based on width
        const detectedFaces = faceDetections?.map((detection) => {
            return {
                fileId: fileContext.enteFile.id,
                detection,
            } as DetectedFace;
        });
        newMlFile.faces = detectedFaces?.map((detectedFace) => ({
            ...detectedFace,
            id: getFaceId(detectedFace, newMlFile.imageDimentions),
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        console.log('[MLService] Detected Faces: ', newMlFile.faces?.length);
    }

    private async saveFaceCrop(
        imageBitmap: ImageBitmap,
        face: Face,
        syncContext: MLSyncContext
    ) {
        const faceCrop = await syncContext.faceCropService.getFaceCrop(
            imageBitmap,
            face.detection,
            syncContext.config.faceCrop
        );
        face.crop = await storeFaceCrop(
            face.id,
            faceCrop,
            syncContext.config.faceCrop.blobOptions
        );
        faceCrop.image.close();
    }

    private async syncFileFaceCrops(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            // !syncContext.config.faceCrop.enabled ||
            !fileContext.newDetection &&
            !isDifferentOrOld(
                oldMlFile?.faceCropMethod,
                syncContext.faceCropService.method
            ) &&
            areFaceIdsSame(newMlFile.faces, oldMlFile?.faces)
        ) {
            for (const [index, face] of newMlFile.faces.entries()) {
                face.crop = oldMlFile.faces[index].crop;
            }
            newMlFile.faceCropMethod = oldMlFile.faceCropMethod;
            return;
        }

        const imageBitmap = await this.getImageBitmap(syncContext, fileContext);
        newMlFile.faceCropMethod = syncContext.faceCropService.method;

        for (const face of newMlFile.faces) {
            await this.saveFaceCrop(imageBitmap, face, syncContext);
        }
    }

    private async syncFileFaceAlignments(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !fileContext.newDetection &&
            !isDifferentOrOld(
                oldMlFile?.faceAlignmentMethod,
                syncContext.faceAlignmentService.method
            ) &&
            areFaceIdsSame(newMlFile.faces, oldMlFile?.faces)
        ) {
            for (const [index, face] of newMlFile.faces.entries()) {
                face.alignment = oldMlFile.faces[index].alignment;
            }
            newMlFile.faceAlignmentMethod = oldMlFile.faceAlignmentMethod;
            return;
        }

        newMlFile.faceAlignmentMethod = syncContext.faceAlignmentService.method;
        fileContext.newAlignment = true;
        for (const face of newMlFile.faces) {
            face.alignment = syncContext.faceAlignmentService.getFaceAlignment(
                face.detection
            );
        }
        console.log('[MLService] alignedFaces: ', newMlFile.faces?.length);
        // console.log('4 TF Memory stats: ', tf.memory());
    }

    private async syncFileFaceEmbeddings(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !fileContext.newAlignment &&
            !isDifferentOrOld(
                oldMlFile?.faceEmbeddingMethod,
                syncContext.faceEmbeddingService.method
            ) &&
            areFaceIdsSame(newMlFile.faces, oldMlFile?.faces)
        ) {
            for (const [index, face] of newMlFile.faces.entries()) {
                face.embedding = oldMlFile.faces[index].embedding;
            }
            newMlFile.faceEmbeddingMethod = oldMlFile.faceEmbeddingMethod;
            return;
        }

        newMlFile.faceEmbeddingMethod = syncContext.faceEmbeddingService.method;
        // TODO: when not storing face crops, image will be needed to extract faces
        // fileContext.imageBitmap ||
        //     (await this.getImageBitmap(syncContext, fileContext));
        const faceImages = await extractFaceImages(
            newMlFile.faces,
            syncContext.faceEmbeddingService.faceSize
        );

        const embeddings =
            await syncContext.faceEmbeddingService.getFaceEmbeddings(
                faceImages
            );
        faceImages.forEach((faceImage) => faceImage.close());
        newMlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

        console.log(
            '[MLService] facesWithEmbeddings: ',
            newMlFile.faces.length
        );
        // console.log('5 TF Memory stats: ', tf.memory());
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
            await mlIDbStorage.upsertFileInTx(enteFile.id, (mlFileData) => {
                if (!mlFileData) {
                    mlFileData = this.newMlData(enteFile.id);
                }
                mlFileData.errorCount = (mlFileData.errorCount || 0) + 1;
                mlFileData.lastErrorMessage = e.message;

                return mlFileData;
            });
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

        for (const face of allFaces) {
            face.personId = undefined;
        }
        await mlIDbStorage.clearAllPeople();
        for (const [index, cluster] of clusters.entries()) {
            const faces = cluster.map((f) => allFaces[f]).filter((f) => f);

            // TODO: take default display face from last leaves of hdbscan clusters
            const personFace = findFirstIfSorted(
                faces,
                (a, b) => b.detection.probability - a.detection.probability
            );

            if (personFace && !personFace.crop?.imageUrl) {
                const file = await getLocalFile(personFace.fileId);
                const imageBitmap = await getOriginalImageBitmap(
                    file,
                    syncContext.token
                );
                await this.saveFaceCrop(imageBitmap, personFace, syncContext);
            }

            const person: Person = {
                id: index,
                files: faces.map((f) => f.fileId),
                displayFaceId: personFace?.id,
                displayImageUrl: personFace?.crop?.imageUrl,
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
        const allFacesMap = await this.getAllSyncedFacesMap(syncContext);
        const allFaces = getAllFacesFromMap(allFacesMap);

        const input = allFaces
            .slice(0, syncContext.config.tsne.samples)
            .map((f) => Array.from(f.embedding));
        syncContext.tsne = toTSNE(input, syncContext.config.tsne);
        console.log('tsne: ', syncContext.tsne);
    }
}

export default new MachineLearningService();
