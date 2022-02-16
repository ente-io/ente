import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedFace,
    Face,
} from 'types/machineLearning';
import {
    isDifferentOrOld,
    getFaceId,
    areFaceIdsSame,
    extractFaceImages,
} from 'utils/machineLearning';
import { storeFaceCrop } from 'utils/machineLearning/faceCrop';
import ReaderService from './readerService';

class FaceDetectionService {
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
            newMlFile.imageDimentions = oldMlFile.imageDimentions;
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
        console.log('[MLService] alignedFaces: ', newMlFile.faces?.length);
        // console.log('4 TF Memory stats: ', tf.memory());
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

        console.log(
            '[MLService] facesWithEmbeddings: ',
            newMlFile.faces.length
        );
        // console.log('5 TF Memory stats: ', tf.memory());
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
}

export default new FaceDetectionService();
