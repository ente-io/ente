import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedFace,
    Face,
} from 'types/machineLearning';
import { addLogLine } from 'utils/logging';
import {
    isDifferentOrOld,
    getFaceId,
    areFaceIdsSame,
    extractFaceImages,
} from 'utils/machineLearning';
import { storeFaceCrop } from 'utils/machineLearning/faceCrop';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import ReaderService from './readerService';

class FaceService {
    async syncFileFaceDetections(
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
            newMlFile.imageDimensions = oldMlFile.imageDimensions;
            newMlFile.faceDetectionMethod = oldMlFile.faceDetectionMethod;
            return;
        }

        newMlFile.faceDetectionMethod = syncContext.faceDetectionService.method;
        fileContext.newDetection = true;
        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        const faceDetections =
            await syncContext.faceDetectionService.detectFaces(imageBitmap);
        // addLogLine('3 TF Memory stats: ',JSON.stringify(tf.memory()));
        // TODO: reenable faces filtering based on width
        const detectedFaces = faceDetections?.map((detection) => {
            return {
                fileId: fileContext.enteFile.id,
                detection,
            } as DetectedFace;
        });
        newMlFile.faces = detectedFaces?.map((detectedFace) => ({
            ...detectedFace,
            id: getFaceId(detectedFace, newMlFile.imageDimensions),
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        addLogLine('[MLService] Detected Faces: ', newMlFile.faces?.length);
    }

    async syncFileFaceCrops(
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

        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        newMlFile.faceCropMethod = syncContext.faceCropService.method;

        for (const face of newMlFile.faces) {
            await this.saveFaceCrop(imageBitmap, face, syncContext);
        }
    }

    async syncFileFaceAlignments(
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
        addLogLine('[MLService] alignedFaces: ', newMlFile.faces?.length);
        // addLogLine('4 TF Memory stats: ',JSON.stringify(tf.memory()));
    }

    async syncFileFaceEmbeddings(
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

        addLogLine('[MLService] facesWithEmbeddings: ', newMlFile.faces.length);
        // addLogLine('5 TF Memory stats: ',JSON.stringify(tf.memory()));
    }

    async saveFaceCrop(
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

    async getAllSyncedFacesMap(syncContext: MLSyncContext) {
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
            addLogLine(
                '[MLService] Too few faces to cluster, not running clustering: ',
                allFaces.length
            );
            return;
        }

        addLogLine('Running clustering allFaces: ', allFaces.length);
        syncContext.mlLibraryData.faceClusteringResults =
            await syncContext.faceClusteringService.cluster(
                allFaces.map((f) => Array.from(f.embedding)),
                syncContext.config.faceClustering
            );
        syncContext.mlLibraryData.faceClusteringMethod =
            syncContext.faceClusteringService.method;
        addLogLine(
            '[MLService] Got face clustering results: ',
            JSON.stringify(syncContext.mlLibraryData.faceClusteringResults)
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
}

export default new FaceService();
