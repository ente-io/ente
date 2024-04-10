import log from "@/next/log";
import {
    DetectedFace,
    Face,
    MLSyncContext,
    MLSyncFileContext,
} from "types/machineLearning";
import { imageBitmapToBlob } from "utils/image";
import {
    areFaceIdsSame,
    extractFaceImagesToFloat32,
    getFaceId,
    getLocalFile,
    getOriginalImageBitmap,
    isDifferentOrOld,
} from "utils/machineLearning";
import { storeFaceCrop } from "utils/machineLearning/faceCrop";
import mlIDbStorage from "utils/storage/mlIDbStorage";
import ReaderService from "./readerService";

class FaceService {
    async syncFileFaceDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.faceDetectionMethod,
                syncContext.faceDetectionService.method,
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
            fileContext,
        );
        const timerId = `faceDetection-${fileContext.enteFile.id}`;
        console.time(timerId);
        const faceDetections =
            await syncContext.faceDetectionService.detectFaces(imageBitmap);
        console.timeEnd(timerId);
        console.log("faceDetections: ", faceDetections?.length);
        // log.info('3 TF Memory stats: ',JSON.stringify(tf.memory()));
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
        log.info("[MLService] Detected Faces: ", newMlFile.faces?.length);
    }

    async syncFileFaceCrops(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            // !syncContext.config.faceCrop.enabled ||
            !fileContext.newDetection &&
            !isDifferentOrOld(
                oldMlFile?.faceCropMethod,
                syncContext.faceCropService.method,
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
            fileContext,
        );
        newMlFile.faceCropMethod = syncContext.faceCropService.method;

        for (const face of newMlFile.faces) {
            await this.saveFaceCrop(imageBitmap, face, syncContext);
        }
    }

    async syncFileFaceAlignments(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ): Promise<Float32Array> {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !fileContext.newDetection &&
            !isDifferentOrOld(
                oldMlFile?.faceAlignmentMethod,
                syncContext.faceAlignmentService.method,
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
        const imageBitmap =
            fileContext.imageBitmap ||
            (await ReaderService.getImageBitmap(syncContext, fileContext));

        // Execute the face alignment calculations
        for (const face of newMlFile.faces) {
            face.alignment = syncContext.faceAlignmentService.getFaceAlignment(
                face.detection,
            );
        }
        // Extract face images and convert to Float32Array
        const faceAlignments = newMlFile.faces.map((f) => f.alignment);
        const faceImages = await extractFaceImagesToFloat32(
            faceAlignments,
            syncContext.faceEmbeddingService.faceSize,
            imageBitmap,
        );
        const blurValues =
            syncContext.blurDetectionService.detectBlur(faceImages);
        newMlFile.faces.forEach((f, i) => (f.blurValue = blurValues[i]));

        imageBitmap.close();
        log.info("[MLService] alignedFaces: ", newMlFile.faces?.length);
        // log.info('4 TF Memory stats: ',JSON.stringify(tf.memory()));
        return faceImages;
    }

    async syncFileFaceEmbeddings(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
        alignedFacesInput: Float32Array,
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !fileContext.newAlignment &&
            !isDifferentOrOld(
                oldMlFile?.faceEmbeddingMethod,
                syncContext.faceEmbeddingService.method,
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

        const embeddings =
            await syncContext.faceEmbeddingService.getFaceEmbeddings(
                alignedFacesInput,
            );
        newMlFile.faces.forEach((f, i) => (f.embedding = embeddings[i]));

        log.info("[MLService] facesWithEmbeddings: ", newMlFile.faces.length);
        // log.info('5 TF Memory stats: ',JSON.stringify(tf.memory()));
    }

    async syncFileFaceMakeRelativeDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !fileContext.newAlignment &&
            !isDifferentOrOld(
                oldMlFile?.faceEmbeddingMethod,
                syncContext.faceEmbeddingService.method,
            ) &&
            areFaceIdsSame(newMlFile.faces, oldMlFile?.faces)
        ) {
            return;
        }
        for (let i = 0; i < newMlFile.faces.length; i++) {
            const face = newMlFile.faces[i];
            if (face.detection.box.x + face.detection.box.width < 2) continue; // Skip if somehow already relative
            face.detection =
                syncContext.faceDetectionService.getRelativeDetection(
                    face.detection,
                    newMlFile.imageDimensions,
                );
        }
    }

    async saveFaceCrop(
        imageBitmap: ImageBitmap,
        face: Face,
        syncContext: MLSyncContext,
    ) {
        const faceCrop = await syncContext.faceCropService.getFaceCrop(
            imageBitmap,
            face.detection,
            syncContext.config.faceCrop,
        );
        face.crop = await storeFaceCrop(
            face.id,
            faceCrop,
            syncContext.config.faceCrop.blobOptions,
        );
        const blob = await imageBitmapToBlob(faceCrop.image);
        faceCrop.image.close();
        return blob;
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
        allFaces: Array<Face>,
    ) {
        // await this.init();

        const clusteringConfig = syncContext.config.faceClustering;

        if (!allFaces || allFaces.length < clusteringConfig.minInputSize) {
            log.info(
                "[MLService] Too few faces to cluster, not running clustering: ",
                allFaces.length,
            );
            return;
        }

        log.info("Running clustering allFaces: ", allFaces.length);
        syncContext.mlLibraryData.faceClusteringResults =
            await syncContext.faceClusteringService.cluster(
                allFaces.map((f) => Array.from(f.embedding)),
                syncContext.config.faceClustering,
            );
        syncContext.mlLibraryData.faceClusteringMethod =
            syncContext.faceClusteringService.method;
        log.info(
            "[MLService] Got face clustering results: ",
            JSON.stringify(syncContext.mlLibraryData.faceClusteringResults),
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

    public async regenerateFaceCrop(
        syncContext: MLSyncContext,
        faceID: string,
    ) {
        const fileID = Number(faceID.split("-")[0]);
        const personFace = await mlIDbStorage.getFace(fileID, faceID);
        if (!personFace) {
            throw Error("Face not found");
        }

        const file = await getLocalFile(personFace.fileId);
        const imageBitmap = await getOriginalImageBitmap(file);
        return await this.saveFaceCrop(imageBitmap, personFace, syncContext);
    }
}

export default new FaceService();
