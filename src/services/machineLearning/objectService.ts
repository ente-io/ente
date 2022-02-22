import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedObject,
} from 'types/machineLearning';
import { isDifferentOrOld, getObjectId } from 'utils/machineLearning';
import ReaderService from './readerService';

class ObjectService {
    async syncFileObjectDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.objectDetectionMethod,
                syncContext.objectDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource
        ) {
            newMlFile.objects = oldMlFile?.objects?.map((existingObject) => ({
                id: existingObject.id,
                fileID: existingObject.fileID,
                detection: existingObject.detection,
            }));

            newMlFile.imageSource = oldMlFile.imageSource;
            newMlFile.imageDimensions = oldMlFile.imageDimensions;
            newMlFile.objectDetectionMethod = oldMlFile.objectDetectionMethod;
            return;
        }

        newMlFile.objectDetectionMethod =
            syncContext.objectDetectionService.method;
        fileContext.newDetection = true;
        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        const objectDetections =
            await syncContext.objectDetectionService.detectObjects(imageBitmap);
        // console.log('3 TF Memory stats: ', tf.memory());
        // TODO: reenable faces filtering based on width
        const detectedObjects = objectDetections?.map((detection) => {
            return {
                fileID: fileContext.enteFile.id,
                detection,
            } as DetectedObject;
        });
        newMlFile.objects = detectedObjects?.map((detectedObjects) => ({
            ...detectedObjects,
            id: getObjectId(detectedObjects, newMlFile.imageDimensions),
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        console.log(
            '[MLService] Detected Objects: ',
            newMlFile.objects?.length
        );
    }
}

export default new ObjectService();
